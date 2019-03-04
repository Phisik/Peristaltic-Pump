 $fn=75;
 
 d_cut = 12;
 h_cut = 6.5;
 
difference(){
    union(){ 
        scale([0.9, 0.9, 1.5])
            import("deps/encoder_knob.stl");
        cylinder(d1=15.5, d2=13, h=18);
        difference(){
            cylinder(d=7.5, h=17);
            translate([2.5,-25,0]) 
                cube([50,50,50]);
        }
    }
    translate([0,0,-0.01])
        cylinder(d=d_cut, h=h_cut);
    difference(){
        cylinder(d=6.5, h=17);
        translate([1.5,-25,0]) cube([50,50,50]);
    }
}
//translate([0,0,h_cut])
//    cylinder(d=d_cut, h=0.3);

//difference(){
//            cylinder(d=8.5, h=17);
//            translate([2.5,-25,0]) 
//                cube([50,50,50]);
//    difference(){
//        cylinder(d=6.5, h=17);
//        translate([1.5,-25,0]) cube([50,50,50]);
//        }
//    }