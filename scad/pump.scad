// Created by Phisik on 2018-09-30
// This is fully parametric perictaltic pump. I have use silicon hose OD=7 mm 
// & ID=5.5 mm, with 0.75 mm wall. Nema 17HS4401S motor was able to pump
// 600-700 ml per minute (30-40 litres per hour) easily.
//
// Hoses with thicker walls may require to reduce motor speed.

// Licence GPL: you are free to distibute & contribute to this part in any form

include <settings.scad>

// Assembly
//===============================================================
assemble = 0;
halfcut = 0;
moved_apart = 1;

gap = 1;

partNum = 3; // 1 - stator
             // 2 - stator support
             // 3 - stator cover
             // 4 - rotor base
             // 5 - rotor cover


// To print without skirt we will add some extra material only around the corners
enable_angle_support = 1;
angle_support_gap = .1;
angle_support_w = 15;
angle_support_h = 0.75;
             
// Part smoothness, the more the better
$fn = 100;

//rotate([0,0,360*$t])
if(assemble) {
    alpha = 1;
   
    // Part smoothness, the more the better
    $fn = 30;
    
    // Nema17
    color("gray", alpha) translate([0,0,-40.2]) import("deps/Nema17_40h.stl");
    
    // Hose
    color("red", alpha)  hose();
    
    difference() {
        union() {
            stator_base();
            if(moved_apart)
                translate([0, 60, h_base+gap/2]) stator_support();
            else
                translate([0, 0, h_base+gap/2]) stator_support();
            if(moved_apart) 
                translate([0, 0, 30]) stator_cover();
            else stator_cover();
        }
        if(halfcut) translate([0,-50,-25]) cube(150);
    }
    
    rotor(0);
    
} else {
   if(partNum==1) {
       stator_base();
       if(enable_angle_support) {
           angle_support(angle_support_w, angle_support_h, 
                         -r_ext-mount_length, -handle_length, angle_support_gap, 1);
           angle_support(angle_support_w, angle_support_h, 
                         -r_ext-mount_length, r_ext, angle_support_gap, 2);
           angle_support(angle_support_w, angle_support_h, 
                         r_ext+mount_length, -handle_length, angle_support_gap, 3);
           angle_support(angle_support_w, angle_support_h, 
                         r_ext+mount_length, r_ext, angle_support_gap, 4);
       }
   }
   if(partNum==2) { 
       stator_support();
        if(enable_angle_support) {
           
           angle_support(angle_support_w, angle_support_h, 
                         -r_ext-mount_length, -y_hole_distance+stator_support_gap, angle_support_gap, 1);
           angle_support(angle_support_w, angle_support_h, 
                         -r_ext-mount_length, r_ext-stator_facet, angle_support_gap, 2);
           angle_support(angle_support_w, angle_support_h, 
                         r_ext+mount_length, -y_hole_distance+stator_support_gap, angle_support_gap, 3);
           angle_support(angle_support_w, angle_support_h, 
                         r_ext+mount_length, r_ext-stator_facet, angle_support_gap, 4);
       }
   }
   if(partNum==3) {
       rotate([0,180,0]) translate([0, handle_length, -h_stator]) stator_cover();
       if(enable_angle_support) {
           
           angle_support(angle_support_w*0.75, angle_support_h, 
                         -r_ext+gap-0.05, 0, angle_support_gap, 1);
           angle_support(angle_support_w*0.75, angle_support_h, 
                         -r_ext+gap-0.05, handle_length-y_hole_distance, angle_support_gap, 2);
           angle_support(angle_support_w*0.75, angle_support_h, 
                         r_ext-gap+0.05, 0, angle_support_gap, 3);
           angle_support(angle_support_w*0.75, angle_support_h, 
                         r_ext-gap+0.05, handle_length-y_hole_distance, angle_support_gap, 4);
       }
   }
   if(partNum==4) rotor(1);
   if(partNum==5) rotate([0,180,0]) 
       rotor(2);
}


// width, height, center x0/y0, gap & quadrant number to cut out
module angle_support(w, h, x0=0, y0=0, gap=0, q=1) {
    translate([x0, y0, h/2]) 
    difference() {
        cube([w, w, h], center=true);
        
        i = (q==3 || q==4)?-1:1;
        j = (q==2 || q==4)?-1:1;
        
        translate([i*w/2, j*w/2, 0]) 
            cube([w+2*gap, w+2*gap, h+1], center=true);
    }
}

