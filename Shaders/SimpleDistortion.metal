// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2025

#include <metal_stdlib>
#import "support.h"

using namespace metal;

// =================================================================

distortionEffect(tunnel01) {
  const float2 p = 0.75 * worldCoordAdjusted(position, size);
  const float a2 = atan2( p.y, p.x );
  const float r = sqrt( dot(p,p) );
  
  const float a = a2 + sin(0.5*r-0.5* time );
  
  const float h = 0.5 + 0.5*cos(9.0*a);
  
  const float s = smoothstep(0.4,0.5,h);
  
  const float2 uv = float2( time + 1.0/(r + .1*s), 3.0*a/PI);
  return fract(uv) * size;
}
  
// =================================================================


distortionEffect(melting) {
  float2 p = position / size;
  p.y += 0.01 * fmod(time, 15) * fract(sin(dot(float2(p.x), float2(12.9, 78.2))) * 437.5);
  return p * size;
}



// =================================================================


static float getAddendForRipples(float time, float2 uv, float2 aspect, float2 tapPoint) {
 float waveStrength = 0.02;
 float frequency = 30.0;
 float waveSpeed = 5.0;
 float centerLight = 2;

 half modifiedTime = time / waveSpeed;
 float2 distVec = (uv - tapPoint) * aspect;
 float distance = length(distVec);
 float multiplier = (distance < 1.0) ? ((distance-1.0)*(distance-1.0)) : 0.0;

 float addend = (sin(frequency*distance-modifiedTime)+centerLight) * waveStrength * multiplier;
 return addend;
}

distortionEffect(water_wave_ripples_distort) {
 float oblique = .25;
 
 float2 uv = position / size;
 float addend = getAddendForRipples(time, uv, nodeAspect(size), mouse);
 float2 newTexCoord = position/size + addend*oblique;
 return mod(size * newTexCoord, size);
}

// =================================================================


// Do this with vertex shader?

 static float plane( float3 norm, float3 po, float3 ro, float3 rd ) {
   float de = dot(norm, rd);
   de = sign(de)*max( abs(de), 0.001);
   return dot(norm, po-ro)/de;
 }

 static float2 raytraceTexturedQuad( float3 rayOrigin, float3 rayDirection, float3 quadCenter, float3 quadRotation, float2 quadDimensions) {
   //Rotations ------------------
   float a = sin(quadRotation.x); float b = cos(quadRotation.x);
   float c = sin(quadRotation.y); float d = cos(quadRotation.y);
   float e = sin(quadRotation.z); float f = cos(quadRotation.z);
   float ac = a*c;   float bc = b*c;

   float3x3 RotationMatrix  =
   float3x3(    d*f,      d*e,  -c,
            ac*f-b*e, ac*e+b*f, a*d,
            bc*f+a*e, bc*e-a*f, b*d );
   //--------------------------------------

   float3 right = RotationMatrix * float3(quadDimensions.x, 0.0, 0.0);
   float3 up = RotationMatrix * float3(0, quadDimensions.y, 0);
   float3 normal = cross(right, up);
   normal /= length(normal);

   //Find the plane hit point in space
   float3 pos = (rayDirection * plane(normal, quadCenter, rayOrigin, rayDirection)) - quadCenter;

   //Find the texture UV by projecting the hit point along the plane dirs
   return float2(dot(pos, right) / dot(right, right),
                 dot(pos, up)    / dot(up,    up)) + 0.5;
 }

distortionEffect(verbose_raytrace_quad) {
   //Screen UV goes from 0 - 1 along each axis
 //  float2 screenUV = textureCoord;
   float2 p = worldCoordAdjusted(position, size);

   //Normalized Ray Dir
   float3 dir = float3(p.x, p.y, 1.0);
   dir /= length(dir);

   //Define the plane
   float3 planePosition = float3(0.0, 0.0, 0.5);
   float3 planeRotation = float3(0.4*cos(0.3*time), 0.4*sin(0.6*time), 0.0);
   float2 planeDimension = nodeAspect(size) * float2(-1, 1);

   float2 uv = raytraceTexturedQuad(float3(0), dir, planePosition, planeRotation, planeDimension);

   //If we hit the rectangle, sample the texture
   if(abs(uv.x - 0.5) < 0.5 && abs(uv.y - 0.5) < 0.5) {
     return mod(size * float2(uv.x, 1-uv.y), size);
   }
  // this should have been return 0 -- meaning black -- but this is now a distort fn, not a color fn
  return float2(-1);
 }


 // =================================================================



static float2 tunnelxx(float2 uv, float size, float time)
{
    float2 p  = -1.0 + (2.0 * uv);
    float a = atan2(p.y, p.x);
    float r = sqrt(dot(p, p));
    return float2(a / PI, time + (size / r));
}

distortionEffect(tunnel_effect) {
 const float TUNNEL_SIZE  = 0.25;  // smaller values for smaller/thinner tunnel
 const float TUNNEL_SPEED = 0.5;    // speed of tunnel effect, negative values ok
  float2 uv = tunnelxx(position / size, TUNNEL_SIZE, time * TUNNEL_SPEED);
 return mod(size * uv, size);
}

// ================================================================

