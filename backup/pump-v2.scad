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

partNum = 1; // 1 - stator
             // 1 - rotor base
             // 1 - rotor cover
             // 1 - stator cover

// need_sink_groove = 0;

if(assemble) {
    alpha = 1;
    need_sink_groove = 0;
    
    // Part smoothness, the more the better
    $fn = 30;
    
    color("gray", alpha) translate([0,0,-40.2]) 
        import("Nema17_40h.stl");
    color("red", alpha)  hose();
    //color("green", alpha)    
        difference() {
            union() {
                stator();
                 if(need_hose_handle_v2) hose_handle_v2_cover();
            }
            translate([0,-50,-25])cube(100);
        }
    //color("green", alpha)    
        rotor();
} else {
    // Part smoothness, the more the better
   $fn = 150;
   
   if(partNum==1) stator();
   if(partNum==2) rotor(1);
   if(partNum==3) rotate([0,180,0]) rotor(2);
   if(partNum==4) rotate([0,180,0]) hose_handle_v2_cover();
}

// Functions
//===============================================================

// check input
if(hose_groove > 2*hose_wall + hose_clearance) {
    echo ("<b style=\"color:red\">Warning: too deep hose groove, value should be reduced!</b>");
}

// width of compressed hose 
w_hose_pressed = 3.1415*(d_hose/2-hose_wall)+2*hose_wall;
echo(w_hose_pressed=w_hose_pressed);

// check input
if(w_hose_pressed > bearingNum * h_bearing) {
    echo ("<b style=\"color:red\">Warning: total bearings height is less than compressed hose width, suppose to increase bearing number!</b>");
}


// 2 possible hoose centerline z-position
h_hose1 = h_base + w_hose_pressed/2;
h_hose2 = h_base +  bearing_clearance + h_arm + gap + bearingNum/2*h_bearing;

// we choose the highest one
h_hose = (h_hose1>h_hose2)?h_hose1:h_hose2;

// difference between hose and hose fitting diameter
hose_fitting_delta_d = 1;
// input & output hose hole diameter
d_hose_hole = d_hose + hose_fitting_delta_d;

// position of bearing axis 
r_bearing = r_hose-d_bearing/2+(d_hose/2-2*hose_wall)+0*hose_groove-hose_clearance;
echo(r_bearing=r_bearing);

// stator external radius
r_ext = r_hose + d_hose/2 + wall - hose_groove;
echo(r_ext=r_ext);

// hose external radius
r_hose_ext = r_hose + d_hose/2 ;
echo(r_hose_ext=r_hose_ext);

// stator overall height
h_stator = h_hose + h_arm + d_hose/2 + 3;

// handle length from rotation axis
handle_length = r_ext+l_handle;

// check input
if(2*r_bearing < d_bearing+d_rotor+1) {
    echo ("<b style=\"color:red\">Warning: bearings will touch rotor axis, increase hose raduis!</b>");
}

if(bearingNum*h_bearing  < w_hose_pressed - 2*hose_wall) {
    echo ("<b style=\"color:red\">Warning: you may need more bearings, hose won't be fully compressed!</b>");
}

// Hose
//===============================================================
module hose(){
    translate([0,0,h_hose])  
    difference() {
        rotate_extrude(angle = 180)
            translate([r_hose-0.5+0*hose_groove, 0, 0])
            circle(d=d_hose);
        translate([-50, -100, -50])
            cube([100,100,100]);
    }
    rotate([0,0,-angle])
             translate([-r_hose+0.5-0*hose_groove, 0, h_hose])   
             rotate([90,0,0])
             cylinder(d=d_hose, h=40);
     rotate([0,0,+angle])
             translate([r_hose-0.5+0*hose_groove, 0, h_hose])   
             rotate([90,0,0])
             cylinder(d=d_hose, h=40);
}

