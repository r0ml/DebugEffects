// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2025

#include <metal_stdlib>
#include "support.h"
#include <SwiftUI/SwiftUI_Metal.h>

namespace global {
  constant float epsilon = 0.000001;
  constant float tau = 2 * M_PI_F;
  constant float TAU = 2 * M_PI_F;
  constant float pi = M_PI_F;
  constant float PI = M_PI_F;
  constant float e = M_E_F;
  constant float E = M_E_F;
  constant float phi = 1.6180339887498948482; // sqrt(5.0)*0.5 + 0.5;
  constant float PHI = 1.6180339887498948482; // sqrt(5.0)*0.5 + 0.5;
  constant float goldenRatio = phi;
}

using namespace metal;

/** calculate xy size of texture */
float2 textureSize(texture2d<float> t) {
  return float2(t.get_width(), t.get_height());
}

 fragment float4 passthruFragmentFn( VertexOut thisVertex [[stage_in]] ) {
  return thisVertex.color;
}

// =====================================================

float2 nodeAspect(float2 size) {
  return size / min(size.x, size.y);
}

float2 worldCoordAdjusted(float2 position, float2 size) {
  return ((position / (size / 2)) - 1) * nodeAspect(size) * float2(1, -1); // worldCoordAdjusted;
}

float2 worldCoord(float2 position, float2 size) {
  return ((position / (size / 2)) - 1) * float2(1, -1); // worldCoordAdjusted;
}

float2 toWorld(float2 x) {
  return (2 * x - 1) * float2(1, -1);
}

float fix_atan2(float y, float x) {
  if (x == 0) { return M_PI_F / (y < 0 ? -2 : 2); }
  if (y == 0) { return M_PI_F * (x < 0 ? -1 : 0); }
  return atan2(y, x);
}

// this is the PAL/NTSC algorithm for converting rgb to grayscale
float grayscale(const half3 rgb) {
  return dot(half3(0.299, 0.587, 0.114),rgb);
}

float luminance(const half3 rgb) {
  return dot(half3(0.2126, 0.7152, 0.0722), rgb);
}

static constant float eps = 0.0000001;

half3 rgb2hsv(const half3 c) {
  half4 K = half4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
  half4 p = mix(half4(c.bg, K.wz), half4(c.gb, K.xy), step(c.b, c.g));
  half4 q = mix(half4(p.xyw, c.r), half4(c.r, p.yzx), step(p.x, c.r));
  float d = q.x - min(q.w, q.y);
  return half3(abs(q.z + (q.w - q.y) / (6.0 * d + eps)), d / (q.x + eps), q.x);
}

half3 hsv2rgb(const half3 c) {
  half4 K = half4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
  half3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
  return c.z * mix(K.xxx, saturate(p - K.xxx), c.y);
}

half3 hsl2rgb(const half3 c ){
  half3 rgb = clamp( abs(mod(c.x*6 + half3(0, 4, 2), 6) - 3) - 1, 0, 1);
  return c.z + c.y * (rgb-0.5) * (1 - abs(2 * c.z-1) );
}

half3 gammaEncode(const half3 c) {
  return pow(c, half3(1.0 / 2.2));
}

half4 gammaEncode(const half4 c) {
  return half4(pow(c.rgb, half3(1.0 / 2.2)), c.a);
}

half3 gammaDecode(const half3 c) {
  return pow(c, 2.2);
}

half4 gammaDecode(const half4 c) {
  return half4(pow(c.rgb, 2.2), c.a);
}

half4 opaque(const half a) { return half4(a, a, a, 1); }
half4 opaque(const half3 c) { return half4(c, 1); }
half4 opaque(const half a, const half b, const half c) { return half4(a, b, c, 1); }
half4 opaque(const half4 c) { return half4(c.rgb, 1); }
half4 opaque(float3 c) { return half4( half3(c), 1); }
half4 opaque(float4 c) { return opaque(c.rgb); }

float2x2 rot2d(float t) {
  float c, s = sincos(t, c);
  return float2x2(c, s, -s, c);
}

float2x2 rot2dpi(float t) {
  float c = cospi(t), s = sinpi(t);
  return float2x2(c, -s, s, c);
}

// Rotation matrix from angle-axis
float3x3 rotate( float3 axis, float angle) {
  float3x3 K = float3x3(0, axis.z, -axis.y,   -axis.z, 0, axis.x,    axis.y, -axis.x, 0);
  return float3x3(1.0) + K*(float3x3(sin(angle)) + (1.0-cos(angle))*K);
}

