// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2025

#include <metal_stdlib>
#include "support.h"

using namespace metal;


// =================================================================

layerEffect(alphax) {

  struct Args {
   float radius;
   float blur;
   bool compositing;
 };

  auto args = reinterpret_cast<const device Args *>(arg);
  
  float2 u = position / size;
  float2 m = mouse;
  float a = length(m-u);
  a=smoothstep(args->blur, -args->blur, a-args->radius);
  
  float b=length(m-u);
  b=smoothstep(args->blur, -args->blur, b-args->radius);

  if (! args->compositing) {
    return half4(a,0,b,1);//2 color channels are set by mouse positions.
  } else {
    const half3 a4 = half3( layer.sample(size * u).xyz) * a;//colors are set by
    const half3 b4 = half3( tex.sample(sampler(), u).xyz) * b;//alpha channels are set by distance to mouse positions.
    const half3 ab = half3(a4 * (1 - b4) + b4 * (1 - a4));
    return opaque(ab);
  }

}

// =================================================================

layerEffect(flip02) {
  const float grid_width = 0.1;
  const float2 tc = position / size;
  float2 xy = tc / grid_width;
  const float2 grid = floor(xy);
  xy = mod(xy, 1.0) - 0.5;
  
  float alpha = 0.0;//uni.iMouse.x / uni.iResolution.x;
  float timex = time - (grid.y - grid.x)*0.1;
  timex = mod(timex, 6.0);
  alpha += smoothstep(0.0, 1.0, timex);
  alpha += 1.0 - smoothstep(3.0, 4.0, timex);
  alpha = abs(mod(alpha, 2.0)-1.0);

  const float side = step(0.5, alpha);
  
  alpha = radians(alpha*180.0);
  const float3 normal = float3(cos(alpha),0,sin(alpha));
  const float3 d = float3(1.0,xy.y,xy.x);
  const float3 p = float3(-1.0 - sin(alpha) / 4, 0, 0);
  
  const float3 up = float3(0,1,0);
  const float3 right = cross(up, normal);
  const float dn = dot(d, normal);
  const float pn = dot(p, normal);
  const float3 hit = p - d / dn * pn;
  const float2 uv = 0.5 + float2( dot(hit, right), dot(hit, up) );

  if (uv.x<0.0||uv.y<0.0||uv.x>1.0||uv.y>1.0) {
    return 0;
  }

  const float2 guv = grid*grid_width;
  const float2 c1c = guv + float2(1-uv.x,uv.y)*grid_width;
  const float2 c2c = guv + float2(uv.x, uv.y )*grid_width;
  const half4 c1 = layer.sample(size * c1c );
  const half4 c2 = tex.sample(sampler(), c2c ) ;
  return saturate(mix(c1, c2, side));
}

// =================================================================

static float fbm(float2 p) {
  float v = 0.0;
  v += noisePerlin(p)*.5;
  v += noisePerlin(p*2.)*.25;
  v += noisePerlin(p*4.)*.125;
  return v;
}

colorEffect(burning) {
  const float2 uv = position / size;
  
  const half3 src = currentColor.rgb;
  const half3 tgt = tex.sample(sampler(), uv).rgb;

  
  const float2 uvv = uv - float2(1.5, 0);
  
  const float ctime = mod(time*.5,2.5);
  
  half3 col = src;
  
  // burn
  const float d = uvv.x+uvv.y*0.5 + 0.5*fbm(uvv*15.1) + ctime*1.3;
  if (d >0.35) col = saturate(col-(d-0.35)*10);
  if (d >0.47) {
    if (d < 0.5 ) col += (d-0.4)*33.0*0.5*(0.0+noisePerlin(100.*uvv+float2(-ctime*2.,0.)))*half3(1.5,0.5,0.0);
    else col += tgt; }
  
  return opaque(col);
}

// =================================================================

colorEffect(fade) {

  const float d = 2;
  const float i = 2;

  const float2 uv = position / size;
  const float tot = 2. * (d + i);
  const float t = mod(time, tot);
  const float z = mod(t, d + i);
  const bool s = t > (d + i);
  const float m2 = min(z, d) / i;
  const float m = (s - m2) * sign(s - 0.5);
  const half3 texx0 = currentColor.xyz;
  const half3 texx1 = tex.sample(sampler(), uv).xyz;
  return opaque(mix(texx0, texx1, m));
}