// Stator
//===============================================================
module stator() {
    difference(){
          union(){
                cylinder(r = r_ext, h=h_stator);
                
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
                
                if(need_hose_handle_v2)  hose_handle_v2(); 
            } // union()
            
        // rotor cut out
        translate([0,0,h_base-eps]) 
                cylinder(r = r_ext-wall, h=50-eps);
            
        hose_groove();
        
        
        // nema shaft
        translate([0,0,nema_knob_height + 2*layer_height])
                cylinder(d=nema_shaft_diameter, h=nema_shaft_height);
        // nema knob
        translate([0,0,-eps])
                cylinder(d=nema_knob_diameter, h=nema_knob_height);
        
        // screws
        for(alpha=[45:90:315]) {
            translate([sin(alpha),cos(alpha),0]*nema_screw_distance/sqrt(2)-[0,0,eps]){
                cylinder(d=d_screw, h_base + eps);
                translate([0,0,2])
                    cylinder(d=d_nut,h_base);
            }
        } // for()
        
        if(need_ears) {   
            mounting_distance = r_ext+ l_ear - r1_ear;
            echo(mounting_distance=mounting_distance);
            translate([mounting_distance,0,h_base-1]){
                cylinder(d=d_nut,h=1+eps);
                cylinder(d=d_screw,h=2*h_base, center=true);
            }
            translate([-mounting_distance,0,h_base-1]){
                cylinder(d=d_nut,h=1+eps);
                cylinder(d=d_screw,h=2*h_base, center=true);
            }
        } // if()
        
         
        // hose input & output holes
         rotate([0,0,-angle])
             translate([-r_hose+hose_fitting_delta_d/2-0*hose_groove, 0, h_hose])   
             rotate([90,0,0])
             cylinder(d=d_hose_hole, h=100);
            
         rotate([0,0,+angle])
             translate([r_hose-hose_fitting_delta_d/2+0*hose_groove, 0, h_hose])   
             rotate([90,0,0])
             cylinder(d=d_hose_hole, h=100);
        
        // hose holder
        if(need_hose_handle_v2)  {
            y_shift = sqrt(2*(r_hose_ext+0*hose_groove)*d_hose_hole - d_hose_hole*d_hose_hole);
            translate([-r_ext-eps, -handle_length-y_shift, h_hose]) 
                cube([2*r_ext+2*eps, handle_length, h_stator]);
            
            
            translate([-r_hose_ext+hose_groove, -y_shift-eps, h_base]) 
                cube([2*(r_hose_ext-hose_groove), y_shift, h_stator]);
            
                r_groove = max(1, 2*hose_groove);
    
            // extra cut for hose_groose near input/output holes
            translate([-r_hose_ext+r_groove, 0, h_hose])
            rotate([90,0,0]) hull(){
                translate([0,w_hose_pressed/2,0])cylinder(r=r_groove, h=y_shift+eps);
                translate([0,-w_hose_pressed/2,0]) cylinder(r=r_groove, h=y_shift+eps);
            }
           // extra cut for hose_groose near input/output holes
            translate([r_hose_ext-r_groove, 0, h_hose])
            rotate([90,0,0]) hull(){
                translate([0,w_hose_pressed/2,0])cylinder(r=r_groove, h=y_shift+eps);
                translate([0,-w_hose_pressed/2,0]) cylinder(r=r_groove, h=y_shift+eps);
            }
        }

        if(need_sink_groove) {
            // water sink groove
            w_sink_groove = 4;
            translate([0,0,h_base])
                torus(r_hose_ext-w_sink_groove/2-hose_groove, w_sink_groove);
            translate([0,-r_hose_ext+w_sink_groove/2+hose_groove,h_base])
                rotate([90, 0, 0]) 
                scale([1.5, 1, 1]) cylinder(d=w_sink_groove, h=50, $fn=6);
        }
    } // difference()
    
    difference() {
        translate([0,0, nema_knob_height])
        cylinder(d = nema_shaft_diameter+3, h=h_base+arm_clearance/3-nema_knob_height);
        cylinder(d=nema_shaft_diameter, h=nema_shaft_height);
    }
    
