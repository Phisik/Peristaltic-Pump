// Created by Phisik on 2018-10-20
// Main settings header for peristaltic pump

// Licence GPL

// Part smoothness, the more the better
$fn = 50;

// Silicon hose parameters

// NB! The larger the hose radius the higher torque is required
r_hose = 23;        // radius of hose center line
                    // Update: after addition of groove hose center is at r_hose + hose_groove
d_hose = 7;         // hose diameter
hose_wall = 0.75;    // hose wall thickness
hose_clearance = 0.1; // extra clearance between hose & bearings

// Stator parameters
wall = 3;               // wall thickness
hose_groove = 1.5;      // groove depth for hose to stay in place

h_base = 5;             // height of stator base
d_screw = 3.5;          // screw diameter
d_nut = 6.5;            // nut & screw head diameter

angle = 0;              // extra angle for hose outputs

need_ears = 1;          // add 2 ears to fix pump to the enclosure
l_ear = 12;                 // ears length
r1_ear = d_nut/2 + wall;    // external radius
r2_ear = 2*d_nut + wall;    // internal radius

need_hose_handle = 1;       // add hose handles
l_handle = 37;

// Bearing parameters
bearingNum = 2;     // Number of bearings per arm

h_bearing = 5;      // bearing height
d_bearing = 14;     // OD
d_hole = 5;         // ID
w_axis = 1;         // thickness of inner bush

bearing_clearance = 1; // distance from stator base to the lower arms

// Rotor parameters 
d_rotor = 20;   // Inner diameter

arm_num = 3;    // number of rotor arms
w_arm  = 15;    // arm width
h_arm = 3;      // arm height

gap = 0.2;      // some extra gap to free bearings

arm_clearance = 1.5;  // clearance between arm and stator

// 1602 lcd parameters
y_lcd_hole = 31;
x_lcd_hole = 75;
d_lcd_hole = 3;

l_lcd_plate = 80;
w_lcd_plate = 36.11;
h_lcd_plate = 1.6;

l_lcd = 71.5;
w_lcd = 24.5;
h_lcd = 8.75;

x_lcd_shift = -0.1;
y_lcd_shift = +0.75;

l_lcd_i2c = 42;
w_lcd_i2c = 19;
h_lcd_i2c = 1.5;


// Nema parameters
nema_screw_distance = 31;  // 31 for Nema 17
nema_shaft_diameter = 30;
nema_width = 42.3;
nema_angle_cut = 4;

// some clearance for clean difference() render
eps = 0.1;