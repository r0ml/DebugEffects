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
  const float2 p = position / size;
  const float py = p.y + 0.01 * fmod(time, 15) * fract(sin(dot(float2(p.x), float2(12.9, 78.2))) * 437.5);
  return float2(p.x, py) * size;
}

// =================================================================


static float getAddendForRipples(float time, float2 uv, float2 aspect, float2 tapPoint) {
 const float waveStrength = 0.02;
 const float frequency = 30.0;
 const float waveSpeed = 5.0;
 const float centerLight = 2;

 const half modifiedTime = time / waveSpeed;
 const float2 distVec = (uv - tapPoint) * aspect;
 const float distance = length(distVec);
 const float multiplier = (distance < 1.0) ? ((distance-1.0)*(distance-1.0)) : 0.0;

 const float addend = (sin(frequency*distance-modifiedTime)+centerLight) * waveStrength * multiplier;
 return addend;
}

distortionEffect(water_wave_ripples_distort) {
 const float oblique = 0.25;
 const float2 uv = position / size;
 const float addend = getAddendForRipples(time, uv, nodeAspect(size), mouse);
 const float2 newTexCoord = position/size + addend*oblique;
 return mod(size * newTexCoord, size);
}

// =================================================================


// Do this with vertex shader?

 static float plane(const float3 norm, const float3 po, const float3 ro, const float3 rd ) {
   const float dex = dot(norm, rd);
   const float de = sign(dex)*max( abs(dex), 0.001);
   return dot(norm, po-ro)/de;
 }

 static float2 raytraceTexturedQuad(const float3 rayOrigin,
                                    const float3 rayDirection,
                                    const float3 quadCenter,
                                    const float3 quadRotation,
                                    const float2 quadDimensions) {
   //Rotations ------------------
   const float a = sin(quadRotation.x);
   const float b = cos(quadRotation.x);
   const float c = sin(quadRotation.y);
   const float d = cos(quadRotation.y);
   const float e = sin(quadRotation.z);
   const float f = cos(quadRotation.z);
   const float ac = a*c;
   const float bc = b*c;

   const float3x3 RotationMatrix  =
   float3x3(    d*f,      d*e,  -c,
            ac*f-b*e, ac*e+b*f, a*d,
            bc*f+a*e, bc*e-a*f, b*d );
   //--------------------------------------

   const float3 right = RotationMatrix * float3(quadDimensions.x, 0.0, 0.0);
   const float3 up = RotationMatrix * float3(0, quadDimensions.y, 0);
   const float3 normal = normalize(cross(right, up));

   const float3 pos = (rayDirection * plane(normal, quadCenter, rayOrigin, rayDirection)) - quadCenter;

  return float2(dot(pos, right) / dot(right, right),
                 dot(pos, up)    / dot(up,    up)) + 0.5;
 }

distortionEffect(verbose_raytrace_quad) {
  const float2 p = worldCoordAdjusted(position, size);
  const float3 dir = normalize(float3(p.x, p.y, 1.0));
  const float3 planePosition = float3(0.0, 0.0, 0.5);
  const float3 planeRotation = float3(0.4*cos(0.3*time), 0.4*sin(0.6*time), 0.0);
  const float2 planeDimension = nodeAspect(size) * float2(-1, 1);
  
  const float2 uv = raytraceTexturedQuad(float3(0), dir, planePosition, planeRotation, planeDimension);
  
  if(abs(uv.x - 0.5) < 0.5 && abs(uv.y - 0.5) < 0.5) {
    return mod(size * float2(uv.x, 1-uv.y), size);
  }
  return float2(-1);
}


 // =================================================================

distortionEffect(tunnel_effect) {
  const float TUNNEL_SIZE  = 0.25;
  const float TUNNEL_SPEED = 0.5;
  const float2 p  = toWorld(position / size);
  const float a = atan2(p.y, p.x);
  const float r = sqrt(dot(p, p));
  const float2 uv = float2(a / PI, time * TUNNEL_SPEED + (TUNNEL_SIZE / r));
  return mod(size * uv, size);
}

// ================================================================

distortionEffect(vortex92) {
  const float WAVE_SIZE = 3.0;
  const float SPEED = 3.0;
  const float2 uv = position / size;
  const float2 diff = toWorld(uv) - toWorld(mouse);
  const float dist  = length(diff);
  const float angle = M_PI_F * dist * WAVE_SIZE + time * SPEED;
  const float2 newUV = diff * rot2d(angle);
  return fract(newUV) * size;
}
 
 // =================================================================

distortionEffect(spiral92) {
  const float2 uv = position / size;
  const float2 vecA = toWorld(uv);
  const float len = length(vecA);
  const float2 vecB = float2(len, 0);
  const float initial = dot(vecA, vecB) / len;
  const float degree = acos(initial) * 180 / PI;
  const float thetamod = degree / 18 * sin(len * 50);
  const float intensity = 4;
  const float timex = mod(time, intensity);
  const float ti = timex < intensity / 2.0 ? timex : intensity - timex;
  const float theta = time * 0.5 + thetamod * ti / 100;
  const float2 newPoint = fract(uv * rot2d(theta) );
  return size * newPoint;
}

 // =================================================================

distortionEffect(tunnel94) {
   const float2 oxy = worldCoordAdjusted(position, size) - 0.7;
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

  const float t = time/5.;
  const float n = 10 * (0.5 - 0.5 * cos(TAU * t));
  
  for( float i=0; i < mod(t,4); i++) {
    U = polarRep(U, n);
  }
  
  return mod(size * (0.5+U), size);
}



// =================================================================

distortionEffect(easy_sphere_distortion) {
  const float2 uv = worldCoordAdjusted(position, size);
  const float dist = sqrt(abs(1.0-dot(uv,uv)));
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
  const float2 aspect = nodeAspect(size);
  
  const float2 uv3 = position / size;
  const float t = time * 0.05;
  
  const float2 p = uv3 * aspect;
  
  const float r2 = distance(p, mouse * aspect ) - t;
  const float r = fract(r2 * ring)/div;
  
  const float2 uv2 = r * toWorld(uv3);
  const float2 uv = uv2 * 0.5 + 0.5;

  return mod(uv * size, size);
}


// =================================================================