    if(need_hose_handle_v1) {
        difference(){
            translate([-r_hose+hose_fitting_delta_d/2-0*hose_groove, 0, h_hose-0.1*eps])   
            rotate([90,0,0])
                hose_handle_v1();
            cylinder(r = r_ext, h=h_stator);
        }
        
        difference(){
            translate([r_hose-hose_fitting_delta_d/2+0*hose_groove, 0, h_hose])   
            rotate([90,0,0])
                hose_handle_v1();
            cylinder(r = r_ext, h=h_stator);
        }
    }
    
    
 }   
 
// hose groove
 //===============================================================
module hose_groove(){
  hull(){
    r_groove = max(1, 2*hose_groove);
    shift = w_hose_pressed/2;
    
    translate([0,0,h_hose-shift])  
        torus(r_hose_ext-r_groove, 2*r_groove);
    translate([0,0,h_hose+shift])  
        torus(r_hose_ext-r_groove, 2*r_groove);
  }
}

// draw hose handle
module hose_handle_v1(){
  difference(){
     hull(){
         d = d_hose+hose_fitting_delta_d+wall-0*hose_groove/2+hose_groove/2;
         cylinder(d=d, h=handle_length);
         translate([0,-h_hose,0]) cylinder(d=d, h=handle_length);
     }

     cylinder(d=d_hose+1, h=40);
     
     translate([-25,0,0]) 
        cube([50,d_hose+wall,50]);
     translate([-25,-h_hose-d_hose-wall,-1]) 
        cube([50,d_hose+wall,50]);
     
     // nut
     translate([-handle_length/2, -h_hose/2, handle_length-8]) 
     cube([ handle_length, 2, 4]); 
  }
}
    
// Hose handle cover
//===============================================================
module hose_handle_v2_cover(){
    difference(){
                union(){ 
         hose_handle_v2();
                    
             translate([-r_ext, r_clip/2-handle_length, h_hose+cover_gap])
                hull(){
                    cylinder(d=r_clip, h=h_stator-h_hose-cover_gap);
                    translate([0, 0.45*handle_length, 0])
                    cylinder(d=r_clip, h=h_stator-h_hose-cover_gap);
                }
            translate([r_ext, r_clip/2-handle_length, h_hose+cover_gap])
                hull(){
                    cylinder(d=r_clip, h=h_stator-h_hose-cover_gap);
                    translate([0, 0.45*handle_length, 0])
                    cylinder(d=r_clip, h=h_stator-h_hose-cover_gap);
                }
        }
        y_shift = sqrt(2*(r_hose_ext+0*hose_groove)*d_hose_hole - d_hose_hole*d_hose_hole);
        translate([-r_ext-eps, -handle_length-y_shift, -eps]) 
            cube([2*r_ext+2*eps, handle_length, h_hose+eps+0.5]);
        translate([-r_ext-eps, -y_shift-eps, -eps]) 
            cube([2*r_ext+2*eps, y_shift+2*eps, h_stator + 2*eps]);
        
         // hose input & output holes
     rotate([0,0,-angle])
         translate([-r_hose+hose_fitting_delta_d/2-0*hose_groove, 0, h_hose])   
         rotate([90,0,0])
         cylinder(d=d_hose_hole, h=100);
    
     rotate([0,0,+angle])
         translate([r_hose-hose_fitting_delta_d/2+0*hose_groove, 0, h_hose])   
         rotate([90,0,0])
         cylinder(d=d_hose_hole, h=100);
    }
}
// Hose handle
//===============================================================
cover_gap = 0.5;
r_clip = 6;
module hose_handle_v2(){
  difference(){
    translate([-r_ext, -handle_length, 0]) {
        cube([2*r_ext, handle_length, h_stator]);
    }            
   
    // rotor cut out
    translate([0,0,-eps])
        cylinder(r = r_hose + d_hose/2, h=50-eps);
    hose_groove();
    
     // hose input & output holes
     rotate([0,0,-angle])
         translate([-r_hose+hose_fitting_delta_d/2-0*hose_groove, 0, h_hose])   
         rotate([90,0,0])
         cylinder(d=d_hose_hole, h=100);
    
     rotate([0,0,+angle])
         translate([r_hose-hose_fitting_delta_d/2+0*hose_groove, 0, h_hose])   
         rotate([90,0,0])
         cylinder(d=d_hose_hole, h=100);
    
    // plastic saving cut 
    r_psc=r_hose_ext-d_hose-hose_fitting_delta_d - wall+hose_groove;
    translate([0,-handle_length,-eps])
        scale([1, 0.65*(handle_length-r_ext)/r_psc, 1])
        cylinder(r = r_psc, h=50-eps);
        
    // screws & nuts
    nut_depth = 4;
    screw_depth = 3;
    n_layers = 2;
    cover_screw_hole_distance = -r_ext+d_hose + hose_fitting_delta_d + 4 + d_screw;
    translate([cover_screw_hole_distance, -r_ext, -eps]) {
        translate([0,0,nut_depth+n_layers*layer_height])
            cylinder(d=d_screw, h = h_stator-nut_depth-screw_depth-2*n_layers*layer_height);
        translate([0,0,h_stator-screw_depth]) 
            cylinder(d=d_nut, h = 10);
        rotate([0,0,-30]) 
            cylinder(d=5.4/0.87, h = nut_depth, $fn=6);
    }
    // screws & nuts
    translate([-cover_screw_hole_distance, -r_ext, -eps]) {
        translate([0,0,nut_depth+2*layer_height])
            cylinder(d=d_screw, h = h_stator-nut_depth-screw_depth-2*n_layers*layer_height);
        translate([0,0,h_stator-screw_depth]) 
            cylinder(d=d_nut, h = 10);
        rotate([0,0,30]) 
            cylinder(d=5.5/0.87, h = nut_depth, $fn=6);
    }
  }
}