distortionEffect(vortex92) {
   // float2 rcpResolution = scn_frame.inverseResolution.xy;
   const float WAVE_SIZE = 3.0;
   const float SPEED = 3.0;

  float2 uv = position / size;

   // = float2 ndc    = -1.0 + uv * 2.0;
   // = float2 mouse  = -1.0 + 2.0 * uni.iMouse.xy * rcpResolution;
   float4 mouseNDC = -1.0 + float4(mouse.xy, uv) * 2.0;
   float2 diff     = mouseNDC.zw - mouseNDC.xy;
   
   float dist  = length(diff);       // = sqrt(diff.x * diff.x + diff.y * diff.y);
   float angle = M_PI_F * dist * WAVE_SIZE + time * SPEED;
    
   float3 sincos;
   sincos.x = sin(angle);
   sincos.y = cos(angle);
   sincos.z = -sincos.x;
   
   float2 newUV;
   mouseNDC.zw -= mouseNDC.xy;
   newUV.x = dot(mouseNDC.zw, sincos.yz);  // = ndc.x * cos(angle) - ndc.y * sin(angle);
   newUV.y = dot(mouseNDC.zw, sincos.xy);  // = ndc.x * sin(angle) + ndc.y * cos(angle);
   
  return fract(newUV.xy) * size;
 }


 
 // =================================================================

distortionEffect(spiral92) {
   float2 newPoint;
  float2 uv = position / size;

   float theta = time * 1.5;
   
   float centerCoordx = (uv.x * 2.0 - 1.0);
   float centerCoordy = (uv.y * 2.0 - 1.0);
   
   float len = sqrt(pow(centerCoordx, 2.0) + pow(centerCoordy, 2.0));
   
   float2 vecA = float2(centerCoordx, centerCoordy);
   float2 vecB = float2(len, 0);
   
   float initialValue = dot(vecA, vecB) / (len * 1.0);
  float degree = acos(initialValue) * 180 / PI;

   float thetamod = degree / 18.0 * sin(len * 100.0 / 2.0);
   
   float2 effectParams = mouse;
   
   // Input xy controls speed and intensity
   float intensity = effectParams.x * 20.0 + 10.0;
   float speed = time * effectParams.y * 10.0 + 4.0;
   float timex = mod(speed, intensity);

   if (timex < intensity / 2.0){
     theta += thetamod * (timex / 100.0) ;
   }
   else{
     theta += thetamod * ((intensity - timex) / 100.0) ;
   }
   
   newPoint = float2((cos(theta) * (uv.x * 2.0 - 1.0) + sin(theta) * (uv.y * 2.0 - 1.0) + 1.0)/2.0,
                     (-sin(theta) * (uv.x * 2.0 - 1.0) + cos(theta) * (uv.y * 2.0 - 1.0) + 1.0)/2.0);
   
   
  return size * newPoint;
 }

 
 
 // =================================================================

distortionEffect(tunnel94) {
   float2 oxy = worldCoordAdjusted(position, size) - 0.7;
   return size * fract(float2(time + 0.3/length(oxy), atan2(oxy.y, oxy.x)/PI)) ;
 }

 // =================================================================



static float2 tunnel(float2 p, float size, float time)
{
    float a = atan2(p.y, p.x);
    float r = sqrt(dot(p, p));
    return float2(a / PI, time + (size / r));
}

distortionEffect(tunnel95) {
  const float TUNNEL_SIZE  = 0.25;  // smaller values for smaller/thinner tunnel
   const float TUNNEL_SPEED = 0.3;    // speed of tunnel effect, negative values ok
  float2 uv = worldCoordAdjusted(position, size);
    uv = tunnel(uv, TUNNEL_SIZE, time * TUNNEL_SPEED);
  return size * fract(uv);
}

// =================================================================

static float2 polarRep(float2 U, float n) {
  n = TAU/n;
  float a = atan2(U.y, U.x),
  r = length(U);
  a = mod(a+n/2.,n) - n/2.;
  U = r * float2(cos(a), sin(a));
  return .5* ( U+U - float2(1,0) );
}

distortionEffect(kaleidoscope_polar_repeat) {
  float2 U = worldCoordAdjusted(position, size);
  float t = time/5.;
  float n = 10.* (.5-.5*cos(TAU*t));
  
  for( float i=0.; i < mod(t,4.); i++) {
    U = polarRep(U, n);
  }
  
  return mod(size * (0.5+U), size);
}



// =================================================================

distortionEffect(easy_sphere_distortion) {
  // Normalized pixel coordinates (from 0 to 1)
  float2 uv = worldCoordAdjusted(position, size);
  
  float dist = sqrt(abs(1.0-dot(uv,uv)));
  
  //float3 col = float3(dist);
  return mod(size * (time/8.0 + uv/dist), size);
}

 // =================================================================

distortionEffect(magnifier) {
  const float radius=2.;
  const float depth=radius/2.;

  const float2 uv = position / size;
  const float2 center = mouse;
  const float2 uc = uv - center;
  const float2 aspect = nodeAspect(size);
  
//  float2 ucx = uc / float2(0.2*0.2, )
  const float ax = (uc.x * uc.x) / (0.2*0.2) + ((uc.y * uc.y) / (0.2/ (  aspect.x ))) ;
  const float dx = (-depth/radius)*ax + (depth/(radius*radius))*ax*ax;
  const float f = ax + dx * (ax < radius);
  const float2 magnifierArea = center + (uv-center)*f/ax;
  return size * magnifierArea;
}


// =================================================================

distortionEffect(fresnel) {
  const float ring = 5.0;
  const float div = 0.5;
  float2 aspect = nodeAspect(size);
  
  float2 uv = position / size;
  float t = time * 0.05;
  
  float2 p = uv * aspect;
  
  float r = distance(p, mouse * aspect );
  r -= t;
  r = fract(r*ring)/div;
  
  uv = -1.0 + 2.0 * uv;
  uv *=  r;
  uv = uv * 0.5 + 0.5;

  return mod(uv * size, size);
}


// =================================================================