// Functions
//===============================================================



// width of compressed hose 
w_hose_pressed = 3.1415*(d_hose/2-hose_wall)+2*hose_wall;
echo(w_hose_pressed=w_hose_pressed);


// 2 possible hoose centerline z-position
h_hose = h_base + h_support_base + bearing_clearance + h_arm + gap + bearingNum/2*h_bearing ;


// input & output hose hole diameter
d_hose_hole = d_hose + hose_fitting_delta_d;

// position of bearing axis 
r_bearing = r_hose+0.5*d_hose-2*hose_wall-d_bearing/2-hose_clearance;
echo(r_bearing=r_bearing);

// stator external radius
r_ext = r_hose + d_hose/2 + wall - hose_groove;
echo(r_ext=r_ext);

// hose external radius
r_hose_ext = r_hose + d_hose/2 ;
echo(r_hose_ext=r_hose_ext);

// distance from y=0 to input hole edge
y_hole_distance = 1 + sqrt(2*(r_hose_ext+0*hose_groove)*d_hose_hole - d_hose_hole*d_hose_hole);
            
// stator overall height
h_stator = h_hose +  + bearingNum*h_bearing/2 + gap + h_arm;
echo(h_stator=h_stator);

// handle length from rotation axis
handle_length = r_ext+l_handle;

// total rotor height
rotor_height = bearingNum*h_bearing+2*h_arm+2*gap;

// hose guide height
h_guide_native = rotor_height/2 - w_hose_pressed/2 -0.5;
h_min_guide =h_arm + gap + 0.5;
h_guide = max(h_guide_native, h_min_guide);
echo(h_guide=h_guide);


if(h_guide_native<h_min_guide) {
    echo ("<b style=\"color:red\">Warning: hose OD is too big, hose guides will touch & wear the hose</b>");
}

// Some user input dimension check
//==========================================================
if(2*r_bearing < d_bearing+d_rotor+1) {
    echo ("<b style=\"color:red\">Warning: bearings will touch rotor axis, increase hose raduis!</b>");
}

if(bearingNum*h_bearing  < w_hose_pressed - 2*hose_wall) {
    echo ("<b style=\"color:red\">Warning: you may need more bearings, hose won't be fully compressed!</b>");
}

// check input
if(hose_groove > 2*hose_wall + hose_clearance) {
    echo ("<b style=\"color:red\">Warning: too deep hose groove, value should be reduced!</b>");
}
// check input
if(w_hose_pressed > bearingNum * h_bearing) {
    echo ("<b style=\"color:red\">Warning: total bearings height is less than compressed hose width, suppose to increase bearing number!</b>");
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
    // rotate([0,0,-angle])
             translate([-r_hose+0.5-0*hose_groove, 0, h_hose])   
             rotate([90,0,0])
                    cylinder(d=d_hose, h=handle_length+10);
                
    // rotate([0,0,+angle])
             translate([r_hose-0.5+0*hose_groove, 0, h_hose])   
             rotate([90,0,0])
                    cylinder(d=d_hose, h=handle_length+10);
}


// Stator
//===============================================================

module stator_base() {
    difference(){
        union() {
            translate([-r_ext, -r_hose_ext, 0])
                cube([2*r_ext, r_ext + r_hose_ext, h_base]);
            
            translate([-r_ext-mount_length, -handle_length, 0])
                cube([mount_length, handle_length+r_ext, h_base]);
            translate([r_ext, -handle_length, 0])
                cube([mount_length, handle_length+r_ext, h_base]);

            translate([r_ext, -y_hole_distance-mount_width, 0])
                cube([mount_length, mount_width, h_stator]);
            translate([-r_ext-mount_length, -y_hole_distance-mount_width, 0])
                cube([mount_length, mount_width, h_stator]);
            
            hose_holder();
        } // union()
        
        // screws
        translate([r_ext+mount_length/2, -handle_length+mount_length/2, -eps]) 
            cylinder(d=d_screw, h_stator);
        translate([-r_ext-mount_length/2, -handle_length+mount_length/2, -eps]) 
            cylinder(d=d_screw, h_stator);
        translate([r_ext+mount_length/2, r_ext-mount_length/2, -eps]) 
            cylinder(d=d_screw, h_stator);
        translate([-r_ext-mount_length/2, r_ext-mount_length/2, -eps]) 
            cylinder(d=d_screw, h_stator);
        
        // support screws
        nut_depth = 2.5;
        n_nut_layers = 2;
    
        translate([-r_ext-mount_length/2,r_ext-stator_facet-d_screw-5,-eps]){
            translate([0,0, nut_depth+n_nut_layers*layer_height])
                cylinder(d=d_screw, h_stator);
            cylinder(d=d_nut_tight, h = nut_depth, $fn=6);
        }
        translate([r_ext+mount_length/2,r_ext-stator_facet-d_screw-5, -eps]){
            translate([0,0, nut_depth+n_nut_layers*layer_height])
                cylinder(d=d_screw, h_stator);
            cylinder(d=d_nut_tight, h = nut_depth, $fn=6);
        }
        
        translate([r_ext+mount_length/2, -100, 0.5*(h_stator+h_base)])
            rotate([-90,0,0]) 
            cylinder(d=d_screw, h = 100, $fn=6);
        translate([-r_ext-mount_length/2, -100, 0.5*(h_stator+h_base)])
            rotate([-90,0,0]) 
            cylinder(d=d_screw, h = 100, $fn=6);
        if(need_nut_cuts_in_stator) {
            translate([-r_ext-mount_length/2, -100-y_hole_distance-mount_width+2, 0.5*(h_stator+h_base)])
                rotate([-90,0,0]) 
                cylinder(d=d_nut_tight, h = 100, $fn=6);
            translate([+r_ext+mount_length/2, -100-y_hole_distance-mount_width+2, 0.5*(h_stator+h_base)])
                rotate([-90,0,0]) 
                cylinder(d=d_nut_tight, h = 100, $fn=6);
        }
        
        // nema shaft
        translate([0,0,nema_knob_height + 2*layer_height])
                cylinder(d=nema_shaft_diameter, h=nema_shaft_height);
        // nema knob
        translate([0,0,-eps])
                // cylinder(d=nema_knob_diameter, h=nema_knob_height);
                cylinder(d=nema_knob_diameter+6, h=h_base+2*eps);

        
        // stress release & plastic saving cuts
        translate([r_ext-3,0,-eps])
            cylinder(d=15, h=h_base+2*eps);
        translate([-r_ext+3,0,-eps])
            cylinder(d=15, h=h_base+2*eps);
        translate([0,22,-eps]) hull(){ 
            translate([-5,0,0]) cylinder(d=10, h=h_base+2*eps);
            translate([5,0,0]) cylinder(d=10, h=h_base+2*eps);
        }
        
        // nema screws
        for(alpha=[45:90:315]) {
            translate([sin(alpha),cos(alpha),0]*nema_screw_distance/sqrt(2)-[0,0,eps]){
                cylinder(d=d_screw, h_base + eps);
                translate([0,0,2])
                    cylinder(d=d_nut,h_base);
            }
        } // for()
        
        // water sink 
        translate([0, -y_hole_distance, h_base+r_water_sink])
        rotate([90,0,0])
            cylinder(r=r_water_sink, h=100, $fn=6);
        
        
        // holder cover
        translate([-r_ext - eps, -2*r_hose_ext, h_hose])
                cube([2*r_ext+2*eps, 2*r_hose_ext, handle_length]);
   
        // nema shaft
        translate([0,0,nema_knob_height + 2*layer_height])
            cylinder(d=nema_shaft_diameter, h=nema_shaft_height);
        // nema knob
        translate([0,0,-eps])
            cylinder(d=nema_knob_diameter, h=nema_knob_height);
    } // difference()
    
} // stator()


