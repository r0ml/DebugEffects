// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2025

#define shaderName not_used
#include "support.h"

#include <metal_stdlib>
using namespace metal;

float sdSphere( float3 p, float radius, float3 origin ) {
  return distance(p, origin)-radius;
}

float sdBox( float3 p, float3 sides ) {
  float3 d = abs(p) - sides;
  return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}

float sdTorus( float3 p, float outerRadius, float innerRadius, float3 center ) {
  float2 q = float2(length(p.xz - center.xz)-outerRadius, p.y - center.y);
  return length(q)-innerRadius;
}

// n must be normalized
float sdPlane( float3 p, float4 n ) {
  return dot(p, normalize(n.xyz) ) + n.w;
}

// ------------------------------------------


float sdCircle (float2 p, float r, float2 origin) {
  return distance(p, origin) - r;
}

float sdSegment( float2 p, float2 a, float2 b ) {
  float2 pa = p-a, ba = b-a;
  float h = saturate( dot(pa,ba)/dot(ba,ba));
  return length( pa - ba*h );
}

// signed distance to a 2D triangle
float sdTriangle(float2 p, float2 p0, float2 p1, float2 p2 ) {
  float2 e0 = p1 - p0;
  float2 e1 = p2 - p1;
  float2 e2 = p0 - p2;

  float2 v0 = p - p0;
  float2 v1 = p - p1;
  float2 v2 = p - p2;

  float2 pq0 = v0 - e0*clamp( dot(v0,e0)/dot(e0,e0), 0.0, 1.0 );
  float2 pq1 = v1 - e1*clamp( dot(v1,e1)/dot(e1,e1), 0.0, 1.0 );
  float2 pq2 = v2 - e2*clamp( dot(v2,e2)/dot(e2,e2), 0.0, 1.0 );
    
  float s = e0.x*e2.y - e0.y*e2.x;
  float2 d = min( min( float2( dot( pq0, pq0 ), s*(v0.x*e0.y-v0.y*e0.x) ),
                      float2( dot( pq1, pq1 ), s*(v1.x*e1.y-v1.y*e1.x) )),
                      float2( dot( pq2, pq2 ), s*(v2.x*e2.y-v2.y*e2.x) ));
  return -sqrt(d.x)*sign(d.y);
}

// ------------------------------------------

// subtract the second thing from the second
float sdSubtract( float d1, float d2 ) {
  return max(-d2,d1);
}

// union of two shapes
float sdUnion( float d1, float d2 ) {
    return min(d1,d2);
}

float sdIntersect(float a, float b) {
  return max(a,b);
}

//======================================================

float3 opRep( float3 p, float3 c ) {
    return mod(p,c)-0.5*c;
}
