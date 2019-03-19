// Created by Phisik on 2018-10-20
// Case for open source peristaltic pump

// Licence GPL 
// You are free to distibute & contribute to this part in any form

// Settings
//==============================================================================
include <settings.scad>
use <lcd1602.scad>


assembly      = 0;   // render assembly
render_top    = 1;   // render top part
render_bottom = 0;   // render bottom part
render_side_panel = 1;   // render bottom part

need_motor_plane_support = 1;

rubber_legs = true;
d1_rubber_legs = 15;
d2_rubber_legs = 18;
h_rubber_legs  = 5;

h_case = 68;
w_case = 115;
l_case = 117;

nema_clearance = 0.8;

// Front panel settings
front_angle=20;
back_angle=45;
wall_case = 0.46*cos(front_angle)*4;
wall_size_scale = 1/cos(front_angle);  // when 3d printing tilded walls will thicker




w_front_panel = w_lcd_plate + 36.8;

d_lcd_stand = d_lcd_hole+2.5;
d_lcd_stand_hole = 2;

r_ext = r_hose + d_hose/2 + wall - hose_groove;
handle_length = r_ext+l_handle;
w_back_panel = handle_length+r_ext;


extra_lcd_n_ecn_shift = 5;

lcd_clearance = -0.1;
x_1602_shift = 11;
y_1602_shift = -y_lcd_shift+extra_lcd_n_ecn_shift;
z_1602_shift = -6;

x_enc_shift = -40;
y_enc_shift = 2.2+extra_lcd_n_ecn_shift;
z_enc_shift = -8.5;


// PCB settings
l_pcb = 58.4;
h_pcb = 1.6;
w_pcb = 49;
x_pcb_hole = 51.4;
y_pcb_hole = 41.91;
d_pcb_hole = 2;
x_shift_pcb = -10;
y_shift_pcb = -29.5;
z_shift_pcb = 8;
d_pcb_leg = 7;
d_pcb_leg_hole = 2;

alpha = 1;

// ventillation holes settings
n_vent = 3;
h_vent = 20;
w_vent = 2.5;
dist_vent = 8;
vent_y_shift = 45;
vent_z_shift = 27;

// bottom plate settings
d_bottom_legs_holes = 4;
d_bottom_holes = 2.5;
d_bottom_legs = 20;
h_bottom_legs = 4;
legs_shift = w_case/2-d_bottom_legs/2-7.5;
cover_clearance = 0.3;

// some extra clips to hold side walls
clip_shift = 30;
l_clip = 8;
w_clip = 3;
h_clip = 2;
clip_wall = 2;
clip_clearance = 0.5;

// bottom plate holders
holders_size = 10;
d_holder_hole = 2;

// Assemble
//==============================================================================
if(assembly) {
    alpha = 1;
    

    color("red", alpha) 
        translate([x_shift_pcb, y_shift_pcb, z_shift_pcb]) 
        pcb();
    
    color("green", alpha) 
        translate([0,-l_case, h_case-w_back_panel*sin(back_angle)]) 
        rotate([back_angle, 0, 0])  
        translate([0,handle_length, 0]) 
        import("head-assembly.stl");
    
    color("orange", alpha) 
    // front panel with lcd & encoder
        translate( [  0,
                     -w_front_panel/2*cos(front_angle)+wall_case,
                      h_case-0.5*w_front_panel*sin(front_angle)
                   ])
        rotate([-front_angle,0,0])
        translate([x_enc_shift-1.8, y_enc_shift-3, z_enc_shift+10])
        rotate([0,0,+90]) 
        import("deps/encoder-knob.stl");
    
    if(render_top)       case_main();
    if(render_bottom)    { 
        bottom_cover(); 
        if(rubber_legs) color("gray") draw_rubber_legs(); 
    }
} else {
    if(render_top)       rotate([180+front_angle, 0, 0]) case_main();
    if(render_bottom)    bottom_cover();
}