// Stator support for hose with clearance adjustment 
//===============================================================
module stator_support() {
    module axis_cut(d=nema_shaft_diameter+gap/2, h=h_stator) {
        hull(){
            translate([0,+1, -eps])
                cylinder(d = d, h=h);
            translate([0,-1, -eps])
                cylinder(d = d, h=h);
        }
    } // module axis_cut()
    
    
    difference(){
        hull(){
            translate([-(r_ext-stator_facet), (r_ext-stator_facet), 0])
                cylinder(r=stator_facet, h=h_stator-h_base);
            translate([(r_ext-stator_facet), (r_ext-stator_facet), 0])
                cylinder(r=stator_facet, h=h_stator-h_base);
            translate([-(r_ext), -y_hole_distance+stator_support_gap, 0])
                cube([10, 10, h_stator-h_base]);
            translate([r_ext-10, -y_hole_distance+stator_support_gap, 0])
                cube([10, 10, h_stator-h_base]);
        }
        
        // rotor cutout
        translate([0, 0, h_support_base])
            cylinder(r=r_hose_ext, h=h_stator);  
        
        // cut rounded edges near the hose holder
        translate([-r_hose_ext, -y_hole_distance, h_support_base])
            cube([2*r_hose_ext, y_hole_distance, h_stator]);            
        
        // cutout for motor axis
        axis_cut();
    }
    
    // water protection
    translate([0, 0, h_support_base])
    difference(){
        hull(){
            translate([0,+2, 0])
                cylinder(d = nema_shaft_diameter+3, h=0.75*bearing_clearance);
            translate([0,-2, 0])
                cylinder(d = nema_shaft_diameter+3, h=0.75*bearing_clearance);
        }
        axis_cut() ;
    }
    
    
    // mounting
    difference(){
        translate([r_ext, -y_hole_distance+stator_support_gap, 0])
            cube([mount_length, mount_width, h_stator-h_base]);
        translate([r_ext+mount_length/2, -100, 0.5*(h_stator-h_base)-gap/2])
            rotate([-90,0,0]) 
            cylinder(d=d_screw*1.33, h = 100, $fn=6);
        if(need_nut_cuts_in_support)
            translate([r_ext+mount_length/2, -y_hole_distance+stator_support_gap+mount_width-2, 0.5*(h_stator-h_base)-gap/2])
            rotate([-90,0,0]) 
            cylinder(d=d_nut_tight, h = 100, $fn=6);
    }
    difference(){
        translate([-r_ext-mount_length, -y_hole_distance+stator_support_gap, 0])
            cube([mount_length, mount_width, h_stator-h_base]);
        translate([-r_ext-mount_length/2, -100, 0.5*(h_stator-h_base)-gap/2])
            rotate([-90,0,0]) 
            cylinder(d=d_screw*1.33, h = 100, $fn=6);
        if(need_nut_cuts_in_support)
            translate([-r_ext-mount_length/2, -y_hole_distance+stator_support_gap+mount_width-2, 0.5*(h_stator-h_base)-gap/2])
            rotate([-90,0,0]) 
            cylinder(d=d_nut_tight, h = 100, $fn=6);
    }
    
    // guide   
    translate([r_ext, -y_hole_distance+stator_support_gap+mount_width, 0])
    difference(){
        length = r_ext+y_hole_distance-mount_width-stator_facet-stator_support_gap;
        cube([mount_length, length, h_base]);
        translate([mount_length/2,length-d_screw-5,0]) axis_cut(d_screw);
    }
    
    translate([-r_ext-mount_length, -y_hole_distance+stator_support_gap+mount_width, 0])
    difference(){
        length = r_ext+y_hole_distance-mount_width-stator_facet-stator_support_gap;
        cube([mount_length, length, h_base]);
        translate([mount_length/2,length-d_screw-5,0]) axis_cut(d_screw);
    }
}


