#include <Wire.h>
#include <LiquidCrystal_I2C.h>
#include <ClickEncoder.h>
#include <EEPROM.h>

LiquidCrystal_I2C lcd(0x3F, 16, 2);

// Settings
//========================================================================
// pins numbers
const uint8_t pinEnable = A2;
const uint8_t pinStep   = 10;
const uint8_t pinDir    = 9;

const uint8_t pinMS1 = A1;
const uint8_t pinMS2 = A0;
const uint8_t pinMS3 = 13;

const uint8_t pinReset = 12;
const uint8_t pinSleep = 11;

// Speed & motor setup
const int8_t    microStepping = 16;
const int16_t   maxRpm = 300;		// Upper limit, don't increase RMP above this
const float     minRpm = 0.01;		// Lower limit, set RPM=0
const int16_t   rpmRate = 50;		// RPM increase per second when user change speed
const int16_t   haltRate = 200;		// RPM increase per second when motor halts
const int16_t   volumeRpm = 175;	// RPM when need to pump some water volume

const float   degreePerStep = 1.8;  // rather common value for widespread motors
const int16_t stepsPerRevolution = 360 / degreePerStep * microStepping;

const int8_t  slowdownRevolutions = 10;   // How many revolutions to end we should slow down
const float   slowdownFactor = 0.2;

// Show litres per hour instead of millilitres per minute
#define DISPLAY_LITRES_PER_HOUR 1

// Pump stops when enters MODE_MILLILITRE, if you do not this mode it you can switch it off
#define DISABLE_MODE_MILLILITRE 1

// Variables
//========================================================================

#define MODE_RPM 0
#define MODE_ML_PER_MIN 1
#define MODE_MILLILITRE 2

int8_t  pumpMode = 0;    // 0 - rpm, 1 - ml/m, 2 - ml

int16_t  targetVolume = 0;
float    targetRpm = 0;
float    lastTargetRpm = 0;
float    currentRpm = 0;
int16_t  currentRpmRate = rpmRate;

float rpm2millilitreCw = 3;
float rpm2millilitreCcw = 3;

ClickEncoder *encoder;

volatile uint8_t nMotorCounter = 0;
volatile long stepCounter = 0;
volatile long halfStepLimit = 0;

#define MAGIC_BYTE 0

// EEPROM handling
//========================================================================
void eepromWrite() {
	EEPROM.write(0, (uint8_t)MAGIC_BYTE);
	EEPROM.write(1, (uint8_t)pumpMode);
	EEPROM.put(2, rpm2millilitreCw);
	EEPROM.put(6, rpm2millilitreCcw);
	EEPROM.put(10, lastTargetRpm);
	EEPROM.put(20, targetVolume);
}

bool eepromRead() {
	const uint8_t magic = EEPROM.read(0);
	if (magic != MAGIC_BYTE) return false;

	pumpMode = (uint8_t)EEPROM.read(1);
	EEPROM.get(2, rpm2millilitreCw);
	EEPROM.get(6, rpm2millilitreCcw);
	EEPROM.get(10, lastTargetRpm);
	EEPROM.get(20, targetVolume);
	return true;
}

