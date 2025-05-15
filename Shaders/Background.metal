// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2025

#include <metal_stdlib>
#include "support.h"

using namespace metal;

// =================================================================


colorEffect(toSepia) {
  const half4x4 rgba2sepia = half4x4(
                                     0.393, 0.349, 0.272, 0,
                                     0.769, 0.686, 0.534, 0,
                                     0.189, 0.168, 0.131, 0,
                                     0,     0,     0,     1
                                     );
  const half timeFactor = ( 1.0 + sin(time)) / 2;
  const half4x4 rgba2sepiaDiff = half4x4( 1 ) + timeFactor * ( rgba2sepia - half4x4( 1 ) );
  return rgba2sepiaDiff * currentColor;
}

// ==================================================================

colorEffect(nightVision) {
  const float lumx = cos(position.y);
  const float lum = lumx * lumx / 3 + 0.6;
  const float col = dot(currentColor.rgb, half3(0.65,0.3,0.1)*lum);
  return opaque(0, col, 0) * smoothstep(0.9, 0, distance(position / size, 0.5));
}

// =================================================================

colorEffect(nightVision02) {
  const float2 u = worldCoord(position, size);
  const float2 n = u * nodeAspect(size);
  const float t = time;

  half3 c = currentColor.rgb;
  c += sin(rand(t)) * 0.01;
  c += rand((rand(n.x) + n.y) * t) * 0.5;
  c *= smoothstep(length(n * n * n * float2(0.075, 0.4)), 1.0, 0.4);
  c *= smoothstep(0.001, 3.5, t) * 1.5;
  c = luminance(c) * half3(0.2, 1.5 - rand(t) * 0.1,0.4);
  
  return opaque(c);
}


// =================================================================

colorEffect(monochromeFade) {
  return opaque( mix(currentColor.rgb, dot(currentColor.rgb, 1) / 3, (1 + sin(time) / 2 ) ) );
}

// =================================================================

colorEffect(colorCycle) {
  const float z = 1 / sqrt(3.0);
  const half3 cc = currentColor.xyz;
  const half3 cr = cross(z, cc) * sin(time);
  const half3 md = z * dot(z, cc);
  return opaque(mix(md, cc, cos(time) ) + cr );
}

// =================================================================

colorEffect(derivatives) {
  struct Args {
    char variant;
  };
  
  auto args = reinterpret_cast<device const Args *>(arg);
  
  half3  col = currentColor.rgb;
  const float lum = dot(col, 0.333);
  
  switch (args->variant) {
/*    case 0: {
      float3  nor = normalize( float3( dfdx(lum), 64.0 / size.x, dfdy(lum) ) );
      const float lig = clamp( 0.5 + 1.5*dot(nor,float3(0.7,0.2,-0.7)), 0.0, 1.0 );
      col *= lig;
    }
      break;
 */
    case 1: {
      float3  nor = normalize( float3( dfdx(lum), 64.0 / size.x, dfdy(lum) ) );
      const float lig = 0.5 + dot(nor,float3(0.7,0.2,-0.7));
      col = lig;
    }
      break;
    case 0: {
      const float f = fwidth( lum );
      col *= 1.5 * half3( saturate(1.0-8.0*f) );
    }
      break;
  }

  
//  col *= smoothstep( 0.003, 0.004, abs(b.x-0.5) );
//  col *= 1.0 - (1.0-smoothstep( 0.007, 0.008, abs(b.x-0.5) ))*(1.0-smoothstep(0.49,0.5,b.x));
//  col = mix( col, ocol, pow( 0.5 + 0.5*sin(time), 4.0 ) );
  
  return opaque( col);
}

// =================================================================

colorEffect(vignette01) {
  const float EDGE = 0.2;
  const float2 uv = position / size;
  const float edge = EDGE * abs(sin(time / 5));
  const float2 suv = smoothstep(0, edge, uv) * (1 - smoothstep(1 - edge, 1, uv));
  const half3 fragColor = currentColor.rgb * suv.x * suv.y;
  return opaque(fragColor);
}

// =================================================================

colorEffect(imageCel) {
  const float nColors = 4.0;
  const float vx_offset = 0.5;
  const float2 uv = position / size;
  
  half3 tc = currentColor.rgb;
  
  const float cutColor = 1/nColors;
  
  if (uv.x < (vx_offset-0.001)) {
    tc = rgb2hsv(tc);
    
    const half2 target_c = cutColor * floor(tc.gb/cutColor);
    tc = hsv2rgb(half3(tc.r,target_c));
  }
  else if (uv.x>=(vx_offset+0.01)) {
    tc  = cutColor * floor(tc / cutColor);
  }
  return opaque(tc);
}

// =================================================================