// Bottom cover
//==============================================================================
module bottom_cover() {
    difference() {
        translate([-w_case/2 + wall_case + cover_clearance,
                   -l_case + wall_case + cover_clearance, 0]) 
           cube([
                w_case-2*wall_case-2*cover_clearance, 
                l_case-wall_case-2*cover_clearance, 
                wall_case], center=false);
    
        if(rubber_legs) {
            translate([0,-l_case/2 + 0.5*wall_case + cover_clearance, -eps]) {
                translate(legs_shift*[1,1,0])    
                    cylinder(d=d_bottom_legs_holes, h=h_bottom_legs);
                translate(legs_shift*[1,-1,0])    
                    cylinder(d=d_bottom_legs_holes, h=h_bottom_legs);
                translate(legs_shift*[-1,1,0])    
                    cylinder(d=d_bottom_legs_holes, h=h_bottom_legs);
                translate(legs_shift*[-1,-1,0])    
                    cylinder(d=d_bottom_legs_holes, h=h_bottom_legs);
           }
        } else {  
            translate([x_shift_pcb, y_shift_pcb, 0]){
              translate([x_pcb_hole, y_pcb_hole, -eps]/2)
                    cylinder(d=d_bottom_holes, h=wall_case+1);
                translate([x_pcb_hole, -y_pcb_hole, -eps]/2)
                    cylinder(d=d_bottom_holes, h=wall_case+1);
                translate([-x_pcb_hole, y_pcb_hole, -eps]/2)
                    cylinder(d=d_bottom_holes, h=wall_case+1);
                translate([-x_pcb_hole, -y_pcb_hole, -eps]/2)
                    cylinder(d=d_bottom_holes, h=wall_case+1);
            } // pcb holes
        }
        
                 
        // holders for bottom plate
        translate([-w_case/2+wall_case-eps, eps, -eps]) 
            holder_hole(holders_size, d_bottom_holes);
        translate([-w_case/2+wall_case-eps, -l_case+wall_case+holders_size-eps, -eps]) 
            holder_hole(holders_size, d_bottom_holes);
        translate([w_case/2-wall_case+eps, -l_case+wall_case-eps, -eps]) 
            rotate([0,0,180]) 
            holder_hole(holders_size, d_bottom_holes);
        translate([w_case/2-wall_case+eps, -holders_size+eps, -eps]) 
            rotate([0,0,180]) 
            holder_hole(holders_size, d_bottom_holes);
    }

    
   
   if(rubber_legs) {  
        // pcb holder
        translate([x_shift_pcb, y_shift_pcb, 0]){
            translate([x_pcb_hole, y_pcb_hole, +eps]/2) pbc_leg();
            translate([x_pcb_hole, -y_pcb_hole, 0]/2)   pbc_leg();
            translate([-x_pcb_hole, y_pcb_hole, 0]/2)   pbc_leg();
            translate([-x_pcb_hole, -y_pcb_hole, 0]/2)  pbc_leg();
        } // pcb holder
        
        translate([x_shift_pcb+l_pcb/2+15, y_shift_pcb-5, 0]) pbc_leg();
    } else {
        translate([0,-l_case/2 + 0.5*wall_case + cover_clearance, -h_bottom_legs]) {
            translate(legs_shift*[1,1,0])    
            cylinder(d=d_bottom_legs, h=h_bottom_legs);
                translate(legs_shift*[1,-1,0])    
            cylinder(d=d_bottom_legs, h=h_bottom_legs);
                translate(legs_shift*[-1,1,0])    
            cylinder(d=d_bottom_legs, h=h_bottom_legs);
                translate(legs_shift*[-1,-1,0])    
            cylinder(d=d_bottom_legs, h=h_bottom_legs);
       }
    }

    module pbc_leg() {
        difference() {
            cylinder(d=d_pcb_leg, h=z_shift_pcb);
            cylinder(d=d_pcb_leg_hole, h=z_shift_pcb);
        }
    }
    
    module holder_hole(size, d){
        translate([size/2, -size/2, 0])
                cylinder(d=d,h=20);
    }
    
