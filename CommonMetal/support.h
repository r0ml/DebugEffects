// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2025

#ifndef support_h
#define support_h

#include <SwiftUI/SwiftUI_Metal.h>

namespace global {
/*
  extern constant uint KEY_LEFT;
  extern constant uint KEY_UP;
  extern constant uint KEY_RIGHT;
  extern constant uint KEY_DOWN;
 */
  extern constant float e;
  extern constant float tau;
  extern constant float pi;
  extern constant float epsilon;
  extern constant float goldenRatio;
  extern constant float PI;
  extern constant float TAU;
  extern constant float E;
  extern constant float phi;
  extern constant float PHI;
}

using namespace metal;

#include <metal_stdlib>
// #include "constants.h"

float2 worldCoordAdjusted(float2 position, float2 size);
float2 worldCoord(float2 position, float2 size);
float2 toWorld(float2 x);  // convert texture coordinates to world coordinates

float2 nodeAspect(float2 size);

float fix_atan2(float, float);

template <typename T>
static T fix_sin(T x) {
  return sin(fmod(x, M_PI_F * 2));
}

template <typename T>
static T fix_cos(T x) {
  return cos(fmod(x, M_PI_F * 2));
}

float2x2 rot2d(float);
float2x2 rot2dpi(float);

float3x3 rotate( float3 axis, float angle);
float3x3 rotX( float angle);
float3x3 rotY( float angle);
float3x3 rotZ( float angle);

float2x2 makeMat(float4);

// convert rgb to grayscale
float grayscale(const half3); // rgb to yiq
float luminance(const half3); // srgb
half3 rgb2hsv(const half3);
half3 hsv2rgb(const half3);
half3 hsl2rgb(const half3);

half3 gammaEncode(const half3 c);
half4 gammaEncode(const half4 c);
half3 gammaDecode(const half3 c);
half4 gammaDecode(const half4 c);

half4 opaque(const half c);
half4 opaque(const half3 c);
half4 opaque(const half a, const half b, const half c);
half4 opaque(const half4 c);
half4 opaque(const float3 c);
half4 opaque(const float4 c);

// ==========================================================
// random numbers
// =========================== ===============================
float4 rand4(float2);
float3 rand3(float2, float = 0);
float2 rand2(float2);

// float rand(float2);
float rand( float n);
float rand( float2 n);
float rand( float3 n);


float4 prand4(float2, float2);
float3 prand3(float2, float2);
float2 prand2(float2, float2);
float prand(float2, float2);

float3 interporand(float2 pos, float reso = 256);

// ================================================================================
// Useful utilities
// ================================================================================

using namespace global;

// equivalent to:
//  (acos(cos(x))/PI) if x is divided by Pi

float polySmin( float a, float b, float k );
float polySmax( float a, float b, float k );
float expSmin(float a, float b, float k);
float expSmax(float a, float b, float k);
float commSmin(float a, float b, float k);
float commSmax(float a, float b, float k);

float2 PixToHex(float2 p);
float2 HexToPix(float2 h);
float3 HexGrid (float2 p);
float HexEdgeDist(float2 p);

half3 blackbody(float Temp);
half3 BlackBody( float t);

// ============================================

float noisePerlin(float  x);
float noisePerlin(float2 x);
float noisePerlin(float3 x);

float4 hash4( float n);

class fbm {
public:
  float octaves = 5;
  float lacunarity = 2;
  float gain = 0.5;
  float frequency = 1;
  float amplitude = 1;
  float2 shift = 0;
  float rotation = 0;
  
  // fractal Brownian motion
  float emit(const float2 x);
};

// -----------------------------------------------
// Colors

typedef half3 Color;

Color palette( float t, Color a, Color b, Color c, Color d );

float vignette( float2 uv, float p);

// Normalized Device Coordinate given Viewport coordinate and Viewport size

float2 yflip(float2 x);

template <typename T>
static T mod(T x, float y) {
  return x - y * floor(x/y);
}

template <typename T>
static T mod(T x, typename enable_if<true,T>::type y) {
  return x - y * floor(x/y);
}

template <typename T>
static T radians(T x) {
  return M_PI_F * x / 180.0;
}

float prod(float2 x);
half prod(half2 x);
float prod(float3 x);
half prod(half3 x);
float prod(float4 x);
half prod(half4 x);

float4x4 inverse(float4x4 mm);
float3x3 inverse(float3x3 mm);
float2x2 inverse(float2x2 mm);

#include <SceneKit/scn_metal>

struct VertexOut {
  float4 where [[position]];   // this is in the range -1 -> 1 in the vertex shader,  0 -> viewSize in the fragment shader
  float4 color;
  float2 texCoords;
  float3 normal;
};

typedef struct {
  float4x4 modelTransform;
  float4x4 inverseModelTransform;
  float4x4 modelViewTransform;
  float4x4 inverseModelViewTransform;
  float4x4 normalTransform; // Inverse transpose of modelViewTransform
  float4x4 modelViewProjectionTransform;
  float4x4 inverseModelViewProjectionTransform;
  float2x3 boundingBox;
  float2x3 worldBoundingBox;
} PerNodeData;

typedef struct {
  float2 mouse;
  float2 size;
} MyData;

typedef float4 FragmentOutput;

