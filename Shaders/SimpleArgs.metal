// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2025

#include <metal_stdlib>
#include "support.h"
#include "sdf.h"

using namespace metal;

// =================================================================

static float spiral(const float2 m, const float t) {
  float r = length(m);
  float a = atan2(m.y, m.x);
  float v = sin(100.*(sqrt(r)-0.02*a-.3*t));
  return saturate(v);
  
}

colorEffect(hypnotic02) {
  struct Args {
    bool zoom;
    bool dble;
  };

  auto args = reinterpret_cast<device const struct Args *>(arg);

  const float t = args->zoom ? -time : time;
  const float2 uv = position / size * nodeAspect(size);
  const float2 m = nodeAspect(size) * mouse;
  
  float v = spiral(m-uv, t);
  if (args->dble) {
    v += (1.-v)*spiral( 0.5 * nodeAspect(size) - uv, t);
  }
  
  return opaque(v);
}

// =================================================================

colorEffect(thingy2) {
  struct Args {
    int sides;
  };
  
  auto args = reinterpret_cast< device const struct Args *>(arg);
  
  
  float2 uv = 3 * worldCoordAdjusted(position, size) / 2;
  half3 fragColor = 0;
  
  for (int i = 0 ; i < 7 ; i++) {
    const float scaleFactor = float(i)+2.0;
    uv *= rot2d(time * scaleFactor * 0.01);
    
    const float scale = TAU/float(args->sides);
    const float theta = (floor( (atan2(uv.x, uv.y) + PI)/scale)+0.5)*scale;
    const float2 dir = float2(sin(theta), cos(theta));
    const float2 codir = dir.yx * float2(-1, 1);
    uv = float2(dot(dir, uv), dot(codir, uv));
    
    uv.x -= time * scaleFactor * 0.01;
    uv = abs(fract(uv+0.5)*2.0-1.0)*0.7;
    fragColor += half3( exp(-min(uv.x, uv.y)*10.) * (cos(float3(2,3,1)*float(i)+time*0.5)*.5+.5) ) ;
  }
  
  fragColor *= 0.4;
  return opaque(fragColor);
}

// =======================================================================================

colorEffect(triangle) {
  struct Args {
    float sizex;
    bool showdist;
    bool spin;
  };

  auto args = reinterpret_cast< device const struct Args *>(arg);

  const float2 uv=worldCoordAdjusted(position, size) * rot2d(args->spin * time) * 2;
  const float rg = 2 * sqrt(3.0); // in.mul.y;
  const float2 p1 = rg * args->sizex * float2( +0.5, - 0.5 / sqrt(3.0) ); // right bottom
  const float2 p2 = rg * args->sizex * float2(  0, 1 / sqrt(3.0)); // top corner
  const float2 p3 = rg * args->sizex * float2( -0.5, - 0.5 / sqrt(3.0) ); // left bottom
  
  float t = sdTriangle(uv, p1, p2, p3);
  
  const float f=sdCircle(uv, args->sizex , 0);//incircle
  t = sdSubtract(t,f);//substract incircle

  const float oc = sdCircle(uv, args->sizex * 2, 0);
  
  t = sdSubtract(oc, t);

  if (args->showdist) {
    t=fract(t);
  } else {
    const float reso = 2 / size.y;
    t=smoothstep(reso, -reso, t);
  }
  return opaque(t);
}

// =================================================================

static  float randx( float2 co ){
  return rand(co) * 0.5 - 0.25;
}

static half3 noise( const half3 color, float2 uv, float level ) {
  return max(min(color + half3(randx(uv) * level), 1), 0);
}

static half3 sepia( const half3 color, float adjust ) {
  float cr = min(1.0, (color.r * (1.0 - (0.607 * adjust))) + (color.g * (0.769 * adjust)) + (color.b * (0.189 * adjust)));
  float cg = min(1.0, (color.r * (0.349 * adjust)) + (color.g * (1.0 - (0.314 * adjust))) + (color.b * (0.168 * adjust)));
  float cb = min(1.0, (color.r * (0.272 * adjust)) + (color.g * (0.534 * adjust)) + (color.b * (1.0 - (0.869 * adjust))));
  return half3(cr, cg, cb);
}

static half3 vignette( half3 color, float2 uv, float adjust ) {
  return color - max((distance(uv, 0.5) - 0.25) * 1.25 * adjust, 0.0);
}