// =================================================================

colorEffect(noiseFade) {
  struct Args {
    float speed;
  };

  auto args = reinterpret_cast <device const struct Args *>(arg);

  const float2 uv = position / size;
  const half4 fore = currentColor;
  const half4 back = tex.sample(sampler(),uv);
  const float noise = interporand( floor(position.xy / 5) / size, 256).r;
  const float offset = sin(time * args->speed);
  const float a = saturate(offset * 3.0 - uv.x - noise);
  return back * (1.0 - a) + fore * a;
}

// =================================================================

class cube92 {
public:
  
  const float persp = 0.7;
  const float unzoom = 0.3;
  const float reflection = 0.4;
  const float floating = 3;
  
  float2 project (const float2 p) {
    return p * float2(1, -1.2) + float2(0, -floating/100);
  }
  
  bool inBounds (const float2 p) {
    return all( float2(0) < p ) && all( p < float2(1));
  }
  
  half4 bgColor (const float2 p, const float2 pfrx, const float2 ptox,
                 SwiftUI::Layer vid0, const float2 size, texture2d<half> vid1) {
    half4 c = half4(0, 0,  0, 1);
    const float2 pfr = project(pfrx);
    if (inBounds(pfr)) {
      c += mix(half4(0), vid0.sample(size * yflip(pfr) ), reflection * mix(1, 0, pfr.y));
    }
    const float2 pto = project(ptox);
    if (inBounds(pto)) {
      c += mix(half4(0), vid1.sample(sampler(), yflip(pto) ), reflection * mix(1, 0, pto.y));
    }
    return c;
  }
  
  // p : the position, persp : the perspective in [0, 1], center : the xcenter in [0, 1] \ 0.5 excluded
  float2 xskew (const float2 p, const float persp, const float center) {
    const float x = mix(p.x, 1.-p.x, center);
    const float2 z = float2( x, (p.y - 0.5*(1-persp) * x) / (1+(persp-1)*x) ) - float2(0.5-abs(center-0.5), 0);
    return fma(z, float2(0.5 / abs(center - 0.5 ) * (center < 0.5 ? 1 : -1), 1), float2(center<0.5 ? 0 : 1, 0));
  }
};

layerEffect(cube92) {
  class cube92 shad;
  const float progress = 0.5 + sin(time / 2) * 0.5;

  const float2 op = yflip(position / size);
  const float uz = shad.unzoom * 2.0*(0.5-abs(0.5 - progress));
  const float2 p = -uz*0.5+(1.0+uz) * op;
  const float2 fromP = shad.xskew(
                       (p - float2(progress, 0.0)) / float2(1.0-progress, 1.0),
                       1.0-mix(progress, 0.0, shad.persp),
                       0.0
                       );
  const float2 toP = shad.xskew(
                     p / float2(progress, 1.0),
                     mix(pow(progress, 2.0), 1.0, shad.persp),
                     1.0
                     );
  if (shad.inBounds(fromP)) {
    return layer.sample(size * yflip(fract(fromP)) );
  } else if (shad.inBounds(toP)) {
    return tex.sample(sampler(), yflip(toP));
  } else {
    return shad.bgColor(op, fromP, toP, layer, size, tex);
  }
}

// =================================================================


class swap {
public:
  
  const float reflection = 0.4;

  const half4 black = half4(0, 0, 0, 1);
  const float2 boundMin = 0;
  const float2 boundMax = 1;
  
  bool inBounds(const float2 p) {
    return all((boundMin < p)) && all((p < boundMax));
  }
  
  float2 project (const float2 p) {
    return p * float2(1, -1.2) + float2(0, -0.02);
  }
  
  half4 bgColor (const float2 p, const float2 pfrx, const float2 ptox, SwiftUI::Layer vid0, const float2 size, texture2d<half> vid1) {
    half4 c = black;
    const float2 pfr = project(pfrx);
    if (inBounds(pfr)) {
      c += mix(black, vid0.sample(size * yflip(pfr) ), reflection * mix(1, 0, pfr.y));
    }
    const float2 pto = project(ptox);
    if (inBounds(pto)) {
      c += mix(black, vid1.sample(sampler(), yflip(pto) ), reflection * mix(1, 0, pto.y));
    }
    return c;
  }
};

