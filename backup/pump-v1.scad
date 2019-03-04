// Created by Phisik on 2018-09-30
// This is fully parametric perictaltic pump. I have use silicon hose OD=7 mm 
// & ID=5.5 mm, with 0.75 mm wall. Nema 17HS4401S motor was able to pump
// 600-700 ml per minute (30-40 litres per hour) easily.
//
// Hoses with thicker walls may require to reduce motor speed.

// Licence GPL: you are free to distibute & contribute to this part in any form

include <settings.h>

// Assembly
//===============================================================
assemble = 1;

if(assemble) {
    alpha = 1;
    
    color("gray", alpha) translate([0,0,-40.2]) import("Nema17_40h.stl");
    color("red", alpha)  hose();
    //color("green", alpha)    
        difference() {
            stator();
            translate([0,-50,-25])cube(100);
        }
    //color("green", alpha)    
        rotor();
} else {
   // stator();
   rotor(1);
   // rotor(2);
}

// Settings
//===============================================================

// Part smoothness, the more the better
$fn = 100;

// some clearance for clean difference() render
eps = 0.1;

// Functions
//===============================================================

// check input
if(hose_groove > 2*hose_wall + hose_clearance) {
    echo ("<b style=\"color:red\">Warning: too deep hose groove, value should be reduced!</b>");
}

// width of compressed hose 
w_hose_pressed = 3.1415*(d_hose/2-hose_wall)+2*hose_wall;


h_hose1 = h_base + w_hose_pressed/2;
h_hose2 = h_base +  bearing_clearance + h_arm + gap + bearingNum/2*h_bearing;

h_hose = (h_hose1>h_hose2)?h_hose1:h_hose2;

// position of bearing axis 
r_bearing = r_hose-d_bearing/2+(d_hose/2-2*hose_wall)+hose_groove-hose_clearance;

// check input
if(2*r_bearing < d_bearing+d_rotor+1) {
    echo ("<b style=\"color:red\">Warning: bearings will touch rotor axis, increase hose raduis!</b>");
}

if(bearingNum*h_bearing  < w_hose_pressed - 2*hose_wall) {
    echo ("<b style=\"color:red\">Warning: you may need more bearings, hose won't be fully compressed!</b>");
}

module hose(){
    translate([0,0,h_hose])  
        rotate_extrude(angle = 180)
            translate([r_hose-0.5+hose_groove, 0, 0])
                circle(d=d_hose);
    rotate([0,0,-angle])
             translate([-r_hose+0.5-hose_groove, 0, h_hose])   
             rotate([90,0,0])
             cylinder(d=d_hose, h=40);
     rotate([0,0,+angle])
             translate([r_hose-0.5+hose_groove, 0, h_hose])   
             rotate([90,0,0])
             cylinder(d=d_hose, h=40);
}

module stator() {
    r_ext = r_hose + d_hose/2 + wall ;
    
    difference(){
        union(){
            cylinder(r = r_ext, h=h_hose + h_arm + d_hose/2 + 3);
            
            if(need_ears) {   
                translate([r_ext,0,0])
                    hull(){
                        translate([l_ear - r1_ear,0,0])
                            cylinder(r = r1_ear, h=h_base);
                        translate([-r2_ear,0,0])
                            cylinder(r = r2_ear, h=h_base);
                    }
                
                translate([-r_ext,0,0])
                    hull(){
                        translate(-[l_ear - r1_ear,0,0])
                            cylinder(r = r1_ear, h=h_base);
                        translate(-[-r2_ear,0,0])
                            cylinder(r = r2_ear, h=h_base);
                    }
            } // if()
        } // union()
 
        translate([0,0,h_base-eps]) 
            cylinder(r = r_hose + d_hose/2, h=50-eps);
        
        // nema shaft
        translate([0,0,-eps])
                cylinder(d=nema_shaft_diameter, h=10);
        
        // screws
        for(alpha=[45:90:315]) {
            translate([sin(alpha),cos(alpha),0]*nema_screw_distance/sqrt(2)-[0,0,eps]){
                cylinder(d=d_screw, h_base + eps);
                translate([0,0,2])
                    cylinder(d=d_nut,h_base);
            }
        } // for()
        
        if(need_ears) {   
            translate([r_ext+ l_ear - r1_ear,0,h_base-1]){
                cylinder(d=d_nut,h=1+eps);
                cylinder(d=d_screw,h=2*h_base, center=true);
            }
            translate([-r_ext- l_ear + r1_ear,0,h_base-1]){
                cylinder(d=d_nut,h=1+eps);
                cylinder(d=d_screw,h=2*h_base, center=true);
            }
        } // if()
        
        
        // hose groove
        hull(){
            r_groove = 1.5*hose_groove;
            shift = w_hose_pressed/2-0.9*r_groove;
            
            translate([0,0,h_hose-shift])  
                torus(r_hose+hose_groove-r_groove+d_hose/2, 2*r_groove);
            translate([0,0,h_hose+shift])  
                torus(r_hose+hose_groove-r_groove+d_hose/2, 2*r_groove);
        }
         
        // hose input & output holes
         rotate([0,0,-angle])
             translate([-r_hose+0.5-hose_groove, 0, h_hose])   
             rotate([90,0,0])
             cylinder(d=d_hose+1, h=40);
            
         rotate([0,0,+angle])
             translate([r_hose-0.5+hose_groove, 0, h_hose])   
             rotate([90,0,0])
             cylinder(d=d_hose+1, h=40);
    }
    
