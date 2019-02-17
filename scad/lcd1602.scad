// Created by Phisik on 2018-10-20
// Openscad mode for 1602 display with I2C expander

// Licence GPL
// You are free to distibute & contribute to this part in any form

include <settings.scad>

module lcd1602(){
    // plate
    difference() 
    {   
        translate([0,0,0.8]) 
        cube([l_lcd_plate, w_lcd_plate, h_lcd_plate], center=true);
        
        translate([x_lcd_hole, y_lcd_hole, -eps]/2)
            cylinder(d=d_lcd_hole, h=2);
        translate([x_lcd_hole, -y_lcd_hole, -eps]/2)
            cylinder(d=d_lcd_hole, h=2);
        translate([-x_lcd_hole, y_lcd_hole, -eps]/2)
            cylinder(d=d_lcd_hole, h=2);
        translate([-x_lcd_hole, -y_lcd_hole, -eps]/2)
            cylinder(d=d_lcd_hole, h=2);
        
        translate([-6, -w_lcd_plate/2+2.54, -eps]) for(i=[0:15])
            translate([i*2.54, 0, 0])cylinder(d=1, h=2);
    }
    
    // lcd
    translate([x_lcd_shift,y_lcd_shift,4.375])
        cube([l_lcd, w_lcd, h_lcd], center=true);
    translate([-l_lcd/2+x_lcd_shift,0,h_lcd_plate]) prism();
    
    
    // pins
    translate([-6, -w_lcd_plate/2+2.54, -8]) for(i=[0:15])
            translate([i*2.54, 0, 0])
                rotate([0,0,45]) cylinder(d=0.8, h=11, $fn=4);
    
    // i2c
    // plate
    translate([l_lcd_i2c/2-6-2,w_lcd_i2c/2-+w_lcd_plate/2+2.54-1,-6]) {
        difference() 
        {   
            translate([0,0,h_lcd_i2c/2]) 
            cube([l_lcd_i2c, w_lcd_i2c, h_lcd_i2c], center=true);
            translate([-l_lcd_i2c/2+2, -w_lcd_i2c/2+1, -eps]) for(i=[0:15])
                translate([i*2.54, 0, 0])cylinder(d=1, h=2);
        }
        translate([0,0,-1.25+h_lcd_i2c/2]) 
            cube([7.5, 10, 2.5], center=true);
        translate([12,-2,-2.5+h_lcd_i2c/2]) 
            cube([7, 7, 5], center=true);
    }

    module prism(){
        l1=17/2;
        l2=13/2;
        w=3; 
        h=2.75;
        
        CubePoints = [
            [ 0, -l1,    0 ],  // 0
            [ 0, l1,    0 ],  // 1 
            [ -w,  l2,   0 ],  // 2
            [ -w, -l2,   0 ],  // 3
            [ 0, -l1,   h ],  // 0
            [ 0,  l1,    h ],  // 1 
            [ -w,  l2,   h ],  // 2
            [ -w, -l2,   h ],  // 3
            ];
      
        CubeFaces = [
          [0,1,2,3],  // bottom
          [4,5,1,0],  // front
          [7,6,5,4],  // top
          [5,6,2,1],  // right
          [6,7,3,2],  // back
          [7,4,0,3]]; // left
          
        polyhedron( CubePoints, CubeFaces );
    }
}