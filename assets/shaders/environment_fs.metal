#pragma clang diagnostic ignored "-Wmissing-prototypes"

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct LightParams
{
    float tex_width;
    float tex_height;
    float ambient_xy_angle;
    float ambient_z_angle;
    float shadow_r;
    float shadow_g;
    float shadow_b;
    float shadow_steps;
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

#line 37 ""
static inline __attribute__((always_inline))
float2 getTargetTexCoords(thread const float& x_step, thread const float& y_step, thread const float& xy_angle, thread const float& h)
{
#line 37 ""
#line 38 ""
    return float2((cos(radians(xy_angle)) * h) * x_step, (sin(radians(xy_angle)) * h) * y_step);
}

#line 33 ""
static inline __attribute__((always_inline))
bool approx(thread const float& a, thread const float& b)
{
#line 33 ""
    return abs(b - a) < 0.00999999977648258209228515625;
}

#line 48 ""
static inline __attribute__((always_inline))
float4 shadow(thread const float& xy_angle, thread const float& z_angle, thread const float2& tex_coord, thread const float& stp, thread const float& shadow_steps, thread const float& tex_step_x, thread const float& tex_step_y, thread const float4& shadow_color, thread const float4& vert_color, thread texture2d<float> height_tex, thread const sampler height_texSmplr)
{
#line 48 ""
    float4 _92 = height_tex.sample(height_texSmplr, tex_coord);
    float _95 = _92.x;
#line 50 ""
    for (int i = 0; i < int(shadow_steps); i++)
    {
        float param = tex_step_x;
        float param_1 = tex_step_y;
        float param_2 = xy_angle;
        float param_3 = float(i);
        float4 _123 = height_tex.sample(height_texSmplr, (tex_coord + getTargetTexCoords(param, param_1, param_2, param_3)));
        float _124 = _123.x;
#line 53 ""
        float param_4 = tex_step_x;
        float param_5 = tex_step_y;
        float param_6 = xy_angle;
        float param_7 = float(i);
        if (_124 > _95)
        {
            float param_8 = (distance(tex_coord, tex_coord + getTargetTexCoords(param_4, param_5, param_6, param_7)) * tan(radians(z_angle))) + _95;
            float param_9 = _124;
            if (approx(param_8, param_9))
            {
#line 59 ""
                return shadow_color * vert_color;
            }
        }
    }
#line 63 ""
    return vert_color;
}

#line 68 ""
static inline __attribute__((always_inline))
float4 effect(thread const texture2d<float> tex, thread const sampler texSmplr, thread const float2& tex_coord, thread const float4& vert_color, thread texture2d<float> height_tex, thread const sampler height_texSmplr, constant LightParams& v_174, thread texture2d<float> light_tex, thread const sampler light_texSmplr)
{
#line 68 ""
    float _178 = 1.0 / v_174.tex_width;
#line 69 ""
    float _182 = 1.0 / v_174.tex_height;
#line 75 ""
#line 77 ""
    float param = v_174.ambient_xy_angle;
    float param_1 = v_174.ambient_z_angle;
    float2 param_2 = tex_coord;
    float param_3 = sqrt((_178 * _178) + (_182 * _182));
    float param_4 = v_174.shadow_steps;
    float param_5 = _178;
    float param_6 = _182;
    float4 param_7 = float4(v_174.shadow_r, v_174.shadow_g, v_174.shadow_b, 1.0);
    float4 param_8 = vert_color;
#line 78 ""
    return shadow(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, height_tex, height_texSmplr) + light_tex.sample(light_texSmplr, tex_coord);
}

#line 15 ""
fragment main0_out main0(main0_in in [[stage_in]], constant LightParams& v_174 [[buffer(0)]], texture2d<float> main_tex [[texture(0)]], texture2d<float> height_tex [[texture(1)]], texture2d<float> light_tex [[texture(2)]], sampler main_texSmplr [[sampler(0)]], sampler height_texSmplr [[sampler(1)]], sampler light_texSmplr [[sampler(2)]])
{
    main0_out out = {};
#line 15 ""
    float2 param = in.uv_out;
    float4 param_1 = in.color_out;
    out.frag_color = effect(main_tex, main_texSmplr, param, param_1, height_tex, height_texSmplr, v_174, light_tex, light_texSmplr);
    return out;
}

