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

#line 60 ""
static inline __attribute__((always_inline))
float2 interpolate(thread const float2& tex_coord, thread const int2& tex_size, thread const float& texelsPerPixel)
{
#line 60 ""
    float2 _120 = tex_coord * float2(tex_size);
    float2 _123 = fract(_120);
    return (floor(_120) + (fast::clamp(_123 / float2(texelsPerPixel), float2(0.0), float2(0.5)) + fast::clamp(((_123 - float2(1.0)) / float2(texelsPerPixel)) + float2(0.5), float2(0.0), float2(0.5)))) / float2(tex_size);
}

#line 32 ""
static inline __attribute__((always_inline))
float4 tiltshift(thread const texture2d<float> tex, thread const sampler texSmplr, thread const float2& tex_coord)
{
#line 32 ""
    float _58 = pow((tex_coord.y * 2.0) - 1.0, 2.0);
#line 35 ""
    float4 blurred = float4(0.0, 0.0, 0.0, 1.0);
#line 38 ""
    for (float offsX = -1.0; offsX <= 1.0; offsX += 1.0)
    {
#line 39 ""
        for (float offsY = -1.0; offsY <= 1.0; offsY += 1.0)
        {
#line 42 ""
#line 45 ""
            float2 _179 = tex_coord;
            _179.x = tex_coord.x + ((offsX * _58) * 0.0040000001899898052215576171875);
#line 46 ""
            float2 _182 = _179;
            _182.y = tex_coord.y + ((offsY * _58) * 0.0040000001899898052215576171875);
#line 49 ""
            blurred += tex.sample(texSmplr, _182);
        }
    }
#line 55 ""
    float4 _111 = blurred;
    float4 _113 = _111 * float4(0.111111111938953399658203125);
    blurred = _113;
    return _113;
}

#line 69 ""
static inline __attribute__((always_inline))
float4 effect(thread const texture2d<float> tex, thread const sampler texSmplr, thread const float2& tex_coord, thread const float4& vert_color)
{
#line 69 ""
#line 72 ""
    float2 param = tex_coord;
    int2 param_1 = int2(tex.get_width(), tex.get_height());
    float param_2 = 8.0;
    float2 param_3 = interpolate(param, param_1, param_2);
    return tiltshift(tex, texSmplr, param_3) * vert_color;
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