// rotate about x axis
float3x3 rotX( float angle) {
  float cx = cos(angle), sx = sin(angle);
  return float3x3(1., 0, 0,      0, cx, sx,      0, -sx, cx);
}

// rotate about y axis
float3x3 rotY( float angle) {
  float cy = cos(angle), sy = sin(angle);
  return float3x3(cy, 0, -sy,    0, 1., 0,       sy, 0, cy);
}

// rotate about z axis
float3x3 rotZ(float angle) {
  float cz = cos(angle), sz = sin(angle);
  return float3x3(cz, -sz, 0.,   sz, cz,0.,      0.,0.,1.);
}





float2x2 makeMat(float4 x) {
  return float2x2(x.x, x.y, x.z, x.w);
}

// ============================================================
// random numbers
// ============================================================
float4 rand4(float2 x) {
  float G = global::e;
  float2 r = (G * sin(G * x));
  return abs(float4( fract(r.x * r.y * (global::PHI + x.x)),
                    fract(sin(r.x * r.y * (global::PI+x.y))),
                    fract( dot(r,r) * cos( dot(x, global::e))),
                    fract( pow(r.y,r.x+1) * atan2( r.x, r.y))
                    ));
}

float3 rand3(float2 winCoord, float tim) {
  float3 v = float3(winCoord, tim);
  v = fract(v) + fract(v*10000) + fract(v*0.0001);
  v += float3(0.12345, 0.6789, 0.314159);
  v = fract(v*dot(v, v)*123.456);
  v = fract(v*dot(v, v)*123.456);
  return v;
}

float2 rand2(float2 x) {
  float3 y = fract(cos(x.xyx) * float3(.1031, .1030, .0973));
  y += dot(y, y.yzx+19.19);
  return abs(fract((y.x+y.yz)*y.zy));
}

// ======================================================

float4 prand4(float2 x, float2 iResolution) {
  float2 x1 = floor(x * 512) / iResolution;
  float2 x2 = ceil(x * 512) / iResolution;
  float4 a1 = rand(x1);
  float4 a2 = rand(x2);
  float z = ((x * 512)/iResolution - x1).x;
  float zz = z / (x2.x - x1.x + (x2.x == x1.x));
  float4 T = mix( a1, a2, zz);
  return T;
}


// simulates getting random pixels from a noise texture.
// the algorithm interpolates between the random values at quantized distances from the requested position
// the second argument is the "granularity" of the virtual noise texture
float3 interporand(float2 pos, float reso) {
  float2 a = floor(pos * reso);
  float2 b = fract(pos * reso);
  
  float3 p1 = rand3(a/reso);
  float3 p2 = rand3((a + float2(0, 1)) / reso);
  float3 p3 = rand3((a + 1) / reso);
  float3 p4 = rand3((a + float2(1, 0)) / reso);

  float3 t1 = mix(p1, p4, b.x);
  float3 t2 = mix(p2, p3, b.x);
  float3 t3 = mix(t1, t2, b.y);
  return t3;
}


// ==========================================================

// smoothed minimum
// http://iquilezles.org/www/articles/smin/smin.htm
float polySmin( float a, float b, float k ) {
  float h = saturate( 0.5+0.5*(b-a)/k );
  return mix( b, a, h ) - k*h*(1.0-h);
}

float polySmax( float a, float b, float k ) {
  float h = saturate( 0.5 + 0.5*(b-a)/k );
  return mix( a, b, h ) + k*h*(1.0-h);
}

// exponential smoothed minimum -- k should be negative (like -4)
float expSmin( float a, float b, float k ) {
  float res = exp( -k*a ) + exp( -k*b );
  return -log( res )/k;
}
float expSmax(float a, float b, float k) {
  return log(exp(k*a)+exp(k*b))/k;
}

// commutative smoothed minimum
float commSmin(float a, float b, float k) {
  float f = max(0., 1. - abs(b - a)/k);
  return min(a, b) - k*.25*f*f;
}
float commSmax( float a,  float b, float k) {
  float f = max(0., 1. - abs(b - a)/k);
  return max(a, b) + k*.25*f*f;
}

// =================================================

