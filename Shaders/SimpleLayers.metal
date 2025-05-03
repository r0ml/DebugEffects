// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2025

#include <metal_stdlib>
#include "support.h"

using namespace metal;

// =================================================================

layerEffect(lights03) {
 
  half3 fragColor = 0;
  for(float m = 1; m <= 5; m++) {
    float2 dd = yflip(position / size);
    float3 d = normalize(float3(dd * nodeAspect(size),1)-.5); // how to flip?
    float3 p = d*( -1./d.y);
    float3 l=float3(0,-.5,3)+sin(float3(1,2,.3)*time+m)*float3(1,.2,1);
    fragColor += layer.sample(fract(p.xz) * size).rgb * pow(max(1.5-length(l-p),0.),3.) + pow(dot(l,d)/length(l),1e4);
  }
  return opaque(fragColor);
}

// ================================================================

static float hash12(float2 p)
{
  const float HASHSCALE1 = .1031;
  float3 p3  = fract(float3(p.xyx) * HASHSCALE1);
  p3 += dot(p3, p3.yzx + 19.19);
  return fract((p3.x + p3.y) * p3.z);
}

static float2 hash22(float2 p)
{
  const float3 HASHSCALE3 = float3(.1031, .1030, .0973);
  float3 p3 = fract(float3(p.xyx) * HASHSCALE3);
  p3 += dot(p3, p3.yzx+19.19);
  return fract((p3.xx+p3.yz)*p3.zy);
  
}

layerEffect(rain06) {
  const float DOUBLE_HASH  = 0;
  const float MAX_RADIUS = 2;

  float resolution = 10. * exp2(-3.*mouse.x);
  float2 uv = position / size * nodeAspect(size) * resolution;
  float2 p0 = floor(uv);
  
  float2 circles = float2(0.);
  for (int j = -MAX_RADIUS; j <= MAX_RADIUS; ++j)
  {
    for (int i = -MAX_RADIUS; i <= MAX_RADIUS; ++i)
    {
      float2 pi = p0 + float2(i, j);
      float2 hsh = DOUBLE_HASH ? hash22(pi) : pi;
      float2 p = pi + hash22(hsh);
      
      float t = fract(0.3*time + hash12(hsh));
      float2 v = p - uv;
      float d = length(v) - (float(MAX_RADIUS) + 1.)*t;
      
      float h = 1e-3;
      float d1 = d - h;
      float d2 = d + h;
      float p1 = sin(31.*d1) * smoothstep(-0.6, -0.3, d1) * smoothstep(0., -0.3, d1);
      float p2 = sin(31.*d2) * smoothstep(-0.6, -0.3, d2) * smoothstep(0., -0.3, d2);
      circles += 0.5 * normalize(v) * ((p2 - p1) / (2. * h) * (1. - t) * (1. - t));
    }
  }
  circles /= float((MAX_RADIUS*2+1)*(MAX_RADIUS*2+1));
  
  float intensity = mix(0.01, 0.15, smoothstep(0.1, 0.6, abs(fract(0.05*time + 0.5)*2.-1.)));
  float3 n = float3(circles, sqrt(1. - dot(circles, circles)));
  half3 color = layer.sample(fract(uv/resolution / nodeAspect(size) /* - intensity*n.xy */ ) * size).rgb + 5.*pow(saturate(dot(n, normalize(float3(1., 0.7, 0.5)))), 6.);
  return opaque(color);
}



// =================================================================