layerEffect(swap) {
  class swap shad;

  const float perspectivex = .2;
  const float depth = 3.;

  const float progress = sin(time*0.5)*.5+0.5;
  const float2 p = yflip(position / size);

  const float sizex = mix(1.0, depth, progress);
  const float perspx = perspectivex * progress;
  const float2 pfr = (p + float2(0, -0.5)) * float2(sizex/(1-perspectivex*progress), sizex/(1-sizex*perspx*p.x)) + float2(0, 0.5);

  const float sizey = mix(1, depth, 1-progress);
  const float perspy = perspectivex * (1.-progress);
  const float a1 = sizey/(1-perspectivex*(1-progress));
  const float a2 = sizey/(1-sizey*perspy*(0.5-p.x));
  const float2 pto = (p + float2(-1, -0.5)) * float2(a1, a2) + float2(1, 0.5);

  const bool fromOver = progress < 0.5;

  if (fromOver) {
    if (shad.inBounds(pfr)) {
      return layer.sample(size * yflip(fract(pfr)));
    }
    else if (shad.inBounds(pto)) {
      return tex.sample(sampler(), yflip(pto));
    }
    else {
      return shad.bgColor(p, pfr, pto, layer, size, tex);
    }
  }
  else {
    if (shad.inBounds(pto)) {
      return tex.sample(sampler(), yflip(pto) );
    }
    else if (shad.inBounds(pfr)) {
      return layer.sample(size * yflip(pfr) );
    }
    else {
      return shad.bgColor(p, pfr, pto, layer, size, tex);
    }
  }
}

// =================================================================

class kaleidoscope03 {
public:
  
  float2 kaleidoscope(float2 uv, float2 offset, float splits, bool linear, bool fix_x) {
    // XY coord to angle
    float angle = atan2(uv.y, uv.x);
    // Normalize angle (0 - 1)
    angle = ((angle / PI) + 1.0) * 0.5;
    // Rotate by 90°
    angle = angle + 0.25;
    // Split angle
    angle = mod(angle, 1.0 / splits) * splits;
    
    // Warp angle
    if (!linear) {
      float a = (2.0*angle - 1.0);
      angle = -a*a + 1.0;
      
      //angle = -pow(a, 0.4) + 1.0;
    } else {
      angle = -abs(2.0*angle - 1.0) + 1.0;
    }
    
    angle = angle*0.1;
    
    // y is just dist from center
    float y = length(uv);
    //y = (y*30.0);
    
    if (fix_x) {
      angle = angle * (y*3.0);
    }
    
    return float2(angle, y) + offset;
  }
  
  float3 heatmapGradient(float t) {
    return saturate((pow(t, 1.5) * 0.8 + 0.2) * float3(smoothstep(0.0, 0.35, t) + t*0.5, smoothstep(0.5, 1.0, t), max(1.0 - t*1.7, t*7.0 - 6.0)));
  }
  
  float3 customGradient(float t) {
    t = mod(t*-0.9, 42.0);
    return 0.5 + 0.5*cos( 3.0 + t*0.075*t + float3(0.0,0.6,1.0));
  }
};

