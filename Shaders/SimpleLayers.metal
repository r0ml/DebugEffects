// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2025

#include <metal_stdlib>
#include "support.h"

using namespace metal;

// =================================================================

layerEffect(lights03) {
  half3 fragColor = 0;

  const float2 dd = yflip(position / size);
  const float3 d = normalize(float3(dd * nodeAspect(size), 1)- 0.5);
  const float3 p = -d /d.y;
  for(float m = 1; m <= 5; m++) {
    const float3 lab = float3(0, -0.5, 3)+sin(float3(1, 2, 0.3)*time+m)*float3(1, 0.2, 1);
    fragColor += layer.sample(fract(p.xz) * size).rgb * pow(max(1.5-length(lab-p),0.), 3) + pow(dot(lab,d)/length(lab),10000);
  }
  return opaque(fragColor);
}

// ================================================================

layerEffect(rain06) {
  const float MAX_RADIUS = 2;

  const float resolution = 10 * exp2(-3 * mouse.x);
  const float2 uv = position / size * nodeAspect(size) * resolution;
  const float2 p0 = floor(uv);
  
  float2 circles = 0;
  for (int j = -MAX_RADIUS; j <= MAX_RADIUS; ++j) {
    for (int i = -MAX_RADIUS; i <= MAX_RADIUS; ++i) {
      const float2 pi = p0 + float2(i, j);
      const float2 p = pi + rand2(pi);
      
      const float t = fract(0.3*time + rand(pi));
      const float2 v = p - uv;
      const float d = length(v) - (float(MAX_RADIUS) + 1.)*t;
      
      const float h = 1e-3;
      const float d1 = d - h;
      const float d2 = d + h;
      const float p1 = sin(31.*d1) * smoothstep(-0.6, -0.3, d1) * smoothstep(0., -0.3, d1);
      const float p2 = sin(31.*d2) * smoothstep(-0.6, -0.3, d2) * smoothstep(0., -0.3, d2);
      circles += 0.5 * normalize(v) * ((p2 - p1) / (2. * h) * (1. - t) * (1. - t));
    }
  }
  circles /= float((MAX_RADIUS*2+1)*(MAX_RADIUS*2+1));
  
  const float3 n = float3(circles, sqrt(1. - dot(circles, circles)));
  const float psd = pow(saturate(dot(n, normalize(float3(1, 0.7, 0.5)))), 6);
  const half3 color = layer.sample(size * fract(uv/resolution / nodeAspect(size) ) ).rgb + 5 * psd;
  return opaque(color);
}



// =================================================================

layerEffect(rosace21) {
  const float2 uv = worldCoordAdjusted(position, size);
  const float s = floor(1 + uv.x);
  const float2 U = float2( mod(uv.x + 2 + 0.15*sign(s - 0.5), 2) - 1, uv.y);
  const float r=length(U);

  float a = atan2(U.y, U.x);
  half4 col = 0;
  
  for (int i=0; i<3; i++ ) {
    const float ab = a * 5 / 3;
    const float A = ab + (s <= 0) * time;
    const float B = ab + (s > 0) * time;
    const float d = smoothstep(1, 0.9, 8*abs(r - 0.2 *sin(A) - 0.5));
    const half4 T = 1.3* gammaDecode( layer.sample( mod(size * float2(B / pi , r - 0.2 * sin(A)), size ) ));
    col = max(col, (1 + cos(A) * 0.7)/1.7 * d * T);
    a += TAU;
  }
  return opaque(col) ;
}


// =================================================================

layerEffect(water92) {
 const float waveStrength = 0.02;
 const float frequency = 30.0;
 const float waveSpeed = 5.0;
 const half4 sunlightColor = half4(1.0,0.91,0.75, 1.0);
 const float sunlightStrength = 5.0;
 const float centerLight = 2.;
 const float oblique = .25;
 
 const float2 tapPoint = mouse;
 
 const float2 uv = position / size;
 const float modifiedTime = time * waveSpeed;
 const float2 distVec = (uv - tapPoint) * nodeAspect(size);
 const float distance = length(distVec);
 
 const float multiplier = (distance < 1.0) ? ((distance-1.0)*(distance-1.0)) : 0.0;
 const float addend = (sin(frequency*distance-modifiedTime)+centerLight) * waveStrength * multiplier;
 const float2 newTexCoord = uv + addend*oblique;
 
 const half4 colorToAdd = sunlightColor * sunlightStrength * addend;
 
 return layer.sample(size * newTexCoord) + colorToAdd;
 }
 
// =================================================================

layerEffect(aberration02) {
 const float redShift = 100.0;
 const float greenShift = 50.0;
 const float blueShift = 15.0;
 const float aberrationStrength = 1.0;

 const float2 texelSize = 1 / size;
 const float2 uv = position / size;

 const float uvXOffset = toWorld(uv).x;
 const float mouseXOffset = toWorld(mouse).x;
 
 const float uvXFromCenter = uvXOffset - mouseXOffset;
 const float finalUVX = uvXFromCenter * abs(uvXFromCenter) * aberrationStrength;
 
 const half redChannel = layer.sample( size * float2(uv.x + (finalUVX * (redShift * texelSize.x)), uv.y)  ).r;
 const half greenChannel = layer.sample( size * float2(uv.x + (finalUVX * (greenShift * texelSize.x)), uv.y) ).g;
 const half blueChannel = layer.sample( size * float2(uv.x + (finalUVX * (blueShift * texelSize.x)), uv.y) ).b;
 
 return opaque(redChannel, greenChannel, blueChannel);
}

// =================================================================

layerEffect(isovalues) {
  const half4 fragColor = (
                      layer.sample(position + float2( -1,-1)) +
                      layer.sample(position + float2( 0,-1 )) +
                      layer.sample(position + float2( 1,-1 )) +
                      layer.sample(position + float2( -1, 0)) +
                      layer.sample(position + float2( 0, 0 )) +
                      layer.sample(position + float2( 1, 0 )) +
                      layer.sample(position + float2( -1, 1)) +
                      layer.sample(position + float2( 0, 1 )) +
                      layer.sample(position + float2( 1, 1 ))  ) / 9.;

  const float v = sin(TAU*3.*length(fragColor.xyz));
  return opaque(fragColor * ( 1 - smoothstep(0 , 1, 0.5*abs(v)/fwidth(v))));
}


// =================================================================

layerEffect(vhs02) {
  const float2 uv = position / size;
  
  // Jitter each line left and right
  const float2 samplePosition = uv + float2(
                                            (rand(float2(time, position.y))-0.5)/64.0,
                                            (rand(float2(time))-0.5)/32.0);
  // Slightly add color noise to each line
  const half4 texColor = (-0.5 +
                         half4(
                               rand(float2(position.y, time)),
                               rand(float2(position.y, time + 1)),
                               rand(float2(position.y, time + 2)),
                               0))*0.1;
  
  // Either sample the texture, or just make the pixel white (to get the staticy-bit at the bottom)
  const float whiteNoise = rand(float2(floor(samplePosition.y*80.0),
                                       floor(samplePosition.x*50.0))+float2(time,0));
  if (whiteNoise > 11.5-30.0*samplePosition.y || whiteNoise < 1.5-5.0*samplePosition.y) {
    return texColor + layer.sample(size * samplePosition);
  } else {
    return 1;
  }
}


// =================================================================
 
layerEffect(postProcess) {
  const float2 q = position / size;
  const float2 uv = 0.5 + (q-0.5)*(0.9 + 0.1*sin(0.2*time));
  const half3 oricol = layer.sample(position).rgb;
  
  half3 col = {
    layer.sample( size * float2(uv.x+0.003,uv.y)).x,
    layer.sample( size * float2(uv.x+0.000,uv.y)).y,
    layer.sample( size * float2(uv.x-0.003,uv.y)).z
  };
  
  col = saturate(col*0.5+0.5*col*col*1.2);
  col *= 0.5 + 0.5*16.0*uv.x*uv.y*(1.0-uv.x)*(1.0-uv.y);
  col *= half3(0.95,1.05,0.95);
  col *= 0.9+0.1*sin(10 * time+uv.y * 1000);
  col *= 0.99+0.01*sin(110 * time);
  
  const float comp = smoothstep( 0.2, 0.7, sin(time) );
  col = mix( col, oricol, saturate(-2.0+2.0*q.x+3.0*comp) );
  
  return opaque(col);
}


// =================================================================

layerEffect(deform02) {
  const float2 uv2 = worldCoordAdjusted(position, size);
  const float2 uv = float2(uv.x, abs(uv.y));
  return layer.sample(size * fract(float2((uv.x/uv.y)+(sin(time * PI * 0.25) * 2),
                             (1 / uv.y)+(cos(time * PI * 0.3) * 2)))) * uv.y;
}


// =================================================================

layerEffect(laplace) {
  const float2 uv = position / size ;
  const half3 scc = layer.sample(size * uv).rgb;
  const half3 sum = (
                     layer.sample( size * uv + float2(-1,  0) ).rgb +
                     layer.sample( size * uv + float2( 1,  0) ).rgb +
                     layer.sample( size * uv + float2( 0, -1) ).rgb +
                     layer.sample( size * uv + float2( 0,  1) ).rgb
                     ) - scc * 4;
  
  return opaque( scc * pow(luminance(sum * 6), 1.25) );
}


// =================================================================

layerEffect(infinite) {
  const float2 u = worldCoordAdjusted(position, size) / 2;
  return layer.sample(size * fract( 0.2 * time - float2(u.x,1)/u.y ) ) * -u.y * 3 ;
}


// =================================================================

layerEffect(sliced) {
  const float columns = 6; //4. + 3.5 * sin(uni.iTime);
  const float columnWidth = 1 / columns;
  const float t = time;
  const float scrollProgress = 0.5 + 0.5 * sin(PI + t);
  const float zoom = 1 + 0.5 * sin(t);
  const float padding = 0.15 + 0.15 * sin(t);
  
  const float2 uv2 = worldCoordAdjusted(position, size);
  const float2 uv = (uv2 * rot2d(0.2 * sin(t))) * nodeAspect(size);
  
  float2 uvRepeat = fract(uv * zoom);
  
  // calc columns and scroll/repeat them
  const float colIndex = floor(uvRepeat.x * columns) + 1.;
  const float yStepRepeat = colIndex * scrollProgress;
  uvRepeat += float2(0, yStepRepeat);
  uvRepeat = fract(uvRepeat);
  
  // add padding
  uvRepeat.y *= 1 + padding;
  uvRepeat.y -= padding;
  uvRepeat.x *= (columnWidth + padding * 1.) * columns;
  uvRepeat.x -= padding * colIndex;
  if (uvRepeat.y > 0 && uvRepeat.y < 1 && uvRepeat.x < columnWidth * colIndex && uvRepeat.x > columnWidth * (colIndex - 1)) {
      return layer.sample(uvRepeat * size);
  }
  return 1;
}


// =================================================================

layerEffect(tunnel92) {
   const float2 uv2 = abs(worldCoord(position, size) / 2) * 2;
   const float y = max(uv2.x,uv2.y);
   const float2 uv = float2(1,  min(uv2.x,uv2.y))/y - time * float2(-0.6, 0);
   return layer.sample( mod(size * uv, size) )*y;
 }

 // =================================================================

layerEffect(water93) {
  const float2 r = size;
  
  float h = 0;
  float b = 1;
   
   for(uint o = 1; o <= 8; o++) {
     h += sin(b / (o + 15.) * (time * (o * (.5 - .1 * o) + 5.) - 28. * length(position / r))) / (b + b);
     b += b;
   }
   
   const float2 n = 2. * float2(dfdx(h), dfdy(h));
   return layer.sample(position + size * n) + dot(n, n) * length(r);
 }

// =================================================================


layerEffect(blackHole) {
  const float2 uvb = position / size * 4;
  const float2 uva = uvb * nodeAspect(size);
  const float2 bh = float2(-3 + mod(time, 12), 2);
  const float distToHole = distance(uva, bh) ;
  const float2 awayVec = normalize(uva - bh);
  
  const float2 uv = uvb - awayVec/distToHole * 0.6 ;
  
  const float pd = pow(3 * distToHole, 2);
  const float cl = clamp(0.0, 1.0, pd / 8);
  const float2 uvx = size * uv * 0.2;
  const half3 space3 = layer.sample( uvx ).rgb * cl;
  
  const half3 space = space3 * space3 * space3;
  return opaque( space * 2);
}

 // =================================================================

layerEffect(vhsfilter) {
  const float2 uv = position / size;
  const float d = length(uv - 0.5);
  const float blur = 0.02;
  
  const float ss = sin(time) + sin(2 * time) + sin(0.3 * time) + sin(1.4 * time) + cos(0.7 * time) + cos(1.3 * time);
  const float2 myuv =  float2(uv.x + sin( (uv.y + sin(time)) * abs(ss) * 4 ) * 0.02, uv.y) ;
  
  half3 col = half3(layer.sample( float2(myuv.x+blur, myuv.y) * size  ).r,
                    layer.sample( myuv * size ).g,
                    layer.sample( float2(myuv.x-blur,myuv.y) * size ).b
                    );
  
  const float scanline = sin(uv.y*400.0)*0.08;
  col -= scanline;
  col *= 1.0 - d * 0.5;
  return opaque(col);
}

// ===============================================================

layerEffect(pressure) {
  float touchPressure = (0.6 + 0.4 * cos (time * 4));
  const float touchRadius = 0.3;
  const float gridRadius = 0.5;
  const float gridResolution = 30;
  const half4 gridColor = half4(1, 1 - touchPressure, 0, 1);

  float3 frag = float3(position/size * nodeAspect(size), 0);
  float2 touchPosition = mouse * nodeAspect(size);
  float touchDistance = length (frag.xy - touchPosition);
  
  const float3 ray = normalize(frag - float3(0.5 / nodeAspect(size), -10));

  const int ITERATION = 3;
  for (int i = 0; i < ITERATION; ++i) {
    const float deformation = 0.5 + 0.5 * cospi( min (touchDistance / touchRadius, 1.0));
    frag += (touchPressure * deformation - frag.z) * ray;
    touchDistance = length (frag.xy - touchPosition);
  }

  const half4 color = layer.sample(size * frag.xy / nodeAspect(size) );

  const float2 gridPosition = smoothstep (0.05, 0.1, abs (fract (frag.xy * gridResolution) - 0.5));
  return mix (color, gridColor, (1.0 - gridPosition.x * gridPosition.y) * smoothstep (gridRadius * touchPressure, 0.0, touchDistance));
}

// ===============================================================


