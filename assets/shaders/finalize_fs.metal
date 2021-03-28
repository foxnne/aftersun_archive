#pragma clang diagnostic ignored "-Wmissing-prototypes"

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct FinalizeParams
{
    float texel_size;
    float tex_size_x;
    float tex_size_y;
};

struct main0_out
{
    float4 frag_color [[color(0)]];
};

struct main0_in
{
    float2 uv_out [[user(locn0)]];
    float4 color_out [[user(locn1)]];
};

#line 28 ""
static inline __attribute__((always_inline))
float2 interpolate(thread const float2& tex_coord, thread const float2& tex_size, thread const float& texelsPerPixel)
{
#line 28 ""
    float2 _43 = tex_coord * tex_size;
    float2 _46 = fract(_43);
    return (floor(_43) + (fast::clamp(_46 / float2(texelsPerPixel), float2(0.0), float2(0.5)) + fast::clamp(((_46 - float2(1.0)) / float2(texelsPerPixel)) + float2(0.5), float2(0.0), float2(0.5)))) / tex_size;
}

#line 37 ""
static inline __attribute__((always_inline))
float4 effect(thread const texture2d<float> tex, thread const sampler texSmplr, thread const float2& tex_coord, thread const float4& vert_color, constant FinalizeParams& v_81, thread texture2d<float> bloom_t, thread const sampler bloom_tSmplr, thread texture2d<float> envir_t, thread const sampler envir_tSmplr)
{
#line 37 ""
#line 38 ""
#line 40 ""
    float2 param = tex_coord;
    float2 param_1 = float2(v_81.tex_size_x, v_81.tex_size_y);
    float param_2 = v_81.texel_size;
    float2 _102 = interpolate(param, param_1, param_2);
#line 42 ""
#line 43 ""
#line 44 ""
    return (tex.sample(texSmplr, _102) * envir_t.sample(envir_tSmplr, _102)) + bloom_t.sample(bloom_tSmplr, tex_coord);
}

#line 15 ""
fragment main0_out main0(main0_in in [[stage_in]], constant FinalizeParams& v_81 [[buffer(0)]], texture2d<float> main_tex [[texture(0)]], texture2d<float> bloom_t [[texture(1)]], texture2d<float> envir_t [[texture(2)]], sampler main_texSmplr [[sampler(0)]], sampler bloom_tSmplr [[sampler(1)]], sampler envir_tSmplr [[sampler(2)]])
{
    main0_out out = {};
#line 15 ""
    float2 param = in.uv_out;
    float4 param_1 = in.color_out;
    out.frag_color = effect(main_tex, main_texSmplr, param, param_1, v_81, bloom_t, bloom_tSmplr, envir_t, envir_tSmplr);
    return out;
}