float2 PixToHex (float2 p) {
  float3 c;
  c.xz = float2 ((1./sqrt(3.)) * p.x - (1./3.) * p.y, (2./3.) * p.y);
  c.y = - c.x - c.z;
  float3 r = floor (c + 0.5);
  float3 dr = abs (r - c);
  r -= step (dr.yzx, dr) * step (dr.zxy, dr) * dot (r, float3 (1.));
  return r.xz;
}

float2 HexToPix (float2 h) {
  return float2 (sqrt(3.) * (h.x + 0.5 * h.y), (3./2.) * h.y);
}

float3 HexGrid (float2 p) {
  p -= HexToPix (PixToHex (p));
  float2 q = abs (p);
  return float3 (p, 0.5 * sqrt(3.) - q.x + 0.5 * min (q.x - sqrt(3.) * q.y, 0.));
}

float HexEdgeDist (float2 p) {
  p = abs (p);
  return (sqrt(3.)/2.) - p.x + 0.5 * min (p.x - sqrt(3.) * p.y, 0.);
}

// ===================================================================

// return color from temperature
//http://www.physics.sfasu.edu/astro/color/blackbody.html
//http://www.vendian.org/mncharity/dir3/blackbody/
//http://www.vendian.org/mncharity/dir3/blackbody/UnstableURLs/bbr_color.html
half3 blackbody(float Temp) {
  half3 col = 255;
  col.x = 56100000. * pow(Temp,(-3. / 2.)) + 148.;
  col.y = 100.04 * log(Temp) - 623.6;
  if (Temp > 6500.) col.y = 35200000. * pow(Temp,(-3. / 2.)) + 184.;
  col.z = 194.18 * log(Temp) - 1448.6;
  col = clamp(col, 0., 255.)/255.;
  if (Temp < 1000.) col *= Temp/1000.;
  return col;
}

half3 BlackBody( float t ) {
    float h = 6.6e-34; // Planck constant
    float k = 1.4e-23; // Boltzmann constant
    float c = 3e8;// Speed of light

    half3 w = half3( 610.0, 549.0, 468.0 ) / 1e9; // sRGB approximate wavelength of primaries
    
    // This would be more accurate if we integrate over a range of wavelengths
    // rather than a single wavelength for r, g, b
    
    // Planck's law https://en.wikipedia.org/wiki/Planck%27s_law
    
    half3 w5 = w*w*w*w*w;
    half3 o = 2.*h*(c*c) / (w5 * (exp(h*c/(w*k*t)) - 1.0));

    return o;
}

// ========================================================================


// ==============================================================

float rand( float n ) {
  return fract(sin(n)*43758.5453123);
}

// sometimes known as Hashfv2
// float2(127.1,311.7)
// float2(12.9898,78.233)
float rand( float2 n) {
  return fract (sin (dot (n, float2(12.9898,78.233))) * 43758.5453123);
}

// float3(283.6,127.1,311.7)
float rand( float3 n) {
  return fract(sin(dot(n ,float3(12.9898,78.233,12.7378))) * 43758.5453);
}

float noisePerlin(float p) {
  float i = floor (p);
  float f = fract (p);
  f = f * f * (3 - 2 * f);
  float2 t = fract(sin(i + float2(0, 1) * 43758.54));
  return mix (t.x, t.y, f);
}

float noisePerlin(float2 x) {
  float2 p = floor(x);
  float2 f = fract(x);
  f = f*f*(3-2*f);  // or smoothstep     // to make derivative continuous at borders
  return mix(mix(rand(p+float2(0,0)),
                 rand(p+float2(1,0)), f.x),       // triilinear interp
             mix(rand(p+float2(0,1)),
                 rand(p+float2(1,1)), f.x), f.y);
}

float noisePerlin(float3 x) {
  float3 p = floor(x);
  float3 f = fract(x);
  f = f*f*(3-2*f);  // or smoothstep     // to make derivative continuous at borders
  return mix(mix(mix(rand(p+float3(0,0,0)),
                     rand(p+float3(1,0,0)), f.x),       // triilinear interp
                 mix(rand(p+float3(0,1,0)),
                     rand(p+float3(1,1,0)), f.x), f.y),
             mix(mix(rand(p+float3(0,0,1)),
                     rand(p+float3(1,0,1)), f.x),
                 mix(rand(p+float3(0,1,1)),
                     rand(p+float3(1,1,1)), f.x), f.y), f.z);
}