// Setup()
//========================================================================
void setup() {
	lcd.begin();
	lcd.clear();
	lcd.backlight();	

	// Show invitation
	lcd.setCursor(0, 0);
	lcd.print(F("Peristaltic pump"));

	// Serial.begin(115200);
	encoder = new ClickEncoder(3, 4, 2, 2);

	if (!eepromRead())
		Serial.println(F("Failed to read EEPROM values"));

	// Sets the two pins as Outputs
	pinMode(pinStep,   OUTPUT);
	pinMode(pinDir,    OUTPUT);
	pinMode(pinEnable, OUTPUT);
	pinMode(pinMS1,    OUTPUT);
	pinMode(pinMS2,    OUTPUT);
	pinMode(pinMS2,    OUTPUT);
	pinMode(pinSleep,  OUTPUT);
	pinMode(pinReset,  OUTPUT);

	digitalWrite(pinEnable, HIGH);
	digitalWrite(pinReset, HIGH);
	digitalWrite(pinSleep, HIGH);

	switch(microStepping){
	case 1:
		digitalWrite(pinMS1, LOW);
		digitalWrite(pinMS2, LOW);
		digitalWrite(pinMS3, LOW);
		break;
	case 2:
		digitalWrite(pinMS1, LOW);
		digitalWrite(pinMS2, HIGH);
		digitalWrite(pinMS3, LOW);
		break;
	case 4:
		digitalWrite(pinMS1, LOW);
		digitalWrite(pinMS2, HIGH);
		digitalWrite(pinMS3, LOW);
		break;
	case 8:
		digitalWrite(pinMS1, HIGH);
		digitalWrite(pinMS2, HIGH);
		digitalWrite(pinMS3, LOW);
		break;
	case 16:
		digitalWrite(pinMS1, HIGH);
		digitalWrite(pinMS2, HIGH);
		digitalWrite(pinMS3, HIGH);
		break;
	}
	

	cli();
	// set timer1 to driver the stepper motor
	TCCR1A = 0; // set TCCR1A register to 0
	TCCR1B = 0; // set TCCR1B register to 0
	TCNT1  = 0; // set counter value to 0

	TCCR1B |= _BV(WGM12);   // turn on CTC mode
	TCCR1A |= _BV(COM1B0);  // connect pin to interrupt
	// TIMSK1 |= _BV(OCIE1B); // enable timer compare interrupt

	// switch timer1 is  initially switched off by setting prescaler to 0
	// TCCR1B &= ~(_BV(CS12)| _BV(CS11) | _BV(CS10));

	// set timer2 interrupt at 1kHz
	TCCR2A = 0;  // set entire TCCR2A register to 0
	TCCR2B = 0;  // same for TCCR2B
	TCNT2 = 0;  // initialize counter value to 0

	// set compare match register for 1khz increments
	OCR2A = 249; // (16 000 000) / (1000 * 64) - 1;

	TCCR2A |= _BV(WGM21);  // turn on CTC mode
	TCCR2B |= _BV(CS22);   // Set CS21 bit for 64 prescaler
	TIMSK2 |= _BV(OCIE2A); // enable timer compare interrupt

	sei();  // allow interrupts

	
	lcd.setCursor(0, 1);
	lcd.print(F("      v1.1      "));
	delay(2000);
}


// stepper half step timer
//===============================================================================================================
long slowdownLimit = 0;
ISR(TIMER1_COMPB_vect) {
	stepCounter++;

	// Slowdown motor when at the and of specific water volume pumping
	// We do all calculations here, since it does not affect overall performance in our case
	if( slowdownLimit < stepCounter)
		if(slowdownLimit == 0) {
			slowdownLimit = halfStepLimit - 1L * slowdownRevolutions * stepsPerRevolution;
		} else {
			targetRpm = slowdownFactor*((targetRpm>0)?volumeRpm:-volumeRpm);
			slowdownLimit = halfStepLimit + 1;
		}

	if(halfStepLimit < stepCounter) {
		halfStepLimit = 0;
		stepCounter = 0;
		slowdownLimit = 0;
		setMotorSpeed(0);
		currentRpm = targetRpm = 0;
		TIMSK1 &= ~_BV(OCIE1B); // disable timer1 compare interrupt
	}
}

// 1kHz encoder service routine
//===============================================================================================================
ISR(TIMER2_COMPA_vect) {
	encoder->service();
	nMotorCounter++;
}

// Set motor speed
//===============================================================================================================
void setMotorSpeed(float rpm) {
	if (abs(rpm) < 1e-2) {
		TCCR1B &= B11111000;
		digitalWrite(pinStep, LOW);
		digitalWrite(pinEnable, HIGH);
		return;
	}

	digitalWrite(pinDir, (rpm > 0) ? LOW : HIGH);
	digitalWrite(pinEnable, LOW);

	long freq = long(1.0 * abs(rpm) * stepsPerRevolution / 60.);

	TCNT1 = 0; // set counter value to 0

	// Choose prescalers for according to required frequency
	if (freq > 1000) {
		TCCR1B = (TCCR1B & B11111000) | B00000001; // prescaler = 1
		OCR1A = uint16_t(8e6 / freq) - 1; // set compare match register
	} else if (freq > 25) {
		TCCR1B = (TCCR1B & B11111000) | B00000010; // prescaler = 8
		OCR1A = uint16_t(1e6 / freq) - 1; // set compare match register
	} else {
		TCCR1B = (TCCR1B & B11111000) | B00000100; // prescaler = 256
		OCR1A = uint16_t(62500 / freq) - 1; // set compare match register
	}
}

