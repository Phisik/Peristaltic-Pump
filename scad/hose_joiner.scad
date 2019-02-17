include <settings.scad>

$fn = 75;

// Length
h=40;

//Radius
r=9.5/2; 

//wall thickness
th=0.42*4; 

difference(){
    cylinder(r=r, h=h);
    cylinder(r=r-th, h=h);
}