// Rotor assembly, 0 = full, 1 - bottom/base, 2 - top/cap
//===============================================================
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
//===============================================================
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
        
            
            // holes for bearing axes
            translate([r_bearing*sin(angle), r_bearing*cos(angle), -eps])
                cylinder(d=d_bearing_axis + 0.4, h=1*h_arm+gap -1);
            // hole for the screws
            translate([r_bearing*sin(angle), r_bearing*cos(angle), -eps])
                cylinder(d=2.5, h=1*h_arm+gap + 2*eps);
             
        }
    }
    translate([0,0,gap]) cylinder(d=d_rotor, h=h_arm);
}


// Rotor base
//===============================================================
module rotor_base(drawBearings=true) {
    screw_height = h_arm + bearingNum*h_bearing/2;
    translate([0,0,-h_arm - bearingNum/2*h_bearing - gap])
    difference()
    {
            // axis
            cylinder(d=d_rotor, h=bearingNum*h_bearing+h_arm+2*gap);
            // screw
        
        
            translate([0,0,screw_height])
                rotate([-90,0,180/arm_num]) 
                cylinder(d=d_screw/0.866, h=40, $fn=6);
            // nut
            rotate([-90,0,180/arm_num]) {
                translate([0,-screw_height,3.5]) hull(){
                    cylinder(d=d_nut, h=2.7, $fn=6);
                    translate([0,-50,0]) cylinder(d=d_nut, h=2.7, $fn=6);
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
//===============================================================
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
//===============================================================
module shaft() {
    rotate([0,0,90+180/arm_num]) 
        difference(){
            d = 5+0.4;
            cylinder(d=d, h=50);
            translate([2.2,-10,4]) cube([20, 20, 50]);
        }
    // translate([2,-10,5]) cube(20);
}


// Torus to be used for rouded edges
//===============================================================
module torus(r, d) {
    // translate([0,0,d/2])
    rotate_extrude(convexity = 100)
    translate([r, 0, 0])
    circle(d=d);
}