static half3 channels( const half3 color, half3 channels , float adjust ) {
  if ( all(channels == half3(0)) ) return color;
  half3 clr = color;
  if (channels.r != 0.0) {
    if (channels.r > 0.0) {
      clr.r += (1.0 - clr.r) * channels.r; }
    else {
      clr.r += clr.r * channels.r; }
  }
  if (channels.g != 0.0) {
    if (channels.g > 0.0) {
      clr.g += (1.0 - clr.g) * channels.g; }
    else {
      clr.g += clr.g * channels.g; }
  }
  if (channels.b != 0.0) {
    if (channels.b > 0.0)  {
      clr.b += (1.0 - clr.b) * channels.b; }
    else {
      clr.b += clr.b * channels.b; }
  }
  return clr;
}

colorEffect(simpleEffect) {
  struct Args {
    char effect;
  };
  
  device const struct Args *args = reinterpret_cast< device const struct Args *>(arg);
  
  float2 uv = position / size;
  half3 col = currentColor.rgb;

  switch( args->effect ) {
    case 0: return opaque(half3(grayscale(col)));
    case 1: return opaque( (col - 0.5) * 2 + 0.5); // contrast
    case 2: return opaque( 1 - col); // invert
    case 3: return opaque(noise(col, uv, 0.5));
    case 4: return opaque(sepia(col, 0.75));
    case 5: return opaque(vignette(col, uv, 1.0));
    case 6: return opaque(channels(col, half3(0.2, -0.4, -0.05) , 0.0));
    default: return half4(0.3, 0.4, 0.5, 0.6);
  }
}

// ================================================

class alphax {
public:
  
  //set frame setup
  float2 frame(float2 u, float2 r) {
    return ( (u-.5) * r)/r.y;
  }
  
  // static float4 aOverB(float4 a,float4 b) {
  //   a.xyz*=a.w;
  //   b.xyz*=b.w;
  //   return float4(a+b*(1.-a));
  // }
  
  //not sure if correct, but looks useful.
  half4 aXorB(half4 a, half4 b) {
    a.xyz*=a.w;
    b.xyz*=b.w;
    return half4(a*(1.-b)+b*(1.-a));
  }
};

layerEffect(alphax) {
  class alphax shad;
  
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
    half4 a4 = half4( layer.sample(size * u).xyz, a);//colors are set by
    half4 b4 = half4( tex.sample(sampler(), u).xyz, b);//alpha channels are set by distance to mouse positions.
    return opaque(shad.aXorB(a4, b4).rgb);
  }

}

// =================================================================


layerEffect(flip) {
 struct Args {
   int slices;
   float rspeed;
 };

  auto args = reinterpret_cast<const device Args *>(arg);
 
  const float2 uv = position / size;
  const float perWidth = 1.0 / args->slices;
  const float index = floor( uv.x / perWidth );
  const float centerX = perWidth * ( index + 0.5 );
  const float left = perWidth * index;
  const float right = left + perWidth;
  const float angle = mod(time * args->rspeed, 2 * PI);

  const float2 cod = float2( ( uv.x - centerX) / cos( angle ) + centerX, uv.y );
  
  if( cod.x <= right && cod.x >= left ) {
    if (angle >= PI/2 && angle <= 3 * PI / 2) {
      return tex.sample( sampler(), float2( right - cod.x + left, cod.y ) );
    } else {
      return layer.sample( size * cod);
    }
  } else {
    return opaque( 0 );
  }
}

// =================================================================

// FIXME: incorporate this into flip
static float2 plane(const float3 p, const float3 d, const float3 normal) {
  const float3 up = float3(0,1,0);
  const float3 right = cross(up, normal);
  const float dn = dot(d, normal);
  const float pn = dot(p, normal);
  const float3 hit = p - d / dn * pn;
  const float2 uv = float2( dot(hit, right), dot(hit, up) );
  return uv;
}

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
  const float4 n = float4(cos(alpha),0,sin(alpha),-sin(alpha));
  const float3 d = float3(1.0,xy.y,xy.x);
  const float3 p = float3(-1.0+n.w/4.0,0,0);
  
  const float2 uv = 0.5 + plane(p, d, n.xyz);
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

layerEffect(cartoon) {
  
  struct Args {
    int strength;
    float bias;
    float power;
    float precision;
    Color color;
  };
  
  auto args = reinterpret_cast<const device Args *>(arg);
  
  const half4 p2 = gammaDecode(layer.sample(position));
  const half4 s = gammaDecode(layer.sample(position + 0.5));
  const float l = saturate(pow(length(p2-s),half(args->power) ) * args->strength + args->bias);
  const half4 p = floor( gammaEncode(p2)*(args->precision+.999))/args->precision;
  return mix(p, args->color.g, l);
}


 // =================================================================

