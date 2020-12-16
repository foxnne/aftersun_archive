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
int max3(thread const float3& channels)
{
#line 20 ""
    return int(fast::max(channels.z, fast::max(channels.y, channels.x)));
}

#line 24 ""
static inline __attribute__((always_inline))
float2 paletteCoord(thread const float4& base, thread const float4& vert)
{
#line 24 ""
#line 28 ""
#line 25 ""
#line 26 ""
#line 27 ""
    float3 param = float3(fast::clamp((base.x * vert.x) * 65025.0, 0.0, 1.0), fast::clamp((base.y * vert.y) * 65025.0, 0.0, 1.0) * 2.0, fast::clamp((base.z * vert.z) * 65025.0, 0.0, 1.0) * 3.0);
    int _100 = clamp(max3(param) - 1, 0, 2);
    return float2(base[_100], vert[_100]);
}

#line 35 ""
static inline __attribute__((always_inline))
float4 effect(thread const texture2d<float> tex, thread const sampler texSmplr, thread const float2& tex_coord, thread const float4& vert_color, thread texture2d<float> palette_tex, thread const sampler palette_texSmplr)
{
#line 35 ""
    float4 _113 = tex.sample(texSmplr, tex_coord);
#line 36 ""
#line 37 ""
    float4 param = _113;
    float4 param_1 = (vert_color * 255.0) / float4(float(int2(palette_tex.get_width(), palette_tex.get_height()).y - 1));
    return (palette_tex.sample(palette_texSmplr, paletteCoord(param, param_1)) * _113.w) * vert_color.w;
}

#line 15 ""
fragment main0_out main0(main0_in in [[stage_in]], texture2d<float> main_tex [[texture(0)]], texture2d<float> palette_tex [[texture(1)]], sampler main_texSmplr [[sampler(0)]], sampler palette_texSmplr [[sampler(1)]])
{
    main0_out out = {};
#line 15 ""
    float2 param = in.uv_out;
    float4 param_1 = in.color_out;
    out.frag_color = effect(main_tex, main_texSmplr, param, param_1, palette_tex, palette_texSmplr);
    return out;
}

