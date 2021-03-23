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

#line 21 ""
static inline __attribute__((always_inline))
int max3(thread const float3& channels)
{
#line 21 ""
    return int(fast::max(channels.z, fast::max(channels.y, channels.x)));
}

#line 26 ""
static inline __attribute__((always_inline))
float2 paletteCoord(thread const float3& base, thread const float3& vert)
{
#line 26 ""
#line 33 ""
#line 28 ""
#line 30 ""
#line 32 ""
    float3 param = float3(fast::clamp((base.x * vert.x) * 65025.0, 0.0, 1.0), fast::clamp((base.y * vert.y) * 65025.0, 0.0, 1.0) * 2.0, fast::clamp((base.z * vert.z) * 65025.0, 0.0, 1.0) * 3.0);
    uint _99 = uint4(2u, 0u, 1u, 2u)[max3(param)];
    return float2(base[_99], vert[_99]);
}

#line 40 ""
static inline __attribute__((always_inline))
float4 effect(thread const texture2d<float> tex, thread const sampler texSmplr, thread const float2& tex_coord, thread const float4& vert_color, thread texture2d<float> palette_tex, thread const sampler palette_texSmplr)
{
#line 40 ""
    float4 _112 = tex.sample(texSmplr, tex_coord);
#line 41 ""
#line 42 ""
    float3 param = _112.xyz;
    float3 param_1 = (vert_color.xyz * 255.0) / float3(float(int2(palette_tex.get_width(), palette_tex.get_height()).y - 1));
    return (palette_tex.sample(palette_texSmplr, paletteCoord(param, param_1)) * _112.w) * vert_color.w;
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