// Hose handle
//===============================================================
cover_gap = 0.5;
r_clip = 6;
module hose_holder(){
  difference(){
    translate([-r_ext, -handle_length, 0]) {
        cube([2*r_ext, handle_length-y_hole_distance, h_stator]);
    }            
   
    // rotor cut out
    translate([0,0,-eps])
        cylinder(r = r_hose + d_hose/2, h=50-eps);
    
     // hose input & output holes
     // rotate([0,0,-angle])
         translate([-r_hose+hose_fitting_delta_d/2-0*hose_groove, 0, h_hose])   
         rotate([90,0,0])
         scale([1, 0.6, 1]) cylinder(d=d_hose_hole, h=100);
    
     // rotate([0,0,+angle])
         translate([r_hose-hose_fitting_delta_d/2, 0, h_hose])   
         rotate([90,0,0])
         scale([1, 0.6, 1]) cylinder(d=d_hose_hole, h=100);
    
    // screws & nuts
    nut_depth = 4;
    screw_depth = 3;
    n_nut_layers = 2;
    
    cover_screw_hole_x_distance = -r_ext+d_hose + hose_fitting_delta_d + 4 + d_screw;
    cover_screw_hole_y_distance = -(handle_length+y_hole_distance)*0.5;
    
    translate([cover_screw_hole_x_distance, cover_screw_hole_y_distance, -eps]) {
        translate([0,0,nut_depth+n_nut_layers*layer_height])
            cylinder(d=d_screw, h = h_stator-nut_depth-screw_depth-2*n_nut_layers*layer_height);
        translate([0,0,h_stator-screw_depth]) 
            cylinder(d=d_nut, h = 10);
        rotate([0,0,-30]) 
            cylinder(d=d_nut_tight, h = nut_depth, $fn=6);
    }
    // screws & nuts
    translate([-cover_screw_hole_x_distance, cover_screw_hole_y_distance, -eps]) {
        translate([0,0,nut_depth+n_nut_layers*layer_height])
            cylinder(d=d_screw, h = h_stator-nut_depth-screw_depth-2*n_nut_layers*layer_height);
        translate([0,0,h_stator-screw_depth]) 
            cylinder(d=d_nut, h = 10);
        rotate([0,0,30]) 
            cylinder(d=d_nut_tight, h = nut_depth, $fn=6);
    }
  }
}



// Hose holding cover
//===============================================================
r_fix = 2.5;
echo(d_hose=d_hose);
echo(d_hose_hole=d_hose_hole);
module stator_cover(){
    difference(){
        
         union() {
             hose_holder();
             translate([r_hose-hose_fitting_delta_d/2, -handle_length+5, h_hose])   


rotate([90,0,0])
scale([d_hose_hole/(d_hose-r_fix),0.6,1]) torus(d_hose/2, r_fix);
translate([r_hose-hose_fitting_delta_d/2, -handle_length+15, h_hose])   
rotate([90,0,0])
scale([d_hose_hole/(d_hose-r_fix),0.6,1]) torus(d_hose/2, r_fix);
translate([-r_hose+hose_fitting_delta_d/2, -handle_length+5, h_hose])   
rotate([90,0,0])
scale([d_hose_hole/(d_hose-r_fix),0.6,1]) torus(d_hose/2, r_fix);
translate([-r_hose+hose_fitting_delta_d/2, -handle_length+15, h_hose])   
rotate([90,0,0])
scale([d_hose_hole/(d_hose-r_fix),0.6,1]) torus(d_hose/2, r_fix);
         }
        
         translate([-r_ext-eps, -handle_length-eps,-eps])
            cube([2*r_ext+2*eps, handle_length, h_hose+gap]);
         
        translate([-r_ext-eps, -handle_length-eps,-eps])
            cube([gap, handle_length, h_stator+gap]);
        translate([r_ext-gap+eps, -handle_length-eps,-eps])
            cube([gap, handle_length, h_stator+gap]);

        
         // hose input & output holes
         //rotate([0,0,-angle])
//             translate([-r_hose+hose_fitting_delta_d/2, 0, h_hose])   
//             rotate([90,0,0])
//             scale([1,0.5,1]) cylinder(d=d_hose_hole, h=100);
        
        // rotate([0,0,+angle])
//             translate([r_hose-hose_fitting_delta_d/2, 0, h_hose])   
//             rotate([90,0,0])
//             cylinder(d=d_hose_hole, h=100);
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
module rotor_cap() {
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
                        
                    if(enable_hose_guides)
                        difference() {
                            intersection(){
                                for(i = [1 : arm_num]) {
                                    angle = 360/arm_num*(i+0.5);
                                    
                                    hull()
                                    { 
                                        
                                        translate([0,0,h_arm+gap-h_guide+r_hose_guide_facet]) rotate([0,90,90-angle]) {
                                            translate([0,-0.5*w_hose_guide+r_hose_guide_facet,0]) 
                                                cylinder(r=r_hose_guide_facet, h=r_ext); 
                                            translate([0,+0.5*w_hose_guide-r_hose_guide_facet,0]) 
                                                cylinder(r=r_hose_guide_facet, h=r_ext); 
                                        }
                                    
                                        rotate([0,0,90-angle])
                                            translate([0,-w_hose_guide/2,h_arm+gap-1])
                                            cube([r_ext, w_hose_guide, 1]);

                                    } // hull()     

                                } // for()  
                                translate([0,0,-h_guide])
                                    cylinder(r=r_hose_ext-hose_guide_clearance, h=h_stator)  ;
                            } // intersection()
                            translate([0,0,-50]) cylinder(d=d_rotor+gap, h=100);
                        }
                }
            
            
            // holes for bearing axes
            translate([r_bearing*sin(angle), r_bearing*cos(angle), -eps])
                cylinder(d=d_bearing_axis + rotor_bearing_axes_clearance - bearing_axes_clearance, h=1*h_arm+gap -1);
            // hole for the screws
            translate([r_bearing*sin(angle), r_bearing*cos(angle), -eps])
                cylinder(d=2.5, h=1*h_arm+gap + 2*eps);
                
            
             
        }
    }
    
    translate([0,0,gap]) 
        if(enable_hose_guides) cylinder(d=d_rotor*1.5, h=h_arm);
        else cylinder(d=d_rotor, h=h_arm);
    
    
}
//translate([0,0,gap]) cylinder(d=d_rotor, h=100);