    // clips
    // we can print either clips or plastic legs
    if(rubber_legs){
        translate([-w_case/2 + cover_clearance +wall_case, 0, wall_case]) {
            translate([0, -clip_shift-l_clip, 0])
                cube([w_clip, l_clip, h_clip]);
            translate([0, -l_case+wall_case+clip_shift, 0])
                cube([w_clip, l_clip, h_clip]);
        }
         
        translate([+w_case/2 - cover_clearance - wall_case - w_clip, 0, wall_case]) {
            translate([0, -clip_shift-l_clip, 0])
                cube([w_clip, l_clip, h_clip]);
            translate([0, -l_case+wall_case+clip_shift, 0])
                cube([w_clip, l_clip, h_clip]);
        }
        
        translate([0, -l_case+wall_case+cover_clearance, wall_case]) {
            translate([w_case/2 -clip_shift  - l_clip, 0, 0])
                cube([l_clip, w_clip, h_clip]);
            translate([-w_case/2 + clip_shift, 0, 0])
                cube([l_clip, w_clip, h_clip]);
        }
        
        translate([- l_clip/2, -w_clip-cover_clearance, wall_case])
            cube([l_clip, w_clip, h_clip]);
    }
}

module draw_rubber_legs(){
    translate([0,-l_case/2 + 0.5*wall_case + cover_clearance, -h_rubber_legs]) {
        translate(legs_shift*[1,1,0])    leg();
        translate(legs_shift*[1,-1,0])    leg();
        translate(legs_shift*[-1,1,0])    leg();
        translate(legs_shift*[-1,-1,0])   leg();
    }
       
    module leg(){
       difference() {
           cylinder(d1=d1_rubber_legs, d2=d2_rubber_legs, h=h_rubber_legs);
           translate([0,0,-eps]){
              cylinder(d=d1_rubber_legs/2, h=h_rubber_legs/2);
              cylinder(d=3, h=h_rubber_legs+2*eps);
           }
       }
    }
}

// Case main/top part
//==============================================================================
module case_main() {

    // front panel with lcd & encoder
    translate( [  0,
                 -w_front_panel/2*cos(front_angle)+wall_case,
                  h_case-0.5*w_front_panel*sin(front_angle)
               ])
    rotate([-front_angle,0,0])
    translate([0,0,-wall_case]) {
        difference(){
            translate([-w_case/2,-w_front_panel/2,0]) 
               cube([w_case, w_front_panel, wall_case], center=false);

            translate([x_1602_shift, y_1602_shift, z_1602_shift])
                translate([x_lcd_shift,y_lcd_shift,10])
                    cube([l_lcd+lcd_clearance*2, w_lcd+2*lcd_clearance, 20], center=true);
            // encoder shaft
            translate([x_enc_shift - 2, y_enc_shift - 2.57,-8.5])
                rotate([0,0,-90]) {
                    cylinder(d=7.5, h=20);
                }
            // encoder pin
            translate([x_enc_shift - 2, y_enc_shift - 2.57+5.8,-5+1])
                cube([2.5, 1, 10], center=true);
            translate([x_enc_shift - 2, y_enc_shift - 2.57-5.8,-5+1])
                cube([2.5, 1, 10], center=true);
        } // difference()
        
        // lcd holders
        translate([x_1602_shift, y_1602_shift, z_1602_shift+h_lcd_plate]) {
           
            translate([x_lcd_hole, y_lcd_hole, -eps]/2) 
                lcd_stand();
            translate([x_lcd_hole, -y_lcd_hole, -eps]/2)
                lcd_stand();
            translate([-x_lcd_hole, y_lcd_hole, -eps]/2)
                lcd_stand();
            translate([-x_lcd_hole, -y_lcd_hole, -eps]/2)
                lcd_stand();
        }// translate()
        
        // encoder holders
//        translate([x_enc_shift+7.25, y_enc_shift, z_enc_shift+1.5]){
//            translate([-0.5, 6.5, 0]) lcd_stand(-z_enc_shift+2*eps-1);
//            translate([-0.5, -7.4, 0]) lcd_stand(-z_enc_shift+2*eps-1);
//        } // translate()

        
        if(assembly) {
            color("blue", alpha) 
            translate([x_1602_shift, y_1602_shift, z_1602_shift]) 
                 lcd1602();
            color("purple", alpha)  
            translate([x_enc_shift, y_enc_shift, z_enc_shift])
                rotate([0,0,+90]) import("deps/ky-040.stl");
        }  // if(assembly)
    } // translate()


