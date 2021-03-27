#pragma clang diagnostic ignored "-Wmissing-prototypes"

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct PostProcessingParams
{
    float tiltshift_amount;
    float bloom_amount;
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

#line 75 ""
static inline __attribute__((always_inline))
float2 interpolate(thread const float2& tex_coord, thread const int2& tex_size, thread const float& texelsPerPixel)
{
#line 75 ""
    float2 _142 = tex_coord * float2(tex_size);
    float2 _145 = fract(_142);
    return (floor(_142) + (fast::clamp(_145 / float2(texelsPerPixel), float2(0.0), float2(0.5)) + fast::clamp(((_145 - float2(1.0)) / float2(texelsPerPixel)) + float2(0.5), float2(0.0), float2(0.5)))) / float2(tex_size);
}

#line 31 ""
static inline __attribute__((always_inline))
float4 bloom(thread const texture2d<float> tex, thread const sampler texSmplr, thread const float2& tex_coord)
{
#line 31 ""
    return tex.sample(texSmplr, tex_coord);
}

#line 35 ""
static inline __attribute__((always_inline))
float4 tiltshift(thread const texture2d<float> tex, thread const sampler texSmplr, thread const float2& tex_coord, constant PostProcessingParams& v_55)
{
#line 35 ""
#line 47 ""
    float _81 = pow((tex_coord.y * 2.0) - 1.0, 2.0) * v_55.tiltshift_amount;
#line 50 ""
    float4 blurred = float4(0.0, 0.0, 0.0, 1.0);
#line 53 ""
    for (float offsX = -1.0; offsX <= 1.0; offsX += 1.0)
    {
#line 54 ""
        for (float offsY = -1.0; offsY <= 1.0; offsY += 1.0)
        {
#line 57 ""
#line 60 ""
            float2 _213 = tex_coord;
            _213.x = tex_coord.x + ((offsX * _81) * 0.0040000001899898052215576171875);
#line 61 ""
            float2 _216 = _213;
            _216.y = tex_coord.y + ((offsY * _81) * 0.0040000001899898052215576171875);
#line 64 ""
            blurred += tex.sample(texSmplr, _216);
        }
    }
#line 70 ""
    float4 _133 = blurred;
    float4 _135 = _133 * float4(0.111111111938953399658203125);
    blurred = _135;
    return _135;
}

#line 84 ""
static inline __attribute__((always_inline))
float4 effect(thread const texture2d<float> tex, thread const sampler texSmplr, thread const float2& tex_coord, thread const float4& vert_color, constant PostProcessingParams& v_55, thread texture2d<float> emission_tex, thread const sampler emission_texSmplr, thread texture2d<float> environment_texture, thread const sampler environment_textureSmplr)
{
#line 84 ""
#line 87 ""
    float2 param = tex_coord;
    int2 param_1 = int2(tex.get_width(), tex.get_height());
    float param_2 = 8.0;
    float2 _189 = interpolate(param, param_1, param_2);
    float2 param_3 = _189;
    float2 param_4 = _189;
    float2 param_5 = _189;
    return (tiltshift(tex, texSmplr, param_5, v_55) * tiltshift(environment_texture, environment_textureSmplr, param_4, v_55)) + bloom(emission_tex, emission_texSmplr, param_3);
}

#line 15 ""
fragment main0_out main0(main0_in in [[stage_in]], constant PostProcessingParams& v_55 [[buffer(0)]], texture2d<float> main_tex [[texture(0)]], texture2d<float> emission_tex [[texture(1)]], texture2d<float> environment_texture [[texture(2)]], sampler main_texSmplr [[sampler(0)]], sampler emission_texSmplr [[sampler(1)]], sampler environment_textureSmplr [[sampler(2)]])
{
    main0_out out = {};
#line 15 ""
    float2 param = in.uv_out;
    float4 param_1 = in.color_out;
    out.frag_color = effect(main_tex, main_texSmplr, param, param_1, v_55, emission_tex, emission_texSmplr, environment_texture, environment_textureSmplr);
    return out;
}