// Rotor base
//===============================================================
module rotor_base() {
    screw_height = h_arm + bearingNum*h_bearing/2;
    
    translate([0,0,-h_arm - bearingNum/2*h_bearing - gap])
        difference() {
            // axis
            cylinder(d=d_rotor, h=rotor_height-h_arm);
            
            // screw
            translate([0,0,screw_height])
                rotate([-90,0,180/arm_num]) 
                cylinder(d=d_screw, h=40, $fn=6);
            
            // nut
            rotate([-90,0,180/arm_num]) {
                translate([0,-screw_height,3.5]) hull(){
                    cylinder(d=d_nut, h=2.7, $fn=6);
                    translate([0,-50,0]) cylinder(d=d_nut, h=2.7, $fn=6);
                }
            } // rotate()
        } // difference()    

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
                    cylinder(d=d_bearing_axis-bearing_axes_clearance, h=height);
                    translate([0,0,height-10])
                    cylinder(d=2.2, h=10+eps);
                } // difference()
                translate([0, 0, -gap])
                    cylinder(d=d_bearing_axis+2*w_axis, h=gap);
            } // translate()
        } // for()
        
        
    // hose guides
    if(enable_hose_guides)
       translate([0,0,-bearingNum/2*h_bearing-h_arm-gap])
        intersection(){
            for(i = [1 : arm_num]) {
                angle = 360/arm_num*(i+0.5);
                
                hull()
                { 
                    
                    translate([0,0,h_guide-r_hose_guide_facet]) rotate([0,90,90-angle]) {
                        translate([0,-0.5*w_hose_guide+r_hose_guide_facet,0]) 
                            cylinder(r=r_hose_guide_facet, h=r_ext); 
                        translate([0,+0.5*w_hose_guide-r_hose_guide_facet,0]) 
                            cylinder(r=r_hose_guide_facet, h=r_ext); 
                    }
                
                    rotate([0,0,90-angle])
                        translate([0,-w_hose_guide/2,])
                        cube([r_ext, w_hose_guide, 1]);

                } // hull()     

            } // for()  
            cylinder(r=r_hose_ext-hose_guide_clearance, h=h_stator)  ;
        } // intersection()
} // module rotor_base()




// draw bearings   
//===============================================================
 use <605zz.scad>;
module bearings(alpha = 1){
    color("blue", alpha) 
    for(i = [1 : arm_num]) {
        angle = 360/arm_num*i;
        translate(r_bearing*[sin(angle), cos(angle), 0]) 
            for(j = [1:bearingNum] )
                translate([0,0,(j-1-bearingNum/2)*h_bearing+0.1])
                    // scale 605zz bearing model to fit actual bearing size
                    scale([1,1,0]*d_bearing/14+[0,0,(h_bearing-0.2)/5])
                        605zz();
       
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
