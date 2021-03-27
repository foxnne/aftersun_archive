#pragma clang diagnostic ignored "-Wmissing-prototypes"

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct LightParams
{
    float tex_width;
    float tex_height;
    float sun_xy_angle;
    float sun_z_angle;
    float shadow_r;
    float shadow_g;
    float shadow_b;
    float max_shadow_steps;
    float max_shadow_height;
    float shadow_fade;
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

// Implementation of the GLSL radians() function
template<typename T>
inline T radians(T d)
{
    return d * T(0.01745329251);
}

#line 34 ""
static inline __attribute__((always_inline))
float2 extrude(thread const float2& other, thread const float& angle, thread const float& len)
{
#line 34 ""
#line 35 ""
#line 36 ""
    return float2(other.x + (len * cos(radians(angle))), other.y + (len * sin(radians(angle))));
}

#line 40 ""
static inline __attribute__((always_inline))
float getHeightAt(thread const float2& texCoord, thread const float& xyAngle, thread const float& dist, thread texture2d<float> height_tex, thread const sampler height_texSmplr)
{
#line 40 ""
    float2 param = texCoord;
    float param_1 = xyAngle;
    float param_2 = dist;
#line 41 ""
    return height_tex.sample(height_texSmplr, extrude(param, param_1, param_2)).x;
}

#line 46 ""
static inline __attribute__((always_inline))
float getTraceHeight(thread const float& height, thread const float& zAngle, thread const float& dist)
{
#line 46 ""
    return (dist * tan(radians(zAngle))) + height;
}

#line 54 ""
static inline __attribute__((always_inline))
float4 shadow(thread const float& xy_angle, thread const float& z_angle, thread const float2& tex_coord, thread const float& stp, thread const float& max_shadow_steps, thread const float& max_shadow_height, thread const float& shadow_fade, thread const float4& shadow_color, thread const float4& vert_color, thread texture2d<float> height_tex, thread const sampler height_texSmplr)
{
#line 54 ""
    float4 _119 = height_tex.sample(height_texSmplr, tex_coord);
    float _120 = _119.x;
#line 56 ""
    for (int i = 0; float(i) < max_shadow_steps; i++)
    {
#line 57 ""
        float _139 = stp * float(i);
#line 58 ""
        float2 param = tex_coord;
        float param_1 = xy_angle;
        float param_2 = _139;
        float _147 = getHeightAt(param, param_1, param_2, height_tex, height_texSmplr);
        bool _150 = _147 > _120;
        bool _160;
        if (_150)
        {
            _160 = (_147 - _120) < (max_shadow_height * stp);
        }
        else
        {
            _160 = _150;
        }
        if (_160)
        {
            float param_3 = _120;
            float param_4 = z_angle;
            float param_5 = _139;
            if (getTraceHeight(param_3, param_4, param_5) < _147)
            {
#line 63 ""
                float _179 = _139 * shadow_fade;
                return fast::clamp(shadow_color + float4(_179, _179, _179, _139 * shadow_fade), float4(0.0), float4(1.0)) * vert_color;
            }
        }
    }
#line 67 ""
    return vert_color;
}

#line 74 ""
static inline __attribute__((always_inline))
float4 effect(thread const texture2d<float> tex, thread const sampler texSmplr, thread const float2& tex_coord, thread const float4& vert_color, thread texture2d<float> height_tex, thread const sampler height_texSmplr, constant LightParams& v_207, thread texture2d<float> light_tex, thread const sampler light_texSmplr)
{
#line 74 ""
#line 76 ""
    float param = v_207.sun_xy_angle;
    float param_1 = v_207.sun_z_angle;
    float2 param_2 = tex_coord;
    float param_3 = 1.0 / v_207.tex_height;
    float param_4 = v_207.max_shadow_steps;
    float param_5 = v_207.max_shadow_height;
    float param_6 = v_207.shadow_fade;
    float4 param_7 = float4(v_207.shadow_r, v_207.shadow_g, v_207.shadow_b, 1.0);
    float4 param_8 = vert_color;
#line 77 ""
    return shadow(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, height_tex, height_texSmplr) + light_tex.sample(light_texSmplr, tex_coord);
}

#line 15 ""
fragment main0_out main0(main0_in in [[stage_in]], constant LightParams& v_207 [[buffer(0)]], texture2d<float> main_tex [[texture(0)]], texture2d<float> height_tex [[texture(1)]], texture2d<float> light_tex [[texture(2)]], sampler main_texSmplr [[sampler(0)]], sampler height_texSmplr [[sampler(1)]], sampler light_texSmplr [[sampler(2)]])
{
    main0_out out = {};
#line 15 ""
    float2 param = in.uv_out;
    float4 param_1 = in.color_out;
    out.frag_color = effect(main_tex, main_texSmplr, param, param_1, height_tex, height_texSmplr, v_207, light_tex, light_texSmplr);
    return out;
}

