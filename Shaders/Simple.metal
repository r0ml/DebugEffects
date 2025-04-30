// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2025

#include <metal_stdlib>
#include "support.h"

using namespace metal;

// =================================================================

colorEffect(oily1) {
  class fbm fbm;
  fbm.rotation = 0.4; fbm.frequency = 5; fbm.octaves = 7;
  
  const float2 uv = position / size;
  const float t = 0.05 * time;
  const float2 k = float2(3, 1);
  const float2 q = float2(fbm.emit( fma(0.4, t, uv) ), fbm.emit( uv + t + k ) );
  const float f = fbm.emit( fma(3, q, uv) );
  const Color c1 = Color(0.4, 0.6, 0.6);
  const Color c = c1 * (0.5 + f * half3(q.xyx));
  return opaque( c );
}

// ==================================================================

colorEffect(oily2) {
  class fbm fbm;
  fbm.frequency = 16; fbm.octaves = 3;
  
  const float2 uv = position / size;
  const float2 uva = uv + float2(0, time * 0.033);
  const float q = fbm.emit(uva);
  const float c = fbm.emit(uva + fma(time, float2(0.033, 0.066), q) );
  const half3 col = hsv2rgb(half3(q,q * c,c));
  return opaque(col);
}

// =================================================================

colorEffect(fire) {
  class fbm fbm; fbm.lacunarity = 1.7; fbm.gain = 0.47;

  const float2 speed = float2(0.1, 0.9);
  const float dist = 3.5-sin(time*0.4)/1.89;
  
  const float2 uv = yflip(position / size);
  
  const float2 p3 = uv * nodeAspect(size) * dist;
  const float2 p2 = p3 + sin( p3.yx * 4 + float2(0.2, -0.3) * time) * 0.04;
  const float2 p1 = p2 + sin( p2.yx * 8 + float2(0.6, 0.1) * time) * 0.01;
  
  const float2 p = float2(p1.x - time/1.1, p1.y);
  
  const float qx = fbm.emit(p - time * 0.3+1.0*sin(time+0.5)/2.0);
  const float qb = fbm.emit(p - time * 0.4+0.1*cos(time)/2.0);
  const float q2 = fbm.emit(p - time * 0.44 - 5.0*cos(time)/2.0) - 6.0;
  const float q3 = fbm.emit(p - time* 0.9 - 10.0*cos(time)/15.0)-4.0;
  const float q4 = fbm.emit(p - time * 1.4 - 20.0*sin(time)/14.0)+2.0;
  const float q = (qx + qb - .4 * q2 -2.0*q3  + .6*q4)/3.8;
  const float2 r = float2(fbm.emit(p + q /2.0 + time * speed.x - p.x - p.y),
                          fbm.emit(p + q - time * speed.y));

  const Color color = Color(1, 0.2, 0.05)/(pow((r.y+r.y)* max(.0,p.y)+0.1, 4));;
  const Color res = color/(1.0+max(0,color));
  return opaque(res);
}

// =================================================================

colorEffect(flame2) {
  const float2 uv = position / size;
  const float2 xy = uv * 8 - 4;
  const float z = pow(abs(xy.x), 2.4) * 100 + 0.1 * sin(time*30000);
  const float j = smoothstep(1, 0, fma(0.23, length( 2 - xy.y + float2(0, z)), 0.3) );
  const half3 col = pow( half3(1.9, 1.4, 1) * j, half3(1, 1.1, 0.8 ));
  return opaque(gammaDecode(col));
}

//=====================================================================================================

colorEffect(scissor) {
  const float2 uv = worldCoord(position , size);
  const float speed = 10;
  const float2 st = rot2d(time / speed) * uv;
  const float2 o = float2(cos(time / speed), sin(time / (speed / 3) ));
  const float tx = time/50;
  const float s1 = sin(-tx + fma(64, o.x, 16) - o.y * length(o+st) + 16 * atan2(o.y+st.y, o.x + st.x));
  const float s2 = sin( tx + fma(64, o.x, 16) - o.y * length(o-st) - 16 * atan2(o.y-st.y, o.x - st.x));
  const float tl = length(st) * 5;
  const float ss = time + 0.3 * s1 * s2;
  Color col = hsv2rgb( fma(0.4, Color(sin(5 * ss - tl + sin(ss) * 0.5), 0.4, 0.6), 0.4));
  return opaque(col);
}

// =================================================================

colorEffect(wisps) {
  const float2 st = position / size * 3;
  class fbm fbm;
  fbm.octaves = 7;
  fbm.shift = 100;
  fbm.rotation = 0.5;
  
  const float2 q = float2(fbm.emit( st ), fbm.emit( st + 1) );
  
  const float2 r = float2(fbm.emit( st + 1.0*q + float2(1.7,9.2)+ 0.15*time ),
                          fbm.emit( st + 1.0*q + float2(8.3,2.8)+ 0.126*time) );
  
  const float f = fbm.emit(st+r);
  
  Color color = mix(Color(0.101961,0.619608,0.666667),
                    Color(0.666667,0.666667,0.498039),
                    saturate((f*f)*4.0));
  
  color = mix(color, half3(0,0,0.164706), saturate(length(q)));
  color = mix(color, half3(0.666667,1,1), saturate(abs(r.x)));
  
  return opaque((f*f*f+0.6*f*f+0.5*f)*color);
}


// =================================================================