// also known as Hashv4f
float4 hash4( float n) {
  return fract (sin (n + float4 (0, 1, 57, 58)) * 43758.5453123);
}

// -------------------------------------------------------------------
// Colors

Color palette( float t, Color a, Color b, Color c, Color d ) {
  return a + b*cos( tau*(c*t+d) );
}

float vignette( float2 uv, float p) {
  return pow(uv.x * uv.y * (1-uv.x) * (1-uv.y), p);
}

float2 yflip(float2 x) {
  return float2(0, 1) + x * float2(1, -1);
}

float prod(float2 x) { return x.x * x.y; }
half prod(half2 x) { return x.x * x.y; }
float prod(float3 x) { return x.x * x.y * x.z; }
half prod(half3 x) { return x.x * x.y * x.z; }
float prod(float4 x) { return x.x * x.y * x.z * x.w; }
half prod(half4 x) { return x.x * x.y * x.z * x.w; }

float4x4 inverse(float4x4 mm) {
  float4x4 om = float4x4(1);
  int rows = 4;
  for(int i = 0; i < rows; i++) {
    // for(int j = i; j < rows; j++) {
    // if abs(mm[j][j]) < epsilon {
    //  float3 v = mm[i];
    //
    // }
    float n = 1. / mm[i][i];
    om[i] *= n;
    mm[i] *= n;
    for(int j=i+1;j<rows;++j) {
      float t = mm[j][i];
      mm[j] -= mm[i] * t;
      om[j] -= om[i] * t;
      mm[j][i]=0; //not necessary, but looks nicer than 10^-15
    }
  }
  // solving a triangular matrix
  for(int i=rows-1;i>0;--i) {
    for(int j=i-1;j>=0;--j) {
      float t = mm[j][i];
      om[j] -= om[i] * t;
      mm[j] -= mm[i] * t;
    }
  }
  return om;
}

float3x3 inverse(float3x3 mm) {
  float3x3 om = float3x3(1);
  int rows = 3;
  for(int i = 0; i < rows; i++) {
    // for(int j = i; j < rows; j++) {
    // if abs(mm[j][j]) < epsilon {
    //  float3 v = mm[i];
    //
    // }
    float n = 1. / mm[i][i];
    om[i] *= n;
    mm[i] *= n;
    for(int j=i+1;j<rows;++j) {
      float t = mm[j][i];
      mm[j] -= mm[i] * t;
      om[j] -= om[i] * t;
      mm[j][i]=0; //not necessary, but looks nicer than 10^-15
    }
  }
  // solving a triangular matrix
  for(int i=rows-1;i>0;--i) {
    for(int j=i-1;j>=0;--j) {
      float t = mm[j][i];
      om[j] -= om[i] * t;
      mm[j] -= mm[i] * t;
    }
  }
  return om;
}

float2x2 inverse(float2x2 mm) {
  float d = determinant(mm);
  return float2x2(mm[1][1]/d, -mm[0][1]/d, -mm[1][0]/d, mm[0][0]/d);
}




kernel void copyTextureKernel(
    texture2d<float, access::read> inputTexture [[texture(0)]],
    texture2d<half, access::write> outputTexture [[texture(1)]],
    uint2 gid [[thread_position_in_grid]]
) {
    if (gid.x >= outputTexture.get_width() || gid.y >= outputTexture.get_height())
        return;
        
  float4 color = inputTexture.read(gid);
    outputTexture.write(half4(color), gid);
}


  // fractal Brownian motion
float fbm::emit(const float2 x) {
    float r = 0.0;

    //  const float octaves = 5;
    //  const float lacunarity = 2;
    //  const float gain = 0.5;
    float f = frequency;
    float a = amplitude;
    float2 j = f * x;

    for (int i=0; i<octaves; i++) {
      a *= gain;
      r += a * noisePerlin(j);
      j = rot2d(rotation) * j * lacunarity + shift;
    }
    return r;
};


vertex VertexOut flatVertexFn( uint vid [[ vertex_id ]] ) {
  VertexOut v;
  float bx = step( float(vid), 1);
  float by = fmod(float(vid), 2);

  v.where.xy = 2 * float2(bx, by) - 1;
  v.where.y = - v.where.y;

  v.where.zw = {0, 1};

  v.texCoords = 0.5 + v.where.xy * float2(0.5, -0.5) ;
  v.color = 0; // then it works like it used to....
  return v;
}

