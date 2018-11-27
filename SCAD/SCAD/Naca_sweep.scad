// Naca4_sweep.scad - sweep library
// Code: Rudolf Huttary, Berlin 
// 1st release : June 2015
// last update: 2017.02.10
// commercial use prohibited

use <naca4.scad>

//example1(); 
//rotate([80, 180, 130])
example(); 

// sweep from NACA1480 to NACA6480 (len = 230 mm, winding y,z = 80°
// sweeps generates a single polyhedron from multiple datasets
module example()
{
  N = 40; 
  sweep(gen_dat(N=5, dz=1,N=N), showslices = false); 
//  sweep(gen_dat(N=5, dz=1,N=N), showslices = true); 
  
  // specific generator function
  function gen_dat(M=10,dz=.1,N=10) = [for (i=[1:dz:M])   
    let( L = length(i))
    let( af = vec3D(
        airfoil_data([.1,.5,thickness(i)], L=length(i), N = N)))
    T_(-L/2, 0, (i+1)*2, af)];  // translate airfoil
  
  function thickness(i) = .5*sin(i*i)+.1; 
  function length(i) = (60+sin(12*(i-3))*30); 
}

module help()
{
  echo(str("\n\nNaca4_sweep library by Rudolf Huttary\n",
  "List of signatures in lib:\n=================\n", 
  "sweep(dat, convexity = 5, showslices = false, close = false, planar_caps = false)  // dat - vec of vec2, with vec1 = airfoil_data\n", 
  "function vec3D(v, z=0)  // expand vec2 to vec3",
  "function rot(w=0, p) // rotate vec2",
  "function T_(x=0, y=0, z=0, v) // translates vec of vec3\n", 
  "function R_(x=0, y=0, z=0, v) // rotates vec of vec3\n", 
  "function Rx_(x=0, v) // x-rotates vec of vec3\n", 
  "function Ry_(y=0, v) // y-rotates vec of vec3\n", 
  "function Rz_(z=0, v) // z-rotates vec of vec3\n", 
  "function T_(x=0, y=0, z=0, v) // translates vec of vec3\n", 
  "function Tx_(x=0, v) // x-translates vec of vec3\n", 
  "function Ry_(y=0, v) // y-translates vec of vec3\n", 
  "function Rz_(z=0, v) // z-translates vec of vec3\n", 
  "function S_(x=0, y=0, z=0, v) // scales vec of vec3\n", 
  "function Sx_(x=0, v) // x-translates vec of vec3\n", 
  "function Sy_(x=0, v) // y-translates vec of vec3\n", 
  "function Sz_(x=0, v) // z-translates vec of vec3\n", 
  "=================\n")); 
}


// generate polyhedron from multiple airfoil_datasets
// dat - vec of vec1, with vec1 = simple polygon like airfoil_data, > 3 points per dataset expected
// use "planar_caps = false" only for non-planar cap faces with cord line symmetry
module sweep(dat, convexity = 5, showslices = false, close = false, planar_caps = false) 
{
  n = len(dat);     // # datasets
  l = len(dat[0]);  // points per dataset 
  if(l<=3) echo("ERROR: sweep() expects more than 3 points per dataset"); 
  if (showslices)  
    for(i=[0:n-1]) polyhedron(points = dat[i], faces = [count(l-1, 0)]);
  else
  {
    obj = sweep_(dat, close=close, planar_caps=planar_caps); 
    polyhedron(obj[0], obj[1], convexity = 5); 
  }
}
  function count(a, b) = [for (i=[a:(a<b?1:-1):b]) i]; 

function sweep_(dat, close = false, planar_caps = true) = 
  let(n=len(dat), l=len(dat[0]))
  let(first = planar_caps?[count(l-1, 0)]: 
            faces_polygon(l, true))  // indices first face
  let(last = planar_caps?[count((n-1)*l,(n)*l-1)]: 
            faces_shift((n-2)*l, faces_polygon(l, false))) // indices last face
  let(faces = close?faces_sweep(l,n, close) :concat(first, last, faces_sweep(l,n))) 
  let(points = [for (i=[0:n-1], j=[0:l-1]) dat[i][j]]) // flatten points vector
    [points, faces]; 

