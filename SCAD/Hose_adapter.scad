
// Length
h1=12; // [10:500]
h2=12; // [10:500]  
// Length cone
cone_length=3; // [1:200] 
//Radius
r1=5.5/2; 
r2=7/2;  
//wall thickness
th=1; 
//teeth heigth
teeth=0.4; //[0.2:0.1:10]
//wide of the teeths
wt=2; //[0.2:0.1:10]
//distance of the teeths
dt=4; //[0.3:0.1:11]

/* [Hidden]*/

$fn=360;



difference(){
union(){
	translate([0,0,0])      cylinder(h=h1,r1=r1,r2=r1);
        translate([0,0,h1])	cylinder(h=cone_length,r1=r1,r2=r2);
	translate([0,0,h1+cone_length])	cylinder(h=h2,r1=r2,r2=r2);
        
        

//lower rings
	translate([0,0,dt-wt/2]) cylinder(h=wt,r1=r1,r2=r1+teeth);
    translate([0,0,dt+wt/2]) cylinder(h=0.5,r2=r1,r1=r1+teeth);
    
	translate([0,0,2*dt-wt/2]) cylinder(h=wt,r1=r1,r2=r1+teeth);
    translate([0,0,2*dt+wt/2]) cylinder(h=0.5,r2=r1,r1=r1+teeth);
//	translate([0,0,3*dt-teeth]) cylinder(h=wt,r1=r1,r2=r1+teeth);
//upper rings
	translate([0,0,h1+cone_length+h2-wt-dt+teeth]) cylinder(h=wt,r1=r2+teeth,r2=r2);
	translate([0,0,h1+cone_length+h2-wt-2*dt+teeth]) cylinder(h=wt,r1=r2+teeth,r2=r2);
//	translate([0,0,h1+cone_length+h2-wt-3*dt+teeth]) cylinder(h=wt,r1=r2+teeth,r2=r2);
}
	translate([0,0,0])      cylinder(h=h1,r1=r1-th,r2=r1-th);
        translate([0,0,h1])	cylinder(h=cone_length,r1=r1-th,r2=r2-th);
	translate([0,0,h1+cone_length])	cylinder(h=h2,r1=r2-th,r2=r2-th);
 
}


