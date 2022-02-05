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

#line 27 ""
static inline __attribute__((always_inline))
float2 interpolate(thread const float2& tex_coord, thread const float2& tex_size, thread const float& texelsPerPixel)
{
#line 27 ""
    float2 _43 = tex_coord * tex_size;
    float2 _48 = fract(_43 * tex_size);
    return (floor(_43) + (fast::clamp(_48 / float2(texelsPerPixel), float2(0.0), float2(0.5)) + fast::clamp(((_48 - float2(1.0)) / float2(texelsPerPixel)) + float2(0.5), float2(0.0), float2(0.5)))) / tex_size;
}

#line 36 ""
static inline __attribute__((always_inline))
float4 effect(thread const texture2d<float> tex, thread const sampler texSmplr, thread const float2& tex_coord, thread const float4& vert_color, constant FinalizeParams& v_83, thread texture2d<float> envir_t, thread const sampler envir_tSmplr)
{
#line 36 ""
#line 37 ""
#line 39 ""
    float2 param = tex_coord;
    float2 param_1 = float2(v_83.tex_size_x, v_83.tex_size_y);
    float param_2 = v_83.texel_size;
    float2 _104 = interpolate(param, param_1, param_2);
#line 42 ""
#line 43 ""
    return tex.sample(texSmplr, _104) * envir_t.sample(envir_tSmplr, _104);
}

#line 15 ""
fragment main0_out main0(main0_in in [[stage_in]], constant FinalizeParams& v_83 [[buffer(0)]], texture2d<float> main_tex [[texture(0)]], texture2d<float> envir_t [[texture(1)]], sampler main_texSmplr [[sampler(0)]], sampler envir_tSmplr [[sampler(1)]])
{
    main0_out out = {};
#line 15 ""
    float2 param = in.uv_out;
    float4 param_1 = in.color_out;
    out.frag_color = effect(main_tex, main_texSmplr, param, param_1, v_83, envir_t, envir_tSmplr);
    return out;
}