    // front wall
    translate([-w_case/2,0,0]) 
        cube([w_case, wall_case, h_case-w_front_panel*sin(front_angle)], center=false);

    // back panel
    translate([-w_case/2,-l_case,0]) 
    difference(){
        cube([w_case, wall_case, h_case-w_back_panel*sin(back_angle)], center=false);
        translate([w_case-10, 20, h_case/2]) rotate([90,0,0]) 
            cylinder(d=8.1/cos(30), h=40, $fn=6);
    } 
    
      // side panels
    if(render_side_panel) difference(){
        union(){
            // if(!assemble)
                // right panel
                translate([-w_case/2+wall_case*(1-wall_size_scale),-l_case,0]) 
                    cube([wall_case*wall_size_scale, l_case+wall_case, h_case+eps], center=false);

            // left panel
            translate([+w_case/2-wall_case,-l_case,0]) 
                cube([wall_case*wall_size_scale, l_case+wall_case, h_case+eps], center=false);
        }   // uinon()
        
        // cut angles
        translate( [  -w_case, -w_front_panel*cos(front_angle)+wall_case-eps, h_case])
            rotate([-front_angle, 0,0])
            cube([2*w_case + 2*eps, l_case+h_case, h_case], center=false);
            
        translate( [  -w_case, 
                      -l_case-(h_case-w_back_panel*sin(back_angle))/tan(back_angle)+eps, 0])
            rotate([back_angle, 0,0])
            cube([2*w_case, l_case+h_case, h_case], center=false);
        
        // ventilation holes
        for(i=[0:n_vent-1])
            translate( [-10-w_case/2, -l_case+vent_y_shift+(w_vent+dist_vent)*i, vent_z_shift])
                cube([w_case + 20, w_vent, h_vent], center=false);
    } // difference()


    // top panel
    translate([-w_case/2,-l_case+w_back_panel*cos(back_angle),h_case-wall_case]) 
            cube([ w_case, 
                   l_case+wall_case-w_back_panel*cos(back_angle)-w_front_panel*cos(front_angle), 
                   wall_case], center=false);

    // head panel
    

    
    translate([0,-l_case,h_case]) 
    difference(){ union(){
        translate([-w_case/2,0,-w_back_panel*sin(back_angle)])
            rotate([back_angle, 0, 0])
            translate([0,0,-wall_case])
            cube([ w_case, w_back_panel, wall_case], center=false);
     if(need_motor_plane_support) {   
        translate([-w_case/2,0,-w_back_panel*sin(back_angle)])
            rotate([back_angle, 0, 0]) {
            multmatrix([ [1, 0, 0, 0],
                         [0, 1, -sin(back_angle-front_angle), 2.5],
                         [0, 0, 1, -5-wall_case],
                         [0, 0, 0, 1] ])
                 cube([ 15, w_back_panel, 5], center=false);
                multmatrix([ [1, 0, 0, w_case-15],
                         [0, 1, -sin(back_angle-front_angle), 2.5],
                         [0, 0, 1, -5-wall_case],
                         [0, 0, 0, 1] ])
                 cube([ 15, w_back_panel, 5], center=false);
            }
        }
    }
        
        translate([0,-0, -w_back_panel*sin(back_angle)]) 
            rotate([back_angle, 0, 0])  
            translate([0,handle_length, 0]) { 
                    intersection(){   
                        w =  nema_width+2*nema_clearance;
                        h = 100;
                        cube([w, w, h], center=true);   
                        rotate([0,0,45]) {
                            w =  nema_width*sqrt(2)-2*nema_angle_cut/sqrt(2)+2*nema_clearance;
                           cube([w,w,h], center=true);
                        }
                    }

                    // Head mount holes
                    translate([r_ext+mount_length/2, -handle_length+mount_length/2, -wall-eps]) 
                        cylinder(d=d_screw, 10, $fn=6);
                    translate([-r_ext-mount_length/2, -handle_length+mount_length/2, -wall-eps]) 
                        cylinder(d=d_screw, 10, $fn=6);
                    translate([r_ext+mount_length/2, r_ext-mount_length/2, -wall-eps]) 
                        cylinder(d=d_screw, 10, $fn=6);
                    translate([-r_ext-mount_length/2, r_ext-mount_length/2, -wall-eps]) 
                        cylinder(d=d_screw, 10, $fn=6);
                } // translate() 
    } // difference()
    