layerEffect(kaleidoscope03) {
 struct Args {
      bool MOUSE = false;
      bool GAMMA_CORRECT = true;
      // Gives good results if LINEAR is ON
      bool FIX_X = false;
      bool USE_TEXTURE = false;
      bool COLOR_TRANSITION_DEBUG = false;
      // Whether wrapping transition is linear or squared
      bool LINEAR = false;
  };

 auto args = reinterpret_cast<const device Args *>(arg);

 class kaleidoscope03 shad;
  
  float COLOR_TRANSITION_SIZE = 0.04;
  float KALEIDOSCOPE_SPEED_X = 9.0;
  float KALEIDOSCOPE_SPEED_Y = -20.0;
  float KALEIDOSCOPE_SPLITS = 6.0;

  // Mobile friendly UVs
  float2 uv = worldCoordAdjusted(position, size);

  // Start with a good color
  float timex = time + 1207.0;

  if (args->MOUSE) {
    timex += 0.25 * mouse.x * size.x;
  }

  float2 A = float2(timex * KALEIDOSCOPE_SPEED_X * 0.005,
                    timex * KALEIDOSCOPE_SPEED_Y * 0.005);

  uv = shad.kaleidoscope(uv, A, KALEIDOSCOPE_SPLITS, args->LINEAR, args->FIX_X);

  if (args->USE_TEXTURE) {
    uv = uv * 0.7;
    half4 texx = layer.sample(size * fract(uv));
    return opaque(texx.rgb);
  } else {
    float texx = tex.sample(sampler(), fract(uv) ).r;

    // frequency and shape of the transition
    float d = (cos(uv.y+1.2*cos(uv.x)*texx) * 0.5) + 0.5;
    d = smoothstep(0.5 - COLOR_TRANSITION_SIZE, 0.5 + COLOR_TRANSITION_SIZE, d);

    if (args->COLOR_TRANSITION_DEBUG) {
      return opaque(d,d,d);
    }
    
    float3 a = shad.customGradient(texx);
    float3 b = shad.heatmapGradient(texx);

    if (args->GAMMA_CORRECT) {
      a = pow(a, float3(2.2));
      b = pow(b, float3(2.2));
    }
    float3 color = mix(a, b, d);
    
    if (args->GAMMA_CORRECT) {
      color = pow(color, float3(1.0 / 2.2));
    }
    
    return opaque(color.rgb);
  }
}

// ============================================================

layerEffect(filter93) {
 
 enum Variant {
    barrel, bloating, box, grayscalex, emboss
 };

 struct Args {
 char variant;
 };

  auto args = reinterpret_cast<const device Args *>(arg);
  
   const float2 uv = position / size;

  switch(args->variant) {
    case barrel: {
      const float2 distortion_center = float2(0.5,0.5);
      
      //K1 < 0 is pincushion distortion
      //K1 >=0 is barrel distortion
      const float k1 = 1.0 * sin(time*0.5);
      const float k2 = 0.5;
      
      const float2 rx = uv - distortion_center;
      const float rr = dot(rx,rx);
      const float r2 = sqrt(rr) * (1.0 + k1*rr + k2*rr*rr);
      const float theta = atan2(rx.x, rx.y);
      const float2 distortion = float2(sin(theta), cos(theta)) * r2;
      const float2 dest_uv = distortion + 0.5;
      return layer.sample( size * dest_uv);
    }
      break;
    case bloating:
    {
      const float maxPower = 1.5; //Change this to change the grade of bloating that is applied to the image.
      const float2 bloatPos = 0; //The position at which the effect occurs
      
      const float n = smoothstep(0.,1.,abs(1.-mod(time/2.,2.)));
      const float2 q = bloatPos+0.5;
      const float l2 = length(uv-q);
      const float2 p = uv - q;
      
      const float a1 = acos(clamp(dot(normalize(p),float2(1,0)),-1.0, 1.0)) * (p.y < 0 ? -1 : 1) * (length(p) != 0);
      const float l = pow(l2, 1+n*(maxPower-1));
      const float2 uv2 = l*float2(cos(a1),sin(a1))+q;
      return layer.sample(size * uv2);
    }
      break;
    case box: {
      half3 col = 0;
      
      for(int i = 0; i < 3; i++){
        for(int j = 0; j < 3; j++){
          const float2 realRes = float2(i - 1, j - 1) / size * 2;
          const half3 x = layer.sample( size * (uv + realRes) ).rgb ;
          col += gammaDecode(x);
        }
      }
      return opaque(gammaEncode(col / 9));
    }
      break;
    case grayscalex: {
      const float boost = 1.5;
      const float reduction = 4.0;
      const half3 col = layer.sample(size * uv).rgb;
      const float vignette = distance( 0.5, uv );
      const half3 grey = grayscale(col);
      return opaque(mix(grey, col, saturate(boost - vignette * reduction)));
    }
      break;
    case emboss: {
      const float2 delta = 1 / size;
      return opaque((layer.sample( size * (uv - delta) ) * 3 - layer.sample(size * uv) - layer.sample(size * (uv+delta) )).rgb);
    }
      break;
    default:
      break;
  }
  return 0;
 }

// =================================================================

