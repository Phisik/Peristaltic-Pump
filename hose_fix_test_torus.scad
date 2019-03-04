$fn=100;


difference(){
    cube([60, 12, 15], center=true);
    
    for(i=[0:3])
        translate([-23+15*i,0,-20])
            cylinder(d=9-0.5*i, h=50);
}
intersection(){
    cube([60, 12, 15], center=true);
for(i=[0:3])
    translate([-23+15*i,0,0]) {
        d=9-0.5*i-1;
        translate([0,0,-3]) torus(d/2, 2.5);
        translate([0,0,3]) torus(d/2, 2.5);
    }
}



module torus(r_int, r){
    rotate_extrude(convexity = 10)
    translate([r_int+r, 0, 0])
        circle(r = r);
}