#define colorEffect(a) \
\
half4 a##_private(const float2 position, const half4 currentColor, const float time, const float2 size, const float2 mouse, texture2d<half, access::sample> tex, device const void *arg, int arg_size); \
\
\
fragment FragmentOutput a##_ColorFragment(VertexOut vertexOut [[stage_in]], \
                                      texture2d<float> currentTexture [[texture(0)]], \
                                    constant SCNSceneBuffer& scn_frame [[buffer(0)]], \
                                    constant PerNodeData& scn_node [[buffer(1)]], \
                                    constant MyData& myData [[buffer(2)]], \
                                    texture2d<half> otherTexture [[texture(1)]], \
                                    device const void * arg [[buffer(9)]] \
                                    ) { \
  constexpr sampler s = sampler(coord::normalized, address::clamp_to_edge, filter::linear); \
  const float2 size = 1 / scn_frame.inverseResolution; \
  const float2 mouse = myData.mouse; \
  float4 currentColor = currentTexture.sample(s, vertexOut.texCoords); \
\
  half4 res = a##_private(vertexOut.where.xy, half4(currentColor), scn_frame.time, size, mouse, otherTexture, arg, 90909 ); \
  return float4(res); \
} \
\
[[stitchable]] \
half4 a(const float2 position, const half4 currentColor, const float time, const float2 size, const float2 mouse, texture2d<half, access::sample> tex, device const void *arg, int arg_size) { \
  return a##_private(position, currentColor, time, size, mouse, tex, arg, arg_size ); \
} \
\
half4 a##_private(const float2 position, const half4 currentColor, const float time, const float2 size, const float2 mouse, texture2d<half, access::sample> tex, device const void *arg, int arg_size)

// =============================================================================================================


#define layerEffect(a) \
\
half4 a##_LayerPrivate(const float2 position, const SwiftUI::Layer layer, const float time, const float2 size, const float2 mouse, texture2d<half, access::sample> tex, device const void *arg, int arg_size); \
\
\
fragment FragmentOutput a##_LayerFragment(VertexOut vertexOut [[stage_in]], \
                                    texture2d<float> currentTexture [[texture(0)]], \
/*                                    constant SwiftUI::Layer & layer [[buffer(8)]], */ \
                                    constant SCNSceneBuffer& scn_frame [[buffer(0)]], \
                                    constant PerNodeData& scn_node [[buffer(1)]], \
                                    constant MyData& myData [[buffer(2)]], \
                                    texture2d<half> otherTexture [[texture(1)]], \
                                    texture2d<half> baseTexture [[texture(2)]], \
                                    device const void * arg [[buffer(9)]] \
                                    ) { \
  const float2 size = 1 / scn_frame.inverseResolution; \
  const float2 mouse = myData.mouse; \
  SwiftUI::Layer layer; \
  layer.tex = baseTexture; \
  layer.info[0] = float2(scn_frame.inverseResolution.x, 0); \
  layer.info[1] = float2(0, scn_frame.inverseResolution.y); \
  layer.info[2] = 0; \
  layer.info[3] = 0.5 * scn_frame.inverseResolution; \
  layer.info[4] = 1 - 0.5 * scn_frame.inverseResolution; \
\
  half4 res = a##_LayerPrivate(vertexOut.where.xy, layer, scn_frame.time, size, mouse, otherTexture, arg, 90909 ); \
  return float4(res); \
} \
\
[[stitchable]] \
half4 a(const float2 position, const SwiftUI::Layer layer, const float time, const float2 size, const float2 mouse, texture2d<half, access::sample> tex, device const void *arg, int arg_size) { \
  return a##_LayerPrivate(position, layer, time, size, mouse, tex, arg, arg_size ); \
} \
\
half4 a##_LayerPrivate(const float2 position, const SwiftUI::Layer layer, const float time, const float2 size, const float2 mouse, texture2d<half, access::sample> tex, device const void *arg, int arg_size)


// ======================================================================================

#define distortionEffect(a) \
\
float2 a##_DistortPrivate(const float2 position, const float time, const float2 size, const float2 mouse, texture2d<half, access::sample> tex, device const void *arg, int arg_size); \
\
\
fragment FragmentOutput a##_DistortFragment(VertexOut vertexOut [[stage_in]], \
                                    texture2d<float> currentTexture [[texture(0)]], \
                                    constant SCNSceneBuffer& scn_frame [[buffer(0)]], \
                                    constant PerNodeData& scn_node [[buffer(1)]], \
                                    constant MyData& myData [[buffer(2)]], \
                                    texture2d<half> otherTexture [[texture(1)]], \
                                    device const void * arg [[buffer(9)]] \
                                    ) { \
  const float2 size = 1 / scn_frame.inverseResolution; \
  const float2 mouse = myData.mouse; \
\
  float2 res = a##_DistortPrivate(vertexOut.where.xy, scn_frame.time, size, mouse, otherTexture, arg, 90909 ); \
  float4 colx = currentTexture.read(uint2(mod(res, size))); \
  return float4(float3((half3(colx.rgb))), colx.w); \
} \
\
[[stitchable]] \
float2 a(const float2 position, const float time, const float2 size, const float2 mouse, texture2d<half, access::sample> tex, device const void *arg, int arg_size) { \
  return a##_DistortPrivate(position, time, size, mouse, tex, arg, arg_size ); \
} \
\
float2 a##_DistortPrivate(const float2 position, const float time, const float2 size, const float2 mouse, texture2d<half, access::sample> tex, device const void *arg, int arg_size)


#endif /* support_h */