layerEffect(rosace21) {
  float2 U = worldCoordAdjusted(position, size);
  float s=floor(++U.x); U.x = mod(U.x+1.+.15*sign(s-.5), 2.) - 1.; // 2 normalized areas
  float r=length(U), a = atan2(U.y, U.x), A, B, d, t=time;   // polar coordinates
  
  half4 O = 0;
  
  for (int i=0; i<3; i++ ) {
    A = B = 5./3.*a;
    if(s>0.) B+=t; else A+=t; // fractional => 3 turns to close loop via 5 wings.
    d = smoothstep(1., .9, 8.*abs(r-.2*sin(A)-.5));                  // ribbon wings
    half4 T = 1.3* gammaDecode( layer.sample( mod(size * float2(B / pi , r-.2*sin(A)), size ) )); // to attach texture replace B by A
    O = max(O, (1.+cos(A)*.7)/1.7 * d*T);       // 1+cos(A) = depth-shading
    a += TAU;                               // next turn
  }
  return opaque(O) ;
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
 
 float2 tapPoint = mouse;
 
 float2 uv = position / size;
 float modifiedTime = time * waveSpeed;
 float aspectRatiox = nodeAspect(size).x;
 float2 distVec = uv - tapPoint;
 distVec.x *= aspectRatiox;
 float distance = length(distVec);
 
 float multiplier = (distance < 1.0) ? ((distance-1.0)*(distance-1.0)) : 0.0;
 float addend = (sin(frequency*distance-modifiedTime)+centerLight) * waveStrength * multiplier;
 float2 newTexCoord = uv + addend*oblique;
 
 half4 colorToAdd = sunlightColor * sunlightStrength * addend;
 
 return layer.sample(size * newTexCoord) + colorToAdd;
 }
 
// =================================================================

// each output pixel is constructed from 3 different locations of source pictures (by channel)

static float bx2(float x) {
 return x * 2.0 - 1.0;
}

layerEffect(aberration02) {
 const float redShift = 100.0;
 const float greenShift = 50.0;
 const float blueShift = 15.0;
 const float aberrationStrength = 1.0;

 float2 texelSize = 1 / size;
 float2 uv = position / size;

 float uvXOffset = bx2(uv.x);
 float mouseXOffset = bx2(mouse.x);
 
 float uvXFromCenter = uvXOffset - mouseXOffset;
 float finalUVX = uvXFromCenter * abs(uvXFromCenter) * aberrationStrength;
 
 half redChannel = layer.sample( size * float2(uv.x + (finalUVX * (redShift * texelSize.x)), uv.y)  ).r;
 half greenChannel = layer.sample( size * float2(uv.x + (finalUVX * (greenShift * texelSize.x)), uv.y) ).g;
 half blueChannel = layer.sample( size * float2(uv.x + (finalUVX * (blueShift * texelSize.x)), uv.y) ).b;
 
 return opaque(redChannel, greenChannel, blueChannel);
}

// =================================================================

static half4 T(float2 uv, float i, float j, SwiftUI::Layer vid) {
  return vid.sample(uv + float2(i,j));
}

layerEffect(isovalues) {
  const float2 tc = position / size;
  const half4 fragColor = (
                      T(position, -1,-1, layer)+
                      T(position, 0,-1 , layer)+
                      T(position, 1,-1,  layer)+
                      T(position, -1, 0, layer)+
                      T(position, 0, 0,  layer)+
                      T(position, 1, 0,  layer)+
                      T(position, -1, 1, layer)+
                      T(position, 0, 1,  layer)+
                      T(position, 1, 1,  layer) ) / 9.;

  float v = sin(TAU*3.*length(fragColor.xyz));

  return opaque(fragColor * ( 1 - smoothstep(0 , 1, 0.5*abs(v)/fwidth(v))));
}


// =================================================================