function faces_shift(d, dat) = [for (i=[0:len(dat)-1]) dat[i] + [d, d, d]]; 

  
function del(A, n) = [for(i=[0:len(A)-1]) if (n!=i)A[i]]; 

//// knitting for polyhedron
  function faces_sweep(l, n=1, close = false) = 
      let(M = n*l, n1=close?n+1:n) 
      concat([[0,l,l-1]],   // first face
             [for (i=[0:l*(n1-1)-2], j = [0,1])
                j==0? [i, i+1, (i+l)%M] 
                    : [i+1, (i+l+1)%M, (i+l)%M]
             ]
             ,[[(n1*l-1)%M, (n1-1)*l-1, ((n1-1)*l)%M]
             ]); // last face
      ;
    
  function faces_polygon(l, first = true) = let(odd = (l%2==1), d=first?0:l)
    let(res = odd?concat([[d,d+1,d+l-1]],
      [for (i=[1:(l-3)/2], j=[0,1])(j==0)?[d+i,d+i+1,d+l-i]:[d+i+1,d+l-i-1, d+l-i]]):
      [for (i=[0:(l-4)/2], j=[0,1])(j==0)?[d+i,d+i+1,d+l-i-1]:[d+i+1,d+l-i-2, d+l-i-1]])
    first?facerev(res):res;
    
  function facerev(dat) = [for (i=[0:len(dat)-1]) [dat[i][0],dat[i][2],dat[i][1]]]; 



//// vector and vector set operation stuff ///////////////////////
//// Expand 2D vector into 3D
function vec3D(v, z=0) = [for(i = [0:len(v)-1]) 
  len(v[i])==2?[v[i][0], v[i][1], z]:v[i]+[0, 0, z]]; 

// Translation - 1D, 2D, 3D point vector //////////////////////////
// vector along all axes
function T_(x=0, y=0, z=0, v) = let(x_ = (len(x)==3)?x:[x, y, z])
  [for (i=[0:len(v)-1]) T__(x_[0], x_[1], x_[2], p=v[i])]; 
/// vector along one axis
function Tx_(x=0, v) = T_(x=x, v=v); 
function Ty_(y=0, v) = T_(y=y, v=v); 
function Tz_(z=0, v) = T_(z=z, v=v); 
/// point along all axes 1D, 2D, 3D allowed
function T__(x=0, y=0, z=0, p) = len(p)==3?p+[x, y, z]:len(p)==2?p+[x, y]:p+x; 

//// Rotation - 2D, 3D point vector ///////////////////////////////////
// vector around all axes 
function R_(x=0, y=0, z=0, v) =             // 2D vectors allowed 
  let(x_ = (len(x)==3)?x:[x, y, z])
  len(v[0])==3?Rz_(x_[2], Ry_(x_[1], Rx_(x_[0], v))):
  [for(i = [0:len(v)-1]) rot(x_[2], v[i])];  
// vector around one axis
function Rx_(w, A) = A*[[1, 0, 0], [0, cos(w), sin(w)], [0, -sin(w), cos(w)]]; 
function Ry_(w, A) = A*[[cos(w), 0, sin(w)], [0, 1, 0], [-sin(w), 0, cos(w)]]; 
function Rz_(w, A) = A*[[cos(w), sin(w), 0], [-sin(w), cos(w), 0], [0, 0, 1]]; 


//// Scale - 2D, 3D point vector ///////////////////////////////////
// vector along all axes 
function S_(x=1, y=1, z=1, v) = 
  [for (i=[0:len(v)-1]) S__(x,y,z, v[i])]; 
// vector along one axis
function Sx_(x=0, v) = S_(x=x, v=v); 
function Sy_(y=0, v) = S_(y=y, v=v); 
function Sz_(z=0, v) = S_(z=z, v=v); 
// single point in 2D
function S__(x=1, y=1, z=1, p) = 
  len(p)==3?[p[0]*x, p[1]*y, p[2]*z]:len(p)==2?[p[0]*x+p[1]*y]:[p[0]*x]; 

 
 