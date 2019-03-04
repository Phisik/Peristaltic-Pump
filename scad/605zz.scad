module 605zz() {
	difference(){
		cylinder(d=14, h=5);
		cylinder(d=11, h=5);
	}
	difference(){
		cylinder(d=7, h=5);
		cylinder(d=5, h=5);
	}

	translate([0,0,0.25])
	difference(){
		cylinder(d=11, h=4.5);
		cylinder(d=7, h=4.5);
	}
}