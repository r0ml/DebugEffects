// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2025

#include <metal_stdlib>
#include "support.h"

using namespace metal;


colorEffect(vignette03) {
  const float boost = mouse.x < 0.01 ? 1.5 : mouse.x * 2.0;
  const float reduction = mouse.y < 0.01 ? 2.0 : mouse.y * 4.0;
  const half3 col = currentColor.rgb;
  const float vignette = distance( 0.5, position / size);
  return opaque( col * ( boost - vignette * reduction) );
}

// =================================================================

colorEffect(vignette04) {
  const float2 uv = position / size;
  const half3 col = currentColor.rgb;
  const half dist = distance(uv, float2(0.5));
  const half falloff = mouse.y < 0.01 ? 0.1 : mouse.y;
  const half amount = mouse.x < 0.01 ? 1.0 : mouse.x ;
  return opaque( col * smoothstep(half(0.8), half(falloff * 0.8), dist * (amount + falloff)));
}

// =================================================================

colorEffect(shadows01) {
  const float2 d = nodeAspect(size) * (position / size - mouse);
  const float2 s = .15;
  const float r = dot(d, d)/dot(s,s);
  return opaque(currentColor.rgb * (1.5 - r) );
}

// =================================================================

colorEffect(solarization) {
  const half3 threshold = { 1, 0.92, 0.1 };
  const float m = mouse.x * size.x ;
  
  const float line = smoothstep(0, 1 , abs(m - position.x));
  const bool3 cfb = currentColor.xyz < threshold;
  const half3 cf =  half3(cfb) + sign(0.5 - half3(cfb) ) * currentColor.xyz;
  const half3 cr = line * mix(cf, currentColor.xyz, position.x < m);
  return opaque(cr);
}

// =================================================================