    // holders for bottom plate
    translate([-w_case/2+wall_case-eps, eps, wall_case]) 
        holder(holders_size);
    translate([-w_case/2+wall_case-eps, -l_case+wall_case+holders_size-eps, wall_case]) 
        holder(holders_size);
    translate([w_case/2-wall_case+eps, -l_case+wall_case-eps, wall_case]) 
        rotate([0,0,180]) 
        holder(holders_size);
    translate([w_case/2-wall_case+eps, -holders_size+eps, wall_case]) 
        rotate([0,0,180]) 
        holder(holders_size);
    
    // clips
    // we can print either clips or plastic legs
    if(rubber_legs){
        translate([-w_case/2+wall_case, l_clip+clip_wall, wall_case]) {
            translate([0, -clip_shift-l_clip, 0])
                clip_holder();
            translate([0, -l_case+wall_case+clip_shift, 0])
                clip_holder();
        }
         
        translate([+w_case/2 - wall_case, -clip_wall, wall_case]) {
            translate([0, -clip_shift-l_clip, 0])
                rotate([0,0,180]) clip_holder();
            translate([0, -l_case+wall_case+clip_shift, 0])
                rotate([0,0,180]) clip_holder();
        }
        
        translate([ - clip_wall, -l_case + wall_case - eps, wall_case]) {
            translate([w_case/2 - clip_shift  - l_clip, 0, 0])
                rotate([0,0,90])  clip_holder(5);
            translate([-w_case/2 + clip_shift, 0, 0])
                rotate([0,0,90]) clip_holder(5);
        }
        
        translate([l_clip/2+clip_wall, 0, wall_case])
            rotate([0,0,-90]) clip_holder(2);
    }
    
    
     module lcd_stand(h=-z_1602_shift+2*eps){
           difference(){
                cylinder(d=d_lcd_stand, h=-z_1602_shift+eps);
                cylinder(d=d_lcd_stand_hole, h=h);
            }            
        }
}


// Bottom cover holders
//==============================================================================
module holder(size){
    difference(){
        rotate([90,0,0])
            linear_extrude(size)
            polygon(points=[[0,0],[1,0],[1,1/2],[0,1.5]]*size);
        
        translate([size/2, -size/2, 0])
            cylinder(d=d_holder_hole,h=9);
    }
}

module clip_holder(f=3){
    a = w_clip+clip_wall+cover_clearance;
    b = 1+h_clip; c = f*b;
    
    difference(){
        rotate([90,0,0])
            linear_extrude(l_clip+2*clip_wall)
            polygon(points=[[0,0],[a,0],[a,b],[0,c]]);
        translate([-eps, -clip_wall-l_clip-clip_clearance, -eps])
            cube([w_clip+cover_clearance+eps+clip_clearance, l_clip+2*clip_clearance, h_clip+clip_clearance]);
    }
}



// PBC 3d model
//==============================================================================
module pcb()
{
    difference() {
     translate([0,0,h_pcb/2]) 
        cube([l_pcb, w_pcb, h_pcb], center=true);
    
      translate([x_pcb_hole, y_pcb_hole, -eps]/2)
            cylinder(d=d_pcb_hole, h=2);
        translate([x_pcb_hole, -y_pcb_hole, -eps]/2)
            cylinder(d=d_pcb_hole, h=2);
        translate([-x_pcb_hole, y_pcb_hole, -eps]/2)
            cylinder(d=d_pcb_hole, h=2);
        translate([-x_pcb_hole, -y_pcb_hole, -eps]/2)
            cylinder(d=d_pcb_hole, h=2);
    }
    
    translate([15,0,8]) 
        cube([18, 33, 15], center=true);
    translate([-3,5,8]) 
        cube([15, 20, 15], center=true);
    translate([-20,-5,8]) 
        cube([15, 20, 15], center=true);
}


