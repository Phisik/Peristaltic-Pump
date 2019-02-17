include <settings.scad>

$fn = 75;

// Length
h=3.5;

//Radius
r=3.8/2; 

//wall thickness
ew=0.48;
th=ew*2; 

r1=r+th;
r2=r+5*ew;

d1 = 2*r1;
d2 = 2*r2;
echo(d1=d1);
echo(d2=d2);

difference(){
    union(){ 
        cylinder(r=r2, h=1.5);
        cylinder(r=r1, h=h);
    }
    cylinder(r=r, h=h);
}