#pragma clang diagnostic ignored "-Wmissing-prototypes"

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct main0_out
{
    float4 frag_color [[color(0)]];
};

struct main0_in
{
    float2 uv_out [[user(locn0)]];
    float4 color_out [[user(locn1)]];
};

#line 20 ""
static inline __attribute__((always_inline))
float4 effect(thread const texture2d<float> tex, thread const sampler texSmplr, thread const float2& tex_coord, thread const float4& vert_color)
{
#line 20 ""
    float2 _42 = tex_coord * float2(int2(tex.get_width(), tex.get_height()));
    float2 _48 = fract(_42);
#line 26 ""
    return tex.sample(texSmplr, ((floor(_42) + (fast::clamp(_48 * float2(0.125), float2(0.0), float2(0.5)) + fast::clamp(((_48 - float2(1.0)) * float2(0.125)) + float2(0.5), float2(0.0), float2(0.5)))) / float2(int2(tex.get_width(), tex.get_height())))) * vert_color;
}

#line 15 ""
fragment main0_out main0(main0_in in [[stage_in]], texture2d<float> main_tex [[texture(0)]], sampler main_texSmplr [[sampler(0)]])
{
    main0_out out = {};
#line 15 ""
    float2 param = in.uv_out;
    float4 param_1 = in.color_out;
    out.frag_color = effect(main_tex, main_texSmplr, param, param_1);
    return out;
}