    if(need_hose_handle) {
        difference(){
            translate([-r_hose+0.5-hose_groove, 0, h_hose-0.1*eps])   
            rotate([90,0,0])
                hose_handle();
            cylinder(r = r_ext, h=h_hose + h_arm + d_hose/2 + 3);
        }
        
        difference(){
            translate([r_hose-0.5+hose_groove, 0, h_hose])   
            rotate([90,0,0])
                hose_handle();
            cylinder(r = r_ext, h=h_hose + h_arm + d_hose/2 + 3);
        }
    }
 }   
    // draw hose handle
    module hose_handle(){
            difference(){
                 hull(){
                     d = d_hose+1+wall-hose_groove/2;
                     cylinder(d=d, h=l_handle);
                     translate([0,-h_hose,0]) cylinder(d=d, h=l_handle);
                 }
            
                 cylinder(d=d_hose+1, h=40);
                 
                 translate([-25,0,0]) 
                    cube([50,d_hose+wall,50]);
                 translate([-25,-h_hose-d_hose-wall,-1]) 
                    cube([50,d_hose+wall,50]);
                 
                 // nut
                 translate([-l_handle/2, -h_hose/2, l_handle-8]) 
                 cube([ l_handle, 2, 4]); 
        }
    }


// Rotor assembly, 0 = full, 1 - bottom/base, 2 - top/cap
module rotor(type = 0){
    difference() {
        translate([0, 0,h_hose]) 
        union()
        {
            if(type == 0 || type ==1) rotor_base();
            if(type == 0 || type ==2) translate([0,0,bearingNum/2*h_bearing]) rotor_cap();
            if(type == 0) bearings();
        }
       shaft();
    } 
}


// Rotor cap
module rotor_cap(drawBearings=true) {
    for(i = [1 : arm_num]) {
        angle = 360/arm_num*i;
        
        difference(){
            // arms
             //translate([0,0,h_arm])
                union(){
                    // arms
                    translate([0,0,gap]) 
                        hull(){ 
                            cylinder(d=w_arm, h=h_arm);
                            r = r_hose+d_hose/2-w_arm/2-arm_clearance;
                            translate([r*sin(angle), r*cos(angle), h_arm/2]) 
                                torus(w_arm/2-h_arm/2, h_arm);
                        }
                    // bearings axes    
                    translate([r_bearing*sin(angle), r_bearing*cos(angle), 0])
                        cylinder(d=d_bearing_axis+2*w_axis, h=gap);
                }
        
            // holes fo 
            translate([r_bearing*sin(angle), r_bearing*cos(angle), -eps])
                cylinder(d=d_bearing_axis + 0.2, h=1*h_arm+gap -1);
                
            translate([r_bearing*sin(angle), r_bearing*cos(angle), -eps])
                cylinder(d=2.5, h=1*h_arm+gap + 2*eps);
             
        }
    }
    translate([0,0,gap]) cylinder(d=d_rotor, h=h_arm);
}


// Rotor base
module rotor_base(drawBearings=true) {
    translate([0,0,-h_arm - bearingNum/2*h_bearing - gap])
        difference(){
            // axis
            cylinder(d=d_rotor, h=bearingNum*h_bearing+h_arm+2*gap);
            // screw
            translate([0,0,7])
                rotate([-90,0,180/arm_num]) 
                cylinder(d=3/0.866, h=40, $fn=6);
            // nut
            rotate([-90,0,180/arm_num]) {
                translate([0,-7,3.5]) hull(){
                    cylinder(d=d_nut, h=2.7, $fn=6);
                    translate([0,-10,0]) cylinder(d=d_nut, h=2.7, $fn=6);
                }
            }
        }    
    
    // arms
    translate([0,0,-bearingNum/2*h_bearing])
        for(i = [1 : arm_num]) {
            angle = 360/arm_num*i;
            
            // arm
            translate([0,0,-h_arm-gap]) 
                hull(){ 
                    cylinder(d=w_arm, h=h_arm);
                    r = r_hose+d_hose/2-w_arm/2-arm_clearance;
                    translate([r*sin(angle), r*cos(angle), h_arm/2]) 
                        torus(w_arm/2-h_arm/2, h_arm);
                } // hull()
                
            // bearing axis
            translate(r_bearing*[sin(angle), cos(angle), 0]) {
                difference(){ 
                    height = bearingNum*h_bearing + gap + h_arm-1;
                    cylinder(d=d_bearing_axis-0.2, h=height);
                    translate([0,0,height-10])
                    cylinder(d=2.2, h=10+eps);
                } // difference()
                translate([0, 0, -gap])
                    cylinder(d=d_bearing_axis+2*w_axis, h=gap);
            } // translate()
        } // for()

}    

        

// draw bearings   
module bearings(alpha = 1){
    color("blue", alpha) 
    for(i = [1 : arm_num]) {
        angle = 360/arm_num*i;
        translate(r_bearing*[sin(angle), cos(angle), 0]) 
            for(j = [1:bearingNum] )
                translate([0,0,(j-1-bearingNum/2)*h_bearing+0.1])
                    // scale 605zz bearing model to fit actual bearing size
                    scale([1,1,0]*d_bearing/14+[0,0,(h_bearing-0.2)/5])
                        import("605zz.stl");
       
    } // for
}


// Nema 17 shaft
module shaft() {
    rotate([0,0,90+180/arm_num]) 
        difference(){
            d = 5+0.4;
            cylinder(d=d, h=24);
            translate([2.2,-10,4]) cube(20);
        }
    // translate([2,-10,5]) cube(20);
}


// Torus to be used for rouded edges
module torus(r, d) {
    // translate([0,0,d/2])
    rotate_extrude(convexity = 100)
    translate([r, 0, 0])
    circle(d=d);
}
