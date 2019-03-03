#include <Wire.h>
#include <LiquidCrystal_I2C.h>
#include <ClickEncoder.h>
#include <EEPROM.h>

const double firmwareVersion = 2.0;

// Firmware features
//==============================================================================================

// Enable debug output to Serial
#define DEBUG_ENABLED 0

// EEPROM magic byte, increment this to clear EEPROM settings
#define MAGIC_BYTE 99

// Show litres per hour instead of millilitres per minute
#define DISPLAY_LITRES_PER_HOUR 1

// Pump stops when enters MODE_BOTTLING, if you do not this mode it you can switch it off
#define ENABLE_MODE_BOTTLING 1

// Starting from v2.0 pump saves total motor uptime & pumped volume to eeprom, disable it if not used
#define ENABLE_UPTIME_CALC 1

// Enable external speed control from moonshine controller, e.g. HelloDistiller
#define ENABLE_EXTERNAL_CONTROL 0

// Choose control signal 
//     0 = PWM signal from pin 2/interrupt 0, RPM = Duty*maxRpm.  Move encoder pins somewhere else.
//     1 = PWM signal from pin 3/interrupt 1, RPM = Duty*maxRpm.  Move encoder pins somewhere else.
//     2 = analog 0-5V input from pins A6/A7, RPM = InputVoltage*maxRpm/5V
#define EXTERNAL_CONTROL_TYPE 0

// We can use simple moisture sensor to detect hose failure
#define ENABLE_MOISTURE_SENSOR 0

// Threshold above which pump will halt. Set threshold to 2-255 for analog input, or to 1 for digital input
// Note: A6 & A7 pins cannot do digitalRead() and should use analog input only, i.e. threshold>2
#define MOISTURE_SENSOR_THRESHOLD 100 

#define LCD_I2C_ADDRESS 0x27

#define ENCODER_STEP_PER_NOTCH 4


// Hardware Settings
//================================================================================================
// pins numbers
const uint8_t pinEnable = A2;
const uint8_t pinStep = 10;
const uint8_t pinDir = A3;

const uint8_t pinMS1 = A1;
const uint8_t pinMS2 = A0;
const uint8_t pinMS3 = 13;

const uint8_t pinReset = 12;
const uint8_t pinSleep = 11;

#if ENABLE_MOISTURE_SENSOR
const uint8_t pinMoistureSensor = A6;
#endif

#if ENABLE_EXTERNAL_CONTROL 
#if EXTERNAL_CONTROL_TYPE==0
	const uint8_t pinExtControl = 2;  // Interrupt 0
#elif EXTERNAL_CONTROL_TYPE==1
	const uint8_t pinExtControl = 3;  // Interrupt 1
#else
	const uint8_t pinExtControl = A7;  // Analog input pin
#endif
#endif

#if ENABLE_EXTERNAL_CONTROL &&  EXTERNAL_CONTROL_TYPE==0
	const uint8_t pinEncoderButton = 5;
#else
	const uint8_t pinEncoderButton = 2;
#endif
#if ENABLE_EXTERNAL_CONTROL &&  EXTERNAL_CONTROL_TYPE==1
	const uint8_t pinEncoderA  = 5;
#else
	const uint8_t pinEncoderA  = 3;
#endif
const uint8_t pinEncoderB  = 4;




// Speed & motor setup
const int8_t    microStepping = 8;
const int16_t   maxRpm = 450;			// Upper limit, don't increase RMP above this
const float     minRpm = 0.01;			// Lower limit, set RPM=0
const int16_t   rpmAccelerationRate = 50;	// RPM increase per second when user change speed
const int16_t   rpmHaltRate = 200;		// RPM increase per second when motor halts
const int16_t   volumeRpm = 200;		// RPM when need to pump some water volume

const float   degreePerStep = 1.8;  // rather common value for widespread motors
const int16_t stepsPerRevolution = 360 / degreePerStep * microStepping;

const int8_t  slowdownRevolutions = 7;   // How many revolutions to the end we should slow down
const float   slowdownFactor = 0.2;

// Variables
//================================================================================================

#define MODE_RPM			 0		// Control RPM
#define MODE_LITRES_PER_HOUR 1      // Control liquid volume per second

