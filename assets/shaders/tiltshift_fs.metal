#pragma clang diagnostic ignored "-Wmissing-prototypes"

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct TiltshiftParams
{
    float blur_amount;
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

#line 25 ""
static inline __attribute__((always_inline))
float4 effect(thread const texture2d<float> tex, thread const sampler texSmplr, thread const float2& tex_coord, thread const float4& vert_color, constant TiltshiftParams& v_37)
{
#line 25 ""
#line 37 ""
    float _55 = pow((tex_coord.y * 2.0) - 1.0, 2.0) * v_37.blur_amount;
#line 40 ""
    float4 blurred = float4(0.0, 0.0, 0.0, 1.0);
#line 43 ""
    for (float offsX = -1.0; offsX <= 1.0; offsX += 1.0)
    {
#line 44 ""
        for (float offsY = -1.0; offsY <= 1.0; offsY += 1.0)
        {
#line 47 ""
#line 50 ""
            float2 _114 = tex_coord;
            _114.x = tex_coord.x + ((offsX * _55) * 0.0030000000260770320892333984375);
#line 51 ""
            float2 _117 = _114;
            _117.y = tex_coord.y + ((offsY * _55) * 0.0030000000260770320892333984375);
#line 54 ""
            blurred += tex.sample(texSmplr, _117);
        }
    }
#line 60 ""
    float4 _107 = blurred;
    float4 _109 = _107 * float4(0.111111111938953399658203125);
    blurred = _109;
    return _109;
}

#line 15 ""
fragment main0_out main0(main0_in in [[stage_in]], constant TiltshiftParams& v_37 [[buffer(0)]], texture2d<float> main_tex [[texture(0)]], sampler main_texSmplr [[sampler(0)]])
{
    main0_out out = {};
#line 15 ""
    float2 param = in.uv_out;
    float4 param_1 = in.color_out;
    out.frag_color = effect(main_tex, main_texSmplr, param, param_1, v_37);
    return out;
}

