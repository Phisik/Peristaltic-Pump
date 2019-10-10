# SUMMARY
There are several peristaltic pump projects on Thingiverse. However most of them lack source codes and could not be adjusted to use with different hose and bearings. I designed fully parametric peristaltic pump. It can be customized to use any silicon hose, any Nema motor, and any bearings. Source files are supplied. Feel free to modify it and adapt to suit your needs.

I have used silicon hose with OD=7 mm, ID=5.5 mm, and 0.75 mm wall. With that hose Nema 17HS4401S motor was able to pump 700 ml per minute (42 litres per hour) easily. Hoses with thicker walls may require to reduce motor speed or motor with higher torque.

# 3D PRINTING
The latest STL and SCAD source files of pump head are available at https://www.thingiverse.com/thing:3148717. I used 50% infill and 3 perimeters. The higher infill percentage the better. If rotor movement is too tight hose_clearance parameter can be increased. I use PET-G plastic for the case, and ABS for pump head to be able to pump hot liquids.

# HARDWARE
Additionally to pump head you will need to get some electronics:

    1. Nema stepper motor, e.g 17HS4401S. ~$8 
       https://www.aliexpress.com/item/32376023464.html
    2. Stepper motor driver, e.g A4988. ~$1  
       https://www.aliexpress.com/item/1817501276.html
    3. Arduino board. I used Arduino pro mini. ~ $2 
       https://www.aliexpress.com/item/32293707392.html
    4. Rotary encoder with button + 2 resistors or KY-040 Encoder Module. ~ $1 https://www.aliexpress.com/item/32474584136.html
    5. 1602 LCD with I2C converter. ~ $2 https://www.aliexpress.com/item/32836972320.html
    6. Bearings. I used 6 pcs of 605zz bearings. ~$10 for 50 pcs https://www.aliexpress.com/item/32245721720.html
    7. Power supply 12V 1-2A. ~$4 https://www.aliexpress.com/item/1000001113368.html
    8. Rubber legs ~$1.5 for 20pcs https://www.aliexpress.com/item/32844587782.html
    9. DC-DC converter ~$1.5 https://www.aliexpress.com/item/32261885063.html
    10. 2 springs ~$0.1  https://www.aliexpress.com/item/32376023464.html

I have ordered all parts from AliExpress (links are. Total cost of the pump was about $30 including plastic for printing & elecronic components.

# SOFTWARE
Source codes of Arduino firmware for DIY Nema motor based peristaltic pump are available in preset repository. 

Main features:

    1. Adjustable speed via RPM
    2. Adjustable speed via flow in ml per min
    3. Pumping predefined amount of liquid
    4. Pump calibration
    5. Soft start/stop
	6. Moisture sensor support to detect hose failure
	7. External control via analog/PWM signal
	8. Motor uptime & total pumped volume calculation 

Modes can be switched by single click. Double click is used for start/stop. Button hold enables pump calibration mode.

Video showing the pump in action: https://youtu.be/RnriTiulfPw