// Display on-screen data
//===============================================================================================================
char buffer[20] = {0};
void displayPumpData() {
	size_t pos = 0;
	lcd.setCursor(0, 0);
	switch (pumpMode) {
	default:
	case MODE_RPM:
		lcd.print(F("Motor speed, RMP"));
		lcd.setCursor(0, 1);
		sprintf(buffer, "%-+5d SET: %+5d", (int)currentRpm, (int)targetRpm);
		lcd.print(buffer);
		break;
	case MODE_ML_PER_MIN:
		#if DISPLAY_LITRES_PER_HOUR
			lcd.print(F("Flow rate, l/hr "));
		#else
			lcd.print(F("Flow rate, ml/m "));
		#endif
		
		lcd.setCursor(0, 1);
		{
			const float rpm2ml = (currentRpm > 0) ? rpm2millilitreCw : rpm2millilitreCcw;
			#if DISPLAY_LITRES_PER_HOUR
				const int clph = round(currentRpm * rpm2ml * 0.6);  // 60 / 1000 * 10
				const int tlph = round(targetRpm * rpm2ml * 0.6);

        // Was it so difficult to add normal floating point support to sprintf()!?
				sprintf(buffer, "%+3d.%1d SET: %+3d.%1d", clph/10, abs(clph%10), tlph/10, abs(tlph%10));
        if(currentRpm<0 && clph<10) buffer[1]  = '-';
        if(targetRpm<0 && tlph<10)  buffer[12] = '-';
			#else
				sprintf(buffer, "%-+5d SET: %+5d", (int)round(currentRpm*factor), (int)round(targetRpm*factor));
			#endif
      lcd.print(buffer);
		}
		break;
	case MODE_MILLILITRE:
		if(halfStepLimit == 0) {
			lcd.print(F("Water volume, ml"));
			lcd.setCursor(0, 1);
			pos += lcd.print(targetVolume);
			while (pos++ < 16) lcd.write(32);
		} else {
			const int progress = int(17.0*stepCounter / halfStepLimit);
			lcd.print(F("Pumping water "));
			(targetVolume>0)?lcd.print(F("+ ")):lcd.print(F("- "));
			lcd.setCursor(0, 1);
			while (pos++ < progress) lcd.write(255);
			while (pos++ < 16) lcd.write(32);
		}
		return;
	}
}

// Main loop
//===============================================================================================================

uint8_t nStateMachine = 0;
void loop() {
	static long lastTime = 0;

	// process encoder rotation
	float delta = encoder->getValue();
	if (delta) {
		if (pumpMode == MODE_MILLILITRE) { // don't change volume if pumping right now
			if(halfStepLimit<1) {
				targetVolume += delta;
				eepromWrite();
			}
		} else {
			currentRpmRate = rpmRate;

      switch (pumpMode)     {
      case MODE_RPM: 
      case MODE_MILLILITRE:
        targetRpm += delta;
        targetRpm = round(targetRpm);
        break;
      case MODE_ML_PER_MIN:
        
        if(DISPLAY_LITRES_PER_HOUR) {
          const double rpm2ml = (targetRpm>0)?rpm2millilitreCw:rpm2millilitreCcw;
          const double clph = round(targetRpm*rpm2ml*0.6) + delta;
          targetRpm = clph / rpm2ml / 0.6;
        } else {
          const double rpm2ml = (targetRpm>0)?rpm2millilitreCw:rpm2millilitreCcw;
          const double cmlpm = round(targetRpm*rpm2ml) + delta;
          targetRpm = cmlpm / rpm2ml;
        }
        
        break;
      } // switch (pumpMode) 

			if (targetRpm > maxRpm) targetRpm = maxRpm;
			if (targetRpm < -maxRpm) targetRpm = -maxRpm;
			if (abs(targetRpm) < minRpm) targetRpm = 0;
		}
		displayPumpData();
	}

	// process encoder buttons
	switch (encoder->getButton()) {
	case ClickEncoder::DoubleClicked:
		switch (pumpMode) 		{
		case MODE_RPM: 
		case MODE_ML_PER_MIN:
			if (abs(targetRpm) > 1e-2) {
				currentRpmRate = haltRate;
				lastTargetRpm = targetRpm;
				targetRpm = 0;
				eepromWrite();
			} else {
				currentRpmRate = rpmRate;
				targetRpm = lastTargetRpm;
			}
			break;
		case MODE_MILLILITRE:
			if (halfStepLimit > 0) {
				halfStepLimit = 0;
			} else {
				currentRpmRate = rpmRate;
				stepCounter = 0;
				halfStepLimit = (long) abs( 2.0*targetVolume / ((targetVolume>0)?rpm2millilitreCw:rpm2millilitreCcw) * stepsPerRevolution );
				TIMSK1 |= _BV(OCIE1B);  // enable timer compare interrupt
				targetRpm = (targetVolume>0)?volumeRpm:-volumeRpm;
			}
			break;
		} // switch (pumpMode) 
		break;
	case ClickEncoder::Clicked:
		encoder->setAccelerationEnabled(true);
		switch (pumpMode) 		{
		case MODE_RPM: 
			pumpMode++;
			{
				float factor = (currentRpm > 0) ? rpm2millilitreCw : rpm2millilitreCcw;
				currentRpm = round(currentRpm * factor) / factor;
			}
			break;
		case MODE_ML_PER_MIN:
			pumpMode = (DISABLE_MODE_MILLILITRE) ? MODE_RPM : MODE_MILLILITRE;
			
			if(!DISABLE_MODE_MILLILITRE) {  // halt pump
        currentRpmRate = haltRate; 
			  targetRpm = 0;
			}
			break;
		case MODE_MILLILITRE:
			if(halfStepLimit<1) // dont switch if pumping right now
				pumpMode = MODE_RPM;
			break;
		}
		eepromWrite();
		displayPumpData();
		break;
	case ClickEncoder::Held:
		// don't start calibration if pumping right now
		if (pumpMode == MODE_MILLILITRE && halfStepLimit > 1)
			break;

		if(calibratePump()) {
			lcd.setCursor(0, 0);
			lcd.print(F("Pump calibration"));
			lcd.setCursor(0, 1);
			lcd.print(F("is finished     "));

			eepromWrite();
		} else {
			lcd.setCursor(0, 0);
			lcd.print(F("Pump calibration"));
			lcd.setCursor(0, 1);
			lcd.print(F("was canceled    "));
		}
		lastTime = millis() + 1500;

		// Wait button release
		while (encoder->getButton() == ClickEncoder::Held)
			; // do nothing
		break;
	default:
		break;
	} // switch (encoder->getButton())

	// display motor speed twice per second
	if (millis() > lastTime + ((halfStepLimit>0)?100:500)) {
		displayPumpData();
		lastTime = millis();
	}

	// every 10 ms change motor speed
	adjustMotorSpeed();
}

