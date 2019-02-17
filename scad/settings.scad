// Created by Phisik on 2018-12-16
// Main settings header for peristaltic pump

// Licence GPL

// some extra gap for clean difference render in preview
eps = 0.1;

// Part smoothness, the more the better
$fn = 100;

layer_height = 0.25;

// Silicon hose settings
//====================================================================================

// NB! The larger the hose radius the higher torque is required
r_hose = 22;        // radius of hose center line
                    // Update: after addition of groove hose center is at r_hose + hose_groove
d_hose = 9;         // hose external diameter

hose_wall = 1.5;   // hose wall thickness
					// NB! hose_wall affects both stator & rotor geometry
					
hose_clearance = 0.2;   // extra clearance between hose & bearings
						// NB! hose_clearance affects only rotor geometry
						// If you experience lack of suction reduce hose_clearance 
						// If motor misses steps increase hose_clearance, take motor with higher 
						// torque or hose with thinner wall

hose_fitting_delta_d = 1; // difference between hose and hose fitting diameter
						
						
// Stator settings
//====================================================================================
wall = 4;             // wall thickness, should be larger than hose_groove by 1mm or more
hose_groove = 0;     // NB! Rudiment form v1. Do not change. 
					 // groove depth for hose to stay in place 

h_base = 4.75;             // height of stator base
h_support_base = 2;		// height of support base

stator_support_gap = 1;		// gap between support & stator base for spring tension

stator_facet = 10;   // facets of outer support corners

mount_width  = 8;
mount_length = 10;

d_screw = 3.5;           // screw diameter
d_nut = 6.5;             // nut & screw head diameter
d_nut_tight = 5.5/0.87; // nut diameter for nuts to be fitted with soldering iron

l_handle = 10;

r_water_sink = 5.5;

need_nut_cuts_in_support = 0; // cut holes for nuts in support
need_nut_cuts_in_stator  = 1; // cut holes for support nut in stator

hose_fixator_length = 15;  // length of hose inset for fixing it on the stator


// Bearing settings
//====================================================================================
bearingNum = 3;     // Number of bearings per arm

h_bearing = 5;      // bearing height
d_bearing = 14;     // OD
d_bearing_axis = 5;         // ID
w_axis = 1;         // thickness of inner bushing



// Rotor settings
//==================================================================================== 
d_rotor = 17.5;   // Outer rotor diameter

arm_num = 3;    // number of rotor arms
w_arm  = 15;    // arm width
h_arm = 3;      // arm height

enable_hose_guides = 1;
w_hose_guide = 8;
hose_guide_clearance = 0.75;
r_hose_guide_facet = 2;

gap = 0.2;      // some clearance between joins & moving parts

arm_clearance = 4;  // clearance between arm and stator

bearing_axes_clearance = 0.075;  	     // clearance on rotor base between bearings and axes
rotor_bearing_axes_clearance = 0.45;  // clearance on rotor cap between axes and holes
bearing_clearance = 1; 				 // distance from stator base to the lowest arms

// 1602 lcd settings
//====================================================================================
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


// Nema 17 settings
//====================================================================================
nema_screw_distance = 31;  
nema_shaft_diameter = 5.5;
nema_shaft_height = 25;
nema_knob_diameter = 23;
nema_knob_height = 2.5;
nema_width = 42.3;
nema_angle_cut = 4;
