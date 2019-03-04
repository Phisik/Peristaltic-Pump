use <bevel_extrude.scad>

module shape()
{
	text("(c)", size=30);
}

bevel_extrude(height=3,bevel_depth=2,$fn=8) shape();

// translate([-40,0,0]) shape();