// Alter motor speed when accelerating / decelerating
//========================================================================

void adjustMotorSpeed(){
	if (nMotorCounter > 10) {
		if (targetRpm - currentRpm > 1e-5) {
			currentRpm += 0.01 * currentRpmRate;
			if (currentRpm > targetRpm)  currentRpm = targetRpm;
			setMotorSpeed(currentRpm);
		}

		if (targetRpm - currentRpm < -1e-5) {
			currentRpm -= 0.01 * currentRpmRate;
			if (currentRpm < targetRpm)   currentRpm = targetRpm;
			setMotorSpeed(currentRpm);
		}
		nMotorCounter = 0;
	}
}

// Pump calibration
//===============================================================================================================
bool calibratePump() {
	// Show invitation
	lcd.setCursor(0, 0);
	lcd.print(F("PUMP CALIBRATION"));
	lcd.setCursor(0, 1);
	lcd.print(F(" Click to start "));

	// Stop motor
	while (abs(currentRpm) > 1e-2) {
		targetRpm = 0;
		if (targetRpm - currentRpm > 1e-5) {
			currentRpm += 0.01 * haltRate;
			if (currentRpm > targetRpm)  currentRpm = targetRpm;
			setMotorSpeed(currentRpm);
		}

		if (targetRpm - currentRpm < -1e-5) {
			currentRpm -= 0.01 * haltRate;
			if (currentRpm < targetRpm)   currentRpm = targetRpm;
			setMotorSpeed(currentRpm);
		}
		delay(10);
	}

	// Wait button release
	while (encoder->getButton() == ClickEncoder::Held)
		; // do nothing

	do {
		ClickEncoder::Button  btn = encoder->getButton();

		if (btn == ClickEncoder::Clicked)
			break;

		if (btn == ClickEncoder::Held)
			return false;

		delay(1);
	} while (1);


	lcd.setCursor(0, 0);
	lcd.print(F("Select direction"));
	
	
	encoder->setAccelerationEnabled(false);
	int selection = 0;
	do {
		int delta = encoder->getValue();
		if (delta) {
			selection = (selection + delta + 3) % 3;
			Serial.println(delta);
			Serial.println(selection);
		}

		

		lcd.setCursor(0, 1);
		switch (selection) {
		case 0:
			lcd.print(F("Clockwise       "));
			break;
		case 1:
			lcd.print(F("Counterclockwise"));
			break;
		case 2:
			lcd.print(F("Both            "));
			break;
		}


		ClickEncoder::Button  btn = encoder->getButton();

		if (btn == ClickEncoder::Clicked)
			break;

		if (btn == ClickEncoder::Held) {
			encoder->setAccelerationEnabled(true);
			return false;
		}

		delay(1);
	} while (1);
	encoder->setAccelerationEnabled(true);
	
	const int revolutionNum = 50;
	if(selection!=1) {
		lcd.setCursor(0, 0);
		lcd.print(F("Reset scales and"));
		lcd.setCursor(0, 1);
		lcd.print(F("click to proceed"));

		do {
			ClickEncoder::Button  btn = encoder->getButton();

			if (btn == ClickEncoder::Clicked)
				break;

			if (btn == ClickEncoder::Held)
				return false;

			delay(1);
		} while (1);


		lcd.setCursor(0, 0);
		lcd.print(F("Pumping water + "));
		lcd.setCursor(0, 1);
		lcd.print(F("                "));

		// Pump some water
		halfStepLimit =  2L * revolutionNum * stepsPerRevolution;
		TIMSK1 |= _BV(OCIE1B);  // enable timer1 compare interrupt
		targetRpm = volumeRpm;

		lcd.setCursor(0, 0);
		lcd.print(F("Pumping water + "));

		while (halfStepLimit > 0) {
			const int pos = int(16.0*stepCounter / halfStepLimit);
			lcd.setCursor(pos, 1);
			lcd.write(255);

			ClickEncoder::Button  btn = encoder->getButton();
			if (btn == ClickEncoder::Held || btn == ClickEncoder::DoubleClicked) {
				halfStepLimit = 0;
				return false;
			}

			adjustMotorSpeed();
		}

		// ask user for measured volume
		float volume = revolutionNum * rpm2millilitreCw;
		lcd.setCursor(0, 0);
		lcd.print(F("Enter the volume"));
		lcd.setCursor(0, 1);
		lcd.print(F("                "));
		lcd.setCursor(0, 1);
		lcd.print(volume);

		do {
			int delta = encoder->getValue();
			if (delta) {
				volume += 0.1 * delta;
				if (volume < 0) volume = 0;

				lcd.setCursor(0, 1);
				lcd.print(volume, 1);
				lcd.print(F(" ml    "));
			}

			ClickEncoder::Button  btn = encoder->getButton();
			if (btn == ClickEncoder::Clicked) {
				rpm2millilitreCw = volume / revolutionNum;
				break;
			}

			if (btn == ClickEncoder::Held) {
				return false;
			}

			delay(1);
		} while (1);
	}

	if(selection!=0) {
		lcd.setCursor(0, 0);
		lcd.print(F("Reset scales and"));
		lcd.setCursor(0, 1);
		lcd.print(F("click to proceed"));

		do {
			ClickEncoder::Button  btn = encoder->getButton();

			if (btn == ClickEncoder::Clicked)
				break;

			if (btn == ClickEncoder::Held)
				return false;

			delay(1);
		} while (1);

		lcd.setCursor(0, 0);
		lcd.print(F("Pumping water - "));
		lcd.setCursor(0, 1);
		lcd.print(F("                "));

		// Pump some water
		halfStepLimit =  2L * revolutionNum * stepsPerRevolution;
		TIMSK1 |= _BV(OCIE1B);  // enable timer1 compare interrupt
		targetRpm = -volumeRpm;

		lcd.setCursor(0, 0);
		lcd.print(F("Pumping water - "));

		while (halfStepLimit > 0) {
			const int pos = int(16.0*stepCounter / halfStepLimit);
			lcd.setCursor(pos, 1);
			lcd.write(255);

			ClickEncoder::Button  btn = encoder->getButton();
			if (btn == ClickEncoder::Held || btn == ClickEncoder::DoubleClicked) {
				halfStepLimit = 0;
				return false;
			}

			adjustMotorSpeed();
		}

		// ask user for measured volume
		float volume = revolutionNum * rpm2millilitreCcw;
		lcd.setCursor(0, 0);
		lcd.print(F("Enter the volume"));
		lcd.setCursor(0, 1);
		lcd.print(F("                "));
		lcd.setCursor(0, 1);
		lcd.print(volume);

		do {
			int delta = encoder->getValue();
			if (delta) {
				volume += 0.1 * delta;
				if (volume < 0) volume = 0;

				lcd.setCursor(0, 1);
				lcd.print(volume, 1);
				lcd.print(F(" ml    "));
			}

			ClickEncoder::Button  btn = encoder->getButton();

			if (btn == ClickEncoder::Clicked) {
				rpm2millilitreCcw = volume / revolutionNum;
				break;
			}

			if (btn == ClickEncoder::Held) {
				return false;
			}

			delay(1);
		} while (1);
	}

	return true;
}