layerEffect(sobel) {

  struct Args {
    float threshold;
    bool image;
    char variant;
  };
  
  auto args = reinterpret_cast<const device Args *>(arg);
  
  enum {
    lengthx, lumina, graysc, edge_glow, dfdxx, fwidthx, test
  };

   const float3x3 sobelx =
   float3x3(-1.0, -2.0, -1.0,
            0.0,  0.0, 0.0,
            1.0,  2.0,  1.0);
   const float3x3 sobely =
   float3x3(-1.0,  0.0,  1.0,
            -2.0,  0.0, 2.0,
            -1.0,  0.0,  1.0);

   const half3x3 YCoCr_mat = half3x3(1./4., 1./2., 1./4.,  -1./4., 1./2., -1./4.,   1./2., 0.0, -1./2. );

   float2 sum = 0.0;

  const float2 uv = position / size;
  const float2 res = size;
  const half3 pix = layer.sample(size * uv).rgb;

  switch(args->variant) {
    case lengthx:

     for(int i = -1; i <= 1; i++) {
       for(int j = -1; j <= 1; j++) {
         const float2 xy = uv + float2(i,j) /res;
         const half3 clem = layer.sample(size * xy).xyz;
         const float val = length(clem);
         sum += val * float2(sobelx[1+i][1+j], sobely[1+i][1+j]);
       }
     }
      break;
    case lumina:
     for(int i = -1; i <= 1; i++) {
       for(int j = -1; j <= 1; j++) {
         const float2 xy = uv + float2(i,j) /res;
         const half3 clem = layer.sample(size * xy).xyz;
         const float val = pow(luminance(clem), 0.6);
         sum += val * float2(sobelx[1+i][1+j], sobely[1+i][1+j]);
       }
     }
      break;
    case graysc:
     for(int i = -1; i <= 1; i++) {
       for(int j = -1; j <= 1; j++) {
         const float2 xy = uv + float2(i,j) /res;
         const half3 clem = layer.sample(size * xy).xyz;
         const float val = grayscale(clem);
         sum += val * float2(sobelx[1+i][1+j], sobely[1+i][1+j]);
       }
     }
      break;
    case edge_glow: {
      const float2 dd = (sin(time * 5.0)*0.5 + 1.5) ; // kernel offset
      const float2 pp = position ;
      
      float2 gxy = 0;
      
      for(int i = -1; i<2;i++) {
        for(int j = -1; j<2;j+=2) {
          const float gm = j * (2 - abs(i));
          
          gxy.x += luminance(gm * layer.sample( pp + float2(j, i) * dd).rgb);
          gxy.y += luminance(gm * layer.sample( pp + float2(i, j) * dd).rgb);
        }
      }
      const float g = dot(gxy, gxy);
      const float g2 = 0;
      
      half4 col = layer.sample(pp);
      col += half4(0.0, g, g2, 1.0);
      return col;
    }
    case dfdxx: {
      const float2 uv = position / size;
      const half4 colorx =  layer.sample(size * uv);
      const float grayx = length(colorx.rgb);
      return opaque(half3(step(0.06, length(float2(dfdx(grayx), dfdy(grayx))))));
    }
    case fwidthx: {
      const half4 fragColor = fwidth(layer.sample(position))*15.;
      return opaque(fragColor);
    }
    case test:
     float3x3 Y;
     float3x3 Co;
     float3x3 Cr;

     const float2 inv_res = 1. /res;
      float2 uv = position / size;

     for (int i=0; i<3; i++) {
       for (int j=0; j<3; j++) {
         const float2 pos = uv + (float2(i, j) - 1) * inv_res;
         const half3 temp = YCoCr_mat * layer.sample(size * pos).xyz;
         Y[i][j] = temp.x;
         Co[i][j] = temp.y;
         Cr[i][j] = temp.z;
       }
     }

     const float3 xyz = float3(length(float2(dot(sobelx[0], Y[0]) + dot(sobelx[1], Y[1]) + dot(sobelx[2], Y[2]),
                                       dot(sobely[0], Y[0]) + dot(sobely[1], Y[1]) + dot(sobely[2], Y[2]))),
                         length(float2(dot(sobelx[0], Co[0]) + dot(sobelx[1], Co[1]) + dot(sobelx[2], Co[2]),
                                       dot(sobely[0], Co[0]) + dot(sobely[1], Co[1]) + dot(sobely[2], Co[2]))),
                         length(float2(dot(sobelx[0], Cr[0]) + dot(sobelx[1], Cr[1]) + dot(sobelx[2], Cr[2]),
                                       dot(sobely[0], Cr[0]) + dot(sobely[1], Cr[1]) + dot(sobely[2], Cr[2]))));

     return opaque(saturate(xyz));
   }


   const float ls = length(sum);
   const half3 mm = half3( step(args->threshold, ls) * ls);
   const half3 mx = mm * (args->image ? pix : 1);
   return opaque( mx);
 }


 // =================================================================