colorEffect(bevelled) {
  const float imh = 0.8 ;
  const float imw = imh;
  const float imx = float( 1 - imw ) / 2.0 ;
  const float imy = float( 1 - imh ) / 2.0 ;
  const float2 uv = position / size;

  if ( uv.x > imx &&
      uv.x < imx+imw &&
      uv.y > imy &&
      uv.y < imy+imh )
  {
    const half4 rgba = currentColor;
    const float x = ( uv.x - imx ) / imw;
    const float y = ( uv.y - imy ) / imh;
    const float e0 = x;
    const float e1 = 1.0-x;
    const float e2 = y;
    const float e3 = 1.0-y;
    
    float scl = 1.0;
    if ( e0 <= e1 && e0 <= e2 && e0 <= e3 && e0 < 0.1 )
      scl = 1.2; // left edge
    if ( e1 <= e0 && e1 <= e2 && e1 <= e3 && e1 < 0.1 )
      scl = 0.5; // right edge
    if ( e2 <= e1 && e2 <= e0 && e2 <= e3 && e2 < 0.1 )
      scl = 1.5; // bottom edge
    if ( e3 <= e1 && e3 <= e2 && e3 <= e0 && e3 < 0.1 )
      scl = 0.7; // top edge
    return rgba * scl;
  }
  else
  {
    return half4(0,0,0.5,1);
  }
}


// =================================================================

colorEffect(money) {
  const float2 xy = position / size;
  const float amplitud = 0.03;
  const float frecuencia = 10.0;
  const float divisor = 4.8 / size.y;
  const float grosorInicial = divisor * 0.2;
  const int kNumPatrones = 6;

  float gris = 1.0;

  const float3 datosPatron[kNumPatrones] = {
    float3(-0.7071, 0.7071, 3.0), // -45
    float3(0.0, 1.0, 0.6), // 0
    float3(0.0, 1.0, 0.5), // 0
    float3(1.0, 0.0, 0.4), // 90
    float3(1.0, 0.0, 0.3), // 90
    float3(0.0, 1.0, 0.2), // 0
  };
  
  for(int i = 0; i < kNumPatrones; i++) {
    const float coseno = datosPatron[i].x;
    const float seno = datosPatron[i].y;
    
    const float2 punto = float2(
                          xy.x * coseno - xy.y * seno,
                          xy.x * seno + xy.y * coseno
                          );
    
    const float grosor = grosorInicial * float(i + 1);
    const float dist = mod(punto.y + grosor * 0.5 - sin(punto.x * frecuencia) * amplitud, divisor);
    const float brillo = dot(currentColor.rgb, half3(0.3, 0.4, 0.3));
    
    if (dist < grosor && brillo < 0.75 - 0.12 * float(i)) {
      const float k = datosPatron[i].z;
      const float x = (grosor - dist) / grosor;
      const float fx = abs((x - 0.5) / k) - (0.5 - k) / k;
      gris = min(fx, gris);
    }
  }

  return opaque(gris);
}


// =================================================================

colorEffect(wall03) {
  const float BOXES = 10;
  const float MIN_BRIGHTNESS = 0.5;
  const float2 uv = position / size;
  const float2 px = uv * BOXES;
  const float shade = saturate(MIN_BRIGHTNESS + rand(floor(px + 0.5)) );
  const float2 ga = smoothstep(0.4, 0.49, abs(floor(px + 0.5) - px));
  const float gx = dot(ga, 1);
  const float g = 1 - saturate(gx);
  return opaque(g * shade * currentColor);
}


// =================================================================



colorEffect(dotty) {
  return step(length(fract(position * 0.1) * 2 - 1), currentColor);
}

// =================================================================

colorEffect(emboss) {
  half4 fragColor = currentColor;
  fragColor += 0.5 + 15 * dfdy(length(fragColor)) - fragColor;
  fragColor *= half4(1, 0.8, 0.2, 1);
  return fragColor;
}

// =================================================================

colorEffect(emboss02) {
  return 0.5 + 15 * dfdy( dot(currentColor.xyz, sin(time + half3(0, 2.1, -2.1))) );
}

// =================================================================

colorEffect(spotlight01) {
  const float d = 1.0-length(( position / size * 2 - 1) - cos(time) * 0.4) * 2.0;
  return opaque( d * currentColor.rgb);
}

// =================================================================

colorEffect(grate) {
  const float2 uv = position / size * nodeAspect(size);
  const float tile = size.x / 10;
  const float2 oo = sin(uv*tile + float2(0, time*10.0)) * 0.5 + 0.5;
  const float doo = smoothstep(0.2, 0.8, 1 - dot(oo, 1.0));
  return currentColor * doo;
}


// =================================================================

colorEffect(shutter) {
  float2 U = worldCoordAdjusted(position, size);
  
  half4 fragColor = currentColor;
  
  const float N = 12;
//  const float c = cos(TAU/N);
//  const float s = sin(TAU/N);
  const float a = PI/4.*(.5+.5*sin(time));

  for (int i=0; i<20; i++) {
    const float d = -dot(U-float2(-1,1),float2(sin(a),cos(a)));
    const float A = smoothstep(.01,0.,d);
    fragColor.rgb += (1-fragColor.w) * A * half3(1-4*smoothstep(0.01, 0, abs(d)));
    fragColor.w = A;
    U = U * rot2d(TAU/N);
  }
  fragColor *= smoothstep(1, 0.99, length(U));
  return opaque(fragColor);
}

// =================================================================

