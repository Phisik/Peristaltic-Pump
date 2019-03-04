$fn=100;

difference(){
    translate([0,3,0]) cube([50, 6, 15], center=true);
    
    for(i=[0:3]){
        translate([-18+i*12,0,-20]) cylinder(d=9-0.5*i, h=50);
        translate([-18+i*12,0,-7.5-0.01]) cylinder(d1=10-0.5*i, d2=0, h=10);
        translate([-18+i*12,0,-2.5+0.01]) cylinder(d2=10-0.5*i, d1=0, h=10);
    }
}