#if ENABLE_MODE_BOTTLING 
#define MODE_BOTTLING	 2      // Pump fixed volume of liquid
#endif
#if ENABLE_EXTERNAL_CONTROL
#define MODE_EXT_CONTROL 3	    // External control via PWM or analog signal
#endif

int8_t  pumpMode = 0;
LiquidCrystal_I2C lcd(LCD_I2C_ADDRESS, 16, 2);

int16_t  targetVolume = 500;
float    targetRpm = 0;
float    lastTargetRpm = 0;
float    currentRpm = 0;
int16_t  currentRpmRate = rpmAccelerationRate;

float rpm2millilitreCw = 3;
float rpm2millilitreCcw = 3;

ClickEncoder *encoder;

volatile uint8_t speedAdjustmentTicks = 0;
volatile long stepCounter = 0;
volatile long halfStepLimit = 0;

// variable for uptime counting
uint32_t totalMotorUptime = 0;		// motor uptime in seconds
double   totalPumpedVolume = 0;	    // total pumped volume in litres
float    lastCurrentRpm = 0;

#if ENABLE_MOISTURE_SENSOR
long lastSensorReadTime = 0;
bool haltOnHoseFailureFlag = 0;
#endif

#if ENABLE_UPTIME_CALC
const uint16_t volumeIntegralPeriodMs = 1000;
uint32_t eepromSaveTotalsPeriodMs = 60000;
uint32_t eepromRewriteCounter = 0;  // ATMEL gives 100000 cell rewrites lifetime
									// With eeprom update once in every minute we will hold for 100000/60/24 ~ 70 days
									// So for the first 10 minutes we will save uptime every minute
									//            after 10 minutes - every 5 minutes
									//            after 1 hour - every 10 minutes
#endif // ENABLE_UPTIME_CALC

#if ENABLE_EXTERNAL_CONTROL
	// User may want to halt the motor manually. We will use this flag to ignore external input.
bool extControlDisabledFlag = true;
uint32_t lastRpmSetTime = 0;
volatile float extPwmDutyCycle = 0;
volatile uint16_t extPwmPeriodNum = 0;
const double extCtrlAvgWeight = 0.01;
#endif

// Debug helpers
#if DEBUG_ENABLED
#define DEBUG_BEGIN(baudRate)	Serial.begin(baudRate)
									// Prints debug message
#define DEBUG_PRINT(...)		Serial.print(__VA_ARGS__)
#define DEBUG_PRINTLN(...)		Serial.println(__VA_ARGS__)
									// Debug block may contain any code that we'll be switched off when debugging disabled
#define DEBUG_BLOCK(block)		do { block; } while(0)	
#else
#define DEBUG_BEGIN(...)
#define DEBUG_PRINT(...)   
#define DEBUG_PRINTLN(...) 
#define DEBUG_BLOCK(block)
#endif

// EEPROM handling
//================================================================================================
void eepromWrite() {
	eepromRewriteCounter++;

	EEPROM.write(0, (uint8_t)MAGIC_BYTE);
	EEPROM.write(1, (uint8_t)pumpMode);
	EEPROM.put(2, rpm2millilitreCw);
	EEPROM.put(6, rpm2millilitreCcw);
	EEPROM.put(10, lastTargetRpm);
	EEPROM.put(15, targetVolume);
#if ENABLE_UPTIME_CALC
	eepromWriteTotals();
#endif
}

#if ENABLE_UPTIME_CALC
void eepromWriteTotals() {
	EEPROM.put(20, totalMotorUptime);
	EEPROM.put(25, totalPumpedVolume);
	EEPROM.put(30, eepromRewriteCounter);
}
#endif  // !ENABLE_UPTIME_CALC

bool eepromRead() {
	const uint8_t magic = EEPROM.read(0);
	if (magic != MAGIC_BYTE) {
		eepromWrite(); // clear old data
		return false;
	}

	pumpMode = (uint8_t)EEPROM.read(1);
	EEPROM.get(2, rpm2millilitreCw);
	EEPROM.get(6, rpm2millilitreCcw);
	EEPROM.get(10, lastTargetRpm);
	EEPROM.get(15, targetVolume);
#if ENABLE_UPTIME_CALC
	EEPROM.get(20, totalMotorUptime);
	EEPROM.get(25, totalPumpedVolume);
	EEPROM.get(30, eepromRewriteCounter);
#endif
	return true;
}

// Setup()
//================================================================================================
void setup() {
	DEBUG_BEGIN(115200);

	lcd.begin();
	lcd.clear();
	lcd.backlight();

	// Show invitation
	lcd.setCursor(0, 0);
	lcd.print(F("Peristaltic pump"));
	lcd.setCursor(0, 1);
	lcd.print(String(F("      v")) + String(firmwareVersion, 1) + String(F("      ")));

	encoder = new ClickEncoder(pinEncoderA, pinEncoderB, pinEncoderButton, ENCODER_STEP_PER_NOTCH);

	if (!eepromRead())
		DEBUG_PRINTLN(F("Failed to read EEPROM values"));

	// Setup pins
	pinMode(pinStep, OUTPUT);
	pinMode(pinDir, OUTPUT);
	pinMode(pinEnable, OUTPUT);
	pinMode(pinMS1, OUTPUT);
	pinMode(pinMS2, OUTPUT);
	pinMode(pinMS2, OUTPUT);
	pinMode(pinSleep, OUTPUT);
	pinMode(pinReset, OUTPUT);

#if	ENABLE_MOISTURE_SENSOR
	pinMode(pinMoistureSensor, INPUT);
#endif

#if ENABLE_EXTERNAL_CONTROL
	pinMode(pinExtControl, INPUT);
#endif

	// Stepper driver setup
	digitalWrite(pinEnable, HIGH);
	digitalWrite(pinReset, HIGH);
	digitalWrite(pinSleep, HIGH);

	// Choose microstepping
	switch (microStepping) {
	case 1:
		digitalWrite(pinMS1, LOW); 		digitalWrite(pinMS2, LOW); 		digitalWrite(pinMS3, LOW);
		break;
	case 2:
		digitalWrite(pinMS1, LOW); 		digitalWrite(pinMS2, HIGH); 	digitalWrite(pinMS3, LOW);
		break;
	case 4:
		digitalWrite(pinMS1, LOW);		digitalWrite(pinMS2, HIGH);		digitalWrite(pinMS3, LOW);
		break;
	case 8:
		digitalWrite(pinMS1, HIGH);		digitalWrite(pinMS2, HIGH);		digitalWrite(pinMS3, LOW);
		break;
	case 16:
		digitalWrite(pinMS1, HIGH);		digitalWrite(pinMS2, HIGH);		digitalWrite(pinMS3, HIGH);
		break;
	}


	cli();
	// set timer1 to driver the stepper motor
	TCCR1A = 0; // set TCCR1A register to 0
	TCCR1B = 0; // set TCCR1B register to 0
	TCNT1 = 0; // set counter value to 0

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
	OCR2A = 249;  // (16 000 000) / (1000 * 64) - 1;

	TCCR2A |= _BV(WGM21);  // turn on CTC mode
	TCCR2B |= _BV(CS22);   // Set CS22 bit for 64 prescaler

	TIMSK2 |= _BV(OCIE2A); // enable timer compare interrupt

#if ENABLE_EXTERNAL_CONTROL && (EXTERNAL_CONTROL_TYPE == 0 || EXTERNAL_CONTROL_TYPE == 1)
	attachInterrupt(EXTERNAL_CONTROL_TYPE, ExternalInputISR, CHANGE);              // Attach interrupt handler
#endif

	sei();  // allow interrupts	

#if ENABLE_UPTIME_CALC
	delay(1000);
	// Display total stepper uptime
	lcd.clear();
	lcd.print(F("Motor uptime:   "));
	lcd.setCursor(0, 1);
	String line;
	uint32_t tmpMotorUptime = totalMotorUptime;
	if (totalMotorUptime >= 86400)		  line += String(int(totalMotorUptime / 86400)) + String(F("d "));
	if ((tmpMotorUptime %= 86400) > 3600)   line += String(int(tmpMotorUptime / 3600)) + String(F("h "));
	if ((tmpMotorUptime %= 3600) > 60)	  line += String(int(tmpMotorUptime / 60)) + String(F("m "));
	if (totalMotorUptime < 86400)		  line += String(int(tmpMotorUptime % 60)) + String(F("s"));
	lcd.print(line);
	DEBUG_PRINT(F("Total motor uptime: "));
	DEBUG_PRINTLN(line);
	delay(1000);

	// Display total volume pumped
	lcd.clear();
	lcd.print(F("Total volume:   "));
	lcd.setCursor(0, 1);
	line = String(totalPumpedVolume, 2) + String(F("L"));
	lcd.print(line);
	DEBUG_PRINT(F("Total volume pumped: "));
	DEBUG_PRINT(totalPumpedVolume, 3);
	DEBUG_PRINTLN(F("L"));
	delay(1000);
#else
	delay(2000);
#endif  // ENABLE_UPTIME_CALC
}


// stepper half step timer
//===============================================================================================================
long slowdownLimit = 0;
ISR(TIMER1_COMPB_vect) {
	stepCounter++;

	// Slowdown motor when at the and of specific water volume pumping
	// We do all calculations here, since it does not affect overall performance in our case
	if (slowdownLimit < stepCounter)
		if (slowdownLimit == 0) {
			slowdownLimit = halfStepLimit - 1L * slowdownRevolutions * stepsPerRevolution;
		} else {
			targetRpm = slowdownFactor * ((targetRpm > 0) ? volumeRpm : -volumeRpm);
			slowdownLimit = halfStepLimit + 1;
		}

	if (halfStepLimit < stepCounter) {
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
	speedAdjustmentTicks++;
}
#if ENABLE_EXTERNAL_CONTROL && (EXTERNAL_CONTROL_TYPE ==0 || EXTERNAL_CONTROL_TYPE == 1)
void ExternalInputISR() {
	static unsigned long lastFall;
	static unsigned long lastRise;
	static unsigned long lastCall;
	static bool newPeriod = 1;

	float pwmPeriod;
	float pwmOnTime;
	float now = micros();

	if (digitalRead(2 + EXTERNAL_CONTROL_TYPE) == LOW) {
		// Falling edge
		lastFall = now;
		newPeriod = 1;
	} else if (newPeriod) {
		// Rising edge
		pwmPeriod = now - lastRise;
		pwmOnTime = lastFall - lastRise;
		const double duty = pwmOnTime / pwmPeriod;

		if (duty >= 0 && duty <= 1) extPwmDutyCycle = (extPwmDutyCycle + extCtrlAvgWeight * duty) / (1 + extCtrlAvgWeight);

		lastRise = now;
		newPeriod = 0;
		extPwmPeriodNum++;
	}
}
#endif

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
char buffer[20] = { 0 };
void displayPumpData() {
	size_t pos = 0;
	lcd.setCursor(0, 0);
	switch (pumpMode) {
	default:
	case MODE_RPM:
		lcd.print(F("Motor speed, RMP"));
		lcd.setCursor(0, 1);
		sprintf_P(buffer, PSTR("%-+5d SET: %+5d"), (int)currentRpm, (int)targetRpm);
		lcd.print(buffer);
		break;
	case MODE_LITRES_PER_HOUR:
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
			sprintf(buffer, "%+3d.%1d SET: %+3d.%1d", clph / 10, abs(clph % 10), tlph / 10, abs(tlph % 10));
			if (currentRpm<0 && clph>-10) buffer[1] = '-';
			if (targetRpm<0 && tlph>-10)  buffer[12] = '-';
		#else
			sprintf(buffer, "%-+5d SET: %+5d", (int)round(currentRpm*factor), (int)round(targetRpm*factor));
		#endif
			lcd.print(buffer);
		}
		break;
	#if ENABLE_MODE_BOTTLING
	case MODE_BOTTLING:
		if (halfStepLimit == 0) {
			lcd.print(F("Bottling volume "));
			lcd.setCursor(0, 1);
			pos += lcd.print(targetVolume);
			pos += lcd.print(F(" ml"));
			while (pos++ < 16) lcd.write(32);
		} else {
			const int progress = int(17.0*stepCounter / halfStepLimit);
			lcd.print(F("Pumping water "));
			(targetVolume > 0) ? lcd.print(F("+ ")) : lcd.print(F("- "));
			lcd.setCursor(0, 1);
			while (pos++ < progress) lcd.write(255);
			while (pos++ < 16) lcd.write(32);
		}
		return;
	#endif
	#if ENABLE_EXTERNAL_CONTROL 
	case MODE_EXT_CONTROL:
		lcd.print(F("External control"));
		lcd.setCursor(0, 1);
		if (extControlDisabledFlag) {
			sprintf(buffer, "Stopped (%d%%)", int(extPwmDutyCycle * 100));
		} else {
			const int clph = round(currentRpm * rpm2millilitreCw * 0.6);  // 60 / 1000 * 10
			sprintf(buffer, "%d.%1d l/h (%d%%)", clph / 10, abs(clph % 10), int(extPwmDutyCycle * 100));
		}
		pos = lcd.print(buffer);
		while (pos++ < 16) lcd.write(32);

		return;
	#endif
	}
}

// Main loop
//===============================================================================================================

uint8_t nStateMachine = 0;
void loop() {
	static long lastTime = 0;
	const uint32_t now = millis();
	const double rpm2ml = (targetRpm > 0) ? rpm2millilitreCw : rpm2millilitreCcw;

#if	ENABLE_MOISTURE_SENSOR
	if (!haltOnHoseFailureFlag && now - lastSensorReadTime > 777) {
		// Read the input on moisture sensor pin
		int sensorValue = (MOISTURE_SENSOR_THRESHOLD > 1) ? analogRead(pinMoistureSensor) : digitalRead(pinMoistureSensor);
		if (sensorValue >= MOISTURE_SENSOR_THRESHOLD) {
			lcd.clear();
			lcd.print("  Hose failure  ");
			lcd.setCursor(0, 1);
			lcd.print("    detected!   ");

			DEBUG_PRINTLN(F("WARNING! The hose failure was detected. The pump was halted!"));

			haltOnHoseFailureFlag = true;
		}
		lastSensorReadTime = now;
	}
	if (haltOnHoseFailureFlag) {
		currentRpmRate = rpmHaltRate;
		targetRpm = 0;
		adjustMotorSpeed();
		return;
	}
#endif

#if ENABLE_UPTIME_CALC
	static long lastIntegralTime = 0;
	static long lastEepromSaveTime = 0;
	static long lastTotalMotorUptime = totalMotorUptime;
	static long eepromWriteCounter = 0;

	// Count pumped volume
	if (now - lastIntegralTime > volumeIntegralPeriodMs) {
		if (abs(currentRpm) > 0) totalMotorUptime += volumeIntegralPeriodMs / 1000;
		const double rpmIntegral = 0.5*(currentRpm + ((currentRpm*lastCurrentRpm > 0) ? 1 : -1)*lastCurrentRpm) / 60 * volumeIntegralPeriodMs / 1000;
		totalPumpedVolume += rpm2ml * abs(rpmIntegral) / 1000;

		DEBUG_BLOCK({
			if (abs(rpmIntegral) > 0) {
				String line;
				uint32_t tmpMotorUptime = totalMotorUptime;
				if (totalMotorUptime >= 86400)		  line += String(int(totalMotorUptime / 86400)) + String(F("d "));
				if ((tmpMotorUptime %= 86400) > 3600)   line += String(int(tmpMotorUptime / 3600)) + String(F("h "));
				if ((tmpMotorUptime %= 3600) > 60)	  line += String(int(tmpMotorUptime / 60)) + String(F("m "));
				line += String(int(tmpMotorUptime % 60)) + String(F("s"));
				DEBUG_PRINT(F("Total motor uptime: "));
				DEBUG_PRINT(line);

				DEBUG_PRINT(F(". Total volume pumped: "));
				DEBUG_PRINT(totalPumpedVolume, 3);
				DEBUG_PRINTLN(F("L"));

			} });

		lastCurrentRpm = currentRpm;
		lastIntegralTime = now;
	}

	// Save totals to eeprom
	if (totalMotorUptime > lastTotalMotorUptime && now - lastEepromSaveTime > eepromSaveTotalsPeriodMs) {
		eepromWriteTotals();
		lastTotalMotorUptime = totalMotorUptime;
		lastEepromSaveTime = now;
		// Increase eeprom save period to extend cell life
		if (++eepromWriteCounter > 10)		eepromSaveTotalsPeriodMs = 5 * 60 * 1000; // 5 minutes
		else if (eepromWriteCounter > 20)	eepromSaveTotalsPeriodMs = 10 * 60 * 1000; // 10 minutes
	}
#endif  // ENABLE_UPTIME_CALC

#if ENABLE_EXTERNAL_CONTROL 
	if (pumpMode == MODE_EXT_CONTROL && now - lastRpmSetTime > 1000) {  // check duty cycle 5 time per second 
		if (extControlDisabledFlag) {
			targetRpm = 0;
		} else {
		#if EXTERNAL_CONTROL_TYPE > 1
			targetRpm = 1.0*maxRpm*analogRead(pinExtControl) / 255;
		#else
			if (extPwmPeriodNum < 1) // no pulse on input pin means either 0% or 100%
				extPwmDutyCycle = digitalRead(pinExtControl);
			DEBUG_PRINT(F("PWM frequency: "));		DEBUG_PRINT(extPwmPeriodNum);		DEBUG_PRINTLN(F(" Hz"));
			DEBUG_PRINT(F("PWM duty cycle: "));		DEBUG_PRINT(extPwmDutyCycle * 100, 2);		DEBUG_PRINTLN(F("%"));
			targetRpm = maxRpm * extPwmDutyCycle;
			extPwmPeriodNum = 0;
		#endif
		}		

		if (targetRpm > maxRpm) targetRpm = maxRpm;
		if (targetRpm < -maxRpm) targetRpm = -maxRpm;
		if (abs(targetRpm) < minRpm) targetRpm = 0;

		lastRpmSetTime = now;
	}

#endif

	// process encoder rotation
	float delta = encoder->getValue();
	if (delta) {
		currentRpmRate = rpmAccelerationRate;

		switch (pumpMode) {
		case MODE_RPM:
			targetRpm += delta;
			targetRpm = round(targetRpm);
			break;
		case MODE_LITRES_PER_HOUR:
			if (DISPLAY_LITRES_PER_HOUR) {
				const double clph = round(targetRpm*rpm2ml*0.6) + delta;
				targetRpm = clph / rpm2ml / 0.6;
			} else {
				const double cmlpm = round(targetRpm*rpm2ml) + delta;
				targetRpm = cmlpm / rpm2ml;
			}
			break;
		#if ENABLE_MODE_BOTTLING
		case MODE_BOTTLING:
			// don't change volume if pumping right now
			if (halfStepLimit < 1) {
				targetVolume += delta;
				eepromWrite();
			}
			break;
		#endif
		#if ENABLE_EXTERNAL_CONTROL
		case MODE_EXT_CONTROL:
			break;
		#endif
		default:
			break; // no actions here
		} // switch (pumpMode) 

		if (targetRpm > maxRpm) targetRpm = maxRpm;
		if (targetRpm < -maxRpm) targetRpm = -maxRpm;
		if (abs(targetRpm) < minRpm) targetRpm = 0;

		displayPumpData();
	} // if (delta) 

	// process encoder buttons
	switch (encoder->getButton()) {
	case ClickEncoder::DoubleClicked:
		switch (pumpMode) {
		case MODE_RPM:
		case MODE_LITRES_PER_HOUR:
			if (abs(targetRpm) > 1e-2) {
				currentRpmRate = rpmHaltRate;
				lastTargetRpm = targetRpm;
				targetRpm = 0;
				eepromWrite();
			} else {
				currentRpmRate = rpmAccelerationRate;
				targetRpm = lastTargetRpm;
			}
			break;
		#if ENABLE_MODE_BOTTLING
		case MODE_BOTTLING:
			if (halfStepLimit > 0) {
				halfStepLimit = 0;
			} else {
				currentRpmRate = rpmAccelerationRate;
				stepCounter = 0;
				halfStepLimit = (long)abs(2.0*targetVolume / ((targetVolume > 0) ? rpm2millilitreCw : rpm2millilitreCcw) * stepsPerRevolution);
				TIMSK1 |= _BV(OCIE1B);  // enable timer compare interrupt
				targetRpm = (targetVolume > 0) ? volumeRpm : -volumeRpm;
			}
			break;
		#endif
		#if ENABLE_EXTERNAL_CONTROL	
		case MODE_EXT_CONTROL:
			extControlDisabledFlag = !extControlDisabledFlag;
			if (extControlDisabledFlag) {
				currentRpmRate = rpmHaltRate;
				targetRpm = 0;
			} else {
				currentRpmRate = rpmAccelerationRate;
			}
			break;
		#endif // ENABLE_EXTERNAL_CONTROL
		default:
			break; // no actions here
		} // switch (pumpMode) 
		break;
	case ClickEncoder::Clicked:
		encoder->setAccelerationEnabled(true);
		switch (pumpMode) {
		case MODE_RPM:
			pumpMode++;
			{
				float factor = (currentRpm > 0) ? rpm2millilitreCw : rpm2millilitreCcw;
				currentRpm = round(currentRpm * factor) / factor;
			}
			break;
		case MODE_LITRES_PER_HOUR:
		#if ENABLE_MODE_BOTTLING 
			pumpMode = MODE_BOTTLING;
			// halt pump
			currentRpmRate = rpmHaltRate;
			targetRpm = 0;
		#elif ENABLE_EXTERNAL_CONTROL		
			pumpMode = MODE_EXT_CONTROL;
			// halt pump
			currentRpmRate = rpmHaltRate;
			targetRpm = 0;
		#else
			pumpMode = MODE_RPM;
		#endif // MODE_BOTTLING			
			break;
		#if ENABLE_MODE_BOTTLING
		case MODE_BOTTLING:
			if (halfStepLimit < 1) // dont switch if pumping right now
			#if ENABLE_EXTERNAL_CONTROL
				pumpMode = MODE_EXT_CONTROL;
		#else
				pumpMode = MODE_RPM;
		#endif
			break;
		#endif
		#if ENABLE_EXTERNAL_CONTROL
		case MODE_EXT_CONTROL:
			pumpMode = MODE_RPM;
			// halt pump
			currentRpmRate = rpmHaltRate;
			targetRpm = 0;
			extControlDisabledFlag = 1;  // user should confirm pump start every time in ext mode
			break;
		#endif // ENABLE_EXTERNAL_CONTROL

		default:
			pumpMode = MODE_RPM;
			break; // no actions here
		}
		eepromWrite();
		displayPumpData();
		break;
	case ClickEncoder::Held:
		// don't start calibration if pumping right now or in external control mode 
	#if ENABLE_MODE_BOTTLING
		if (pumpMode == MODE_BOTTLING && halfStepLimit > 1)
			break;
	#endif
	#if ENABLE_EXTERNAL_CONTROL
		if (pumpMode == MODE_EXT_CONTROL)
			break;
	#endif // ENABLE_EXTERNAL_CONTROL

		if (calibratePump()) {
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
		lastTime = now + 1500;

		// Wait button release
		while (encoder->getButton() == ClickEncoder::Held)
			; // do nothing
		break;
	default:
		break;
	} // switch (encoder->getButton())

	// display motor speed twice per second
	if (now > lastTime + ((halfStepLimit > 0) ? 100 : 500)) {
		displayPumpData();
		lastTime = now;
	}

	// every 10 ms change motor speed
	adjustMotorSpeed();
}

// Alter motor speed when accelerating / decelerating
//========================================================================

void adjustMotorSpeed() {
	if (speedAdjustmentTicks > 10) {
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
		speedAdjustmentTicks = 0;
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
			currentRpm += 0.01 * rpmHaltRate;
			if (currentRpm > targetRpm)  currentRpm = targetRpm;
			setMotorSpeed(currentRpm);
		}

		if (targetRpm - currentRpm < -1e-5) {
			currentRpm -= 0.01 * rpmHaltRate;
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

	const int revolutionNum = 200;
	if (selection != 1) {
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
		halfStepLimit = 2L * revolutionNum * stepsPerRevolution;
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

	if (selection != 0) {
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
		halfStepLimit = 2L * revolutionNum * stepsPerRevolution;
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


