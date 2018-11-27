
// Length
h1=20; // [10:500]
h2=15; // [10:500]  

// Length cone
cone_length=3; // [1:200] 

//Radius
r1=7/2; 
r2=9/2;  
  

//wall thickness
th=1.2; 

//teeth heigth
teeth=0.4; //[0.2:0.1:10]

//wide of the teeths
wt=2; //[0.2:0.1:10]

//distance of the teeths
dt=3; //[0.3:0.1:11]

/* clearance*/
eps = 0.1;

$fn=75;

// conjunction
r3=10;
alpha = 45;


translate([0,-r3,h2]) {	
rotate([alpha,0,0])
    translate([0,r3,0])
        tube(r1, h1, 0, 2);
conjunction();
}
tube(r2, h2, 0, 4.5);



//difference(){
//union(){
//	translate([0,0,0])      
//        cylinder(h=h1,r1=r1,r2=r1);
//    
//    if(alpha>10) {
//        translate([0,-r3,h1])	
//            conjunction();
//        translate([0,-r3,h1])	
//            rotate([alpha,0,0])
//                translate([0,r3,0])	
//                     tube(r2, h2, 3);
//    } else {
//        translate([0,0,h1])	
//            cylinder(h=cone_length,r1=r1,r2=r2);
//        translate([0,0,h1+cone_length])	
//        cylinder(h=h2,r1=r2,r2=r2);
//    }
//	
//        
//        
//
////lower rings
//	translate([0,0,dt-wt/2]) cylinder(h=wt,r1=r1,r2=r1+teeth);
//    translate([0,0,dt+wt/2]) cylinder(h=0.5,r2=r1,r1=r1+teeth);
//    
//	translate([0,0,2*dt-wt/2]) cylinder(h=wt,r1=r1,r2=r1+teeth);
//    translate([0,0,2*dt+wt/2]) cylinder(h=0.5,r2=r1,r1=r1+teeth);
//    
//	translate([0,0,3*dt-wt/2]) cylinder(h=wt,r1=r1,r2=r1+teeth);
//    translate([0,0,3*dt+wt/2]) cylinder(h=0.5,r2=r1,r1=r1+teeth);
//    
//    
//}
//	translate([0,0,0])      cylinder(h=h1,r1=r1-th,r2=r1-th);
//        translate([0,0,h1])	cylinder(h=cone_length,r1=r1-th,r2=r2-th);
//	translate([0,0,h1+cone_length])	cylinder(h=h2,r1=r2-th,r2=r2-th);
// 
//}

module tube(r, h, n, to){
    difference(){
        union(){
            cylinder(h=h,r=r);
            // rings
            if(n>0)
                for(i=[0:n-1]) {
                    translate([0,0, to + i*dt]) 
                        cylinder(h=wt,r2=r+teeth,r1=r);
                    translate([0,0, to + i*dt + wt]) 
                        cylinder(h=0.5,r2=r,r1=r+teeth);
                }
        }
    
        translate([0,0,-eps])cylinder(h=h+2*eps,r=r-th);
    }
    
   
}

use <Naca_sweep.scad>  // http://www.thingiverse.com/thing:1208001

module conjunction() {
outer = conicbow_traj(r=r3, a1=0, a2 = alpha,  r1=r2, r2=r1, N=100);
inner = conicbow_traj(r=r3, a1=alpha, a2 = 0,  r1=r1-th, r2=r2-th, N=100); 

sweep(concat(outer, inner), close = true);  

function conicbow_traj(r=100, a1=0, a2 = 180, r1=10, r2=20, N=100) =
  [for (i=[0:N-1]) 
      let(R = r1+i*(r2-r1)/N) Rx_(a1+i*(a2-a1)/(N-1), 
        Ty_(r, circle_(R)))
  ];

function circle_(r=10, N=$fn) =
  [for (i=[0:N-1]) [r*sin(i*360/N), r*cos(i*360/N), 0]]; 
  }