layerEffect(vhs02) {
  half4 texColor = 0;
  // get position to sample
  float2 samplePosition = position / size;
//  const float whiteNoise = 9999.0;
  const float t = time;
  
  // Jitter each line left and right
  samplePosition.x = samplePosition.x+(rand(float2(t, position.y))-0.5)/64.0;
  // Jitter the whole picture up and down
  samplePosition.y = samplePosition.y+(rand(float2(t))-0.5)/32.0;
  // Slightly add color noise to each line
  texColor = texColor + (-0.5 +
                         half4(
                               rand(float2(position.y,t)),
                               rand(float2(position.y,t+1.0)),
                               rand(float2(position.y,t+2.0)),
                               0))*0.1;
  
  // Either sample the texture, or just make the pixel white (to get the staticy-bit at the bottom)
  const float whiteNoise = rand(float2(floor(samplePosition.y*80.0),
                                       floor(samplePosition.x*50.0))+float2(t,0));
  if (whiteNoise > 11.5-30.0*samplePosition.y || whiteNoise < 1.5-5.0*samplePosition.y) {
    // Sample the texture.
    // samplePosition.y = 1.0-samplePosition.y; //Fix for upside-down texture
    texColor = texColor + layer.sample(size * samplePosition);
  } else {
    // Use white. (I'm adding here so the color noise still applies)
    texColor = 1;
  }
  return texColor;
}


// =================================================================
 
layerEffect(postProcess) {
  const float2 q = position / size;
  const float t = time;
  const float2 uv = 0.5 + (q-0.5)*(0.9 + 0.1*sin(0.2*t));
  const half3 oricol = layer.sample(position).rgb;
  
  half3 col = {
    layer.sample( size * float2(uv.x+0.003,uv.y)).x,
    layer.sample( size * float2(uv.x+0.000,uv.y)).y,
    layer.sample( size * float2(uv.x-0.003,uv.y)).z
  };
  
  col = saturate(col*0.5+0.5*col*col*1.2);
  
  col *= 0.5 + 0.5*16.0*uv.x*uv.y*(1.0-uv.x)*(1.0-uv.y);
  
  col *= half3(0.95,1.05,0.95);
  
  col *= 0.9+0.1*sin(10.0*t+uv.y*1000.0);
  
  col *= 0.99+0.01*sin(110.0*t);
  
  float comp = smoothstep( 0.2, 0.7, sin(t) );
  col = mix( col, oricol, saturate(-2.0+2.0*q.x+3.0*comp) );
  
  return opaque(col);
}


// =================================================================

layerEffect(deform02) {
  float2 uv=worldCoordAdjusted(position, size);
  uv.y=abs(uv.y);
  float t = time;
  return layer.sample(size * fract(float2((uv.x/uv.y)+(sin(t * PI * 0.25) * 2),
                             (1 / uv.y)+(cos(t * PI * 0.3) * 2)))) * uv.y;
}


// =================================================================

layerEffect(laplace) {
  const float2 uv = position / size ;
  
  // float3 cf = texfilter(fc, in.inputTexture);
  const half3 scc = layer.sample(size * uv).rgb;
  const float2 sz = size;
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
  const float aspect = 4.5 / 3;
  const float padding = 0.15 + 0.15 * sin(t);
  
  // get coordinates, rotate & fix aspect ratio
  float2 uv = worldCoordAdjusted(position, size);
  uv = (uv * rot2d(0.2 * sin(t))) * nodeAspect(size);
  
  // create grid coords & set color
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
   float2 uv = abs(worldCoord(position, size) / 2)*2.;
   float y = max(uv.x,uv.y);
   uv = float2(1.,min(uv.x,uv.y))/y - time*float2(-0.6,0.);
   return layer.sample( mod(size * uv, size) )*y;
 }
  

 // =================================================================

layerEffect(water93) {
  float2 r = size;
   float h = 0., b = 1.;
   
   for(uint o = 1; o <= 8; o++) {
     h += sin(b / (o + 15.) * (time * (o * (.5 - .1 * o) + 5.) - 28. * length(position / r))) / (b + b);
     b += b;
   }
   
   float2 n = 2. * float2(dfdx(h), dfdy(h));
   return layer.sample(position + size * n) + dot(n, n) * length(r);
 }

// =================================================================


