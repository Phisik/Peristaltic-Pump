minkowski() {
    
    linear_extrude(1)
        text("Abc", $fn=5);
     cylinder(d1=2, d2=0, $fn=10);
}