layerEffect(blackHole) {   // Normalized pixel coordinates (from 0 to 1)
  float2 uv = position / size * 4;
  float2 uva = uv * nodeAspect(size);
   float2 bh = float2(-3.+mod(time,12.),2.);
   float distToHole = distance(uva, bh) ;
   float2 awayVec = normalize(uva - bh);
   
   uv -= awayVec/distToHole*.6 ;
  
  float pd = pow(3 * distToHole, 2);
  float cl = clamp(0.0, 1.0, pd / 8);
  float2 uvx = size * uv * 0.2;
  half3 space = layer.sample( uvx ).rgb*cl;
   
   space = space*space*space;
   half3 col = space * 2.;

   return opaque(col);
 }

 // =================================================================

layerEffect(vhsfilter) {
  
  // distance from center of image, used to adjust blur
  float2 uv = position / size;
  float d = length(uv - float2(0.5,0.5));
  
  // blur amount
  float blur = 0.02;
  //blur = (1.0 + sin(uni.iTime*6.0)) * 0.5;
  //blur *= 1.0 + sin(uni.iTime*16.0) * 0.5;
  //blur = pow(blur, 3.0);
  //blur *= 0.05;
  // reduce blur towards center
  //blur *= d;
  
  float myTime = time;
  
  // fragColor = texture( sampler(), float2(uv.x + sin( (uv.y + sin(myTime)) * abs(sin(myTime) + sin(2.0 * myTime) + sin(0.3 * myTime) + sin(1.4 * myTime) + cos(0.7 * myTime) + cos(1.3 * myTime)) * 4.0 ) * 0.02,uv.y) );
  
  float2 myuv =  float2(uv.x + sin( (uv.y + sin(myTime)) * abs(sin(myTime) + sin(2.0 * myTime) + sin(0.3 * myTime) + sin(1.4 * myTime) + cos(0.7 * myTime) + cos(1.3 * myTime)) * 4.0 ) * 0.02,uv.y) ;
  
  // final color
  float3 col;
  col.r = layer.sample( float2(myuv.x+blur,myuv.y) * size  ).r;
  col.g = layer.sample( myuv * size ).g;
  col.b = layer.sample( float2(myuv.x-blur,myuv.y) * size ).b;
  
  // scanline
  float scanline = sin(uv.y*400.0)*0.08;
  col -= scanline;
  
  // vignette
  col *= 1.0 - d * 0.5;
  
  return opaque(col);
}


// =================================================================


layerEffect(pressure) {
  // Inputs
  float touchPressure = // (uni.wasMouseButtons > 0) *
  (0.6 + 0.4 * cos ( time * 4.0));
  const float touchRadius = 0.3;
  const float gridRadius = 0.5;
  const float gridResolution = 30.0;
  half4 gridColor = half4 (1.0, 1.0 - touchPressure, 0.0, 1.0);

  // Get the position of this fragment
  float3 frag = float3 (position/size * nodeAspect(size), 0.0);

  // Get the touch information
  float2 touchPosition = mouse ;
  touchPosition.x = touchPosition.x * nodeAspect(size).x;
//  touchPosition.y = 1 - touchPosition.y;

  float touchDistance = length (frag.xy - touchPosition);

  // Raymarching
  float3 ray = normalize (frag - float3 (0.5 * nodeAspect(size).y, 0.5, -10.0));
//  float3 ray = normalize (frag - float3(0, 0, -10) );

  int ITERATION = 3;
  for (int i = 0; i < ITERATION; ++i)
  {
    float deformation = 0.5 + 0.5 * cospi ( min (touchDistance / touchRadius, 1.0));
    frag += (touchPressure * deformation - frag.z) * ray;
    touchDistance = length (frag.xy - touchPosition);
  }

  // Get the color from the texture
  half4 color = layer.sample(size * frag.xy / nodeAspect(size) );

  // Add the grid
  float2 gridPosition = smoothstep (0.05, 0.1, abs (fract (frag.xy * gridResolution) - 0.5));
  color = mix (color, gridColor, (1.0 - gridPosition.x * gridPosition.y) * smoothstep (gridRadius * touchPressure, 0.0, touchDistance));

  // Set the fragment color
  return color;
}

// =================================================================


