#pragma clang diagnostic ignored "-Wmissing-prototypes"

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct LightParams
{
    float tex_width;
    float tex_height;
    float sun_XYAngle;
    float sun_ZAngle;
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

#line 26 ""
static inline __attribute__((always_inline))
float2 extrude(thread const float2& other, thread const float& angle, thread const float& len)
{
#line 26 ""
#line 27 ""
#line 28 ""
    return float2(other.x + (len * cos(radians(angle))), other.y + (len * sin(radians(angle))));
}

#line 32 ""
static inline __attribute__((always_inline))
float getHeightAt(thread const float2& texCoord, thread const float& xyAngle, thread const float& dist, thread const texture2d<float> heightMap, thread const sampler heightMapSmplr)
{
#line 32 ""
    float2 param = texCoord;
    float param_1 = xyAngle;
    float param_2 = dist;
#line 33 ""
    return heightMap.sample(heightMapSmplr, extrude(param, param_1, param_2)).x;
}

#line 38 ""
static inline __attribute__((always_inline))
float getTraceHeight(thread const float& height, thread const float& zAngle, thread const float& dist)
{
#line 38 ""
    return (dist * tan(radians(zAngle))) + height;
}

#line 46 ""
static inline __attribute__((always_inline))
bool isInShadow(thread const float& xyAngle, thread const float& zAngle, thread const texture2d<float> heightMap, thread const sampler heightMapSmplr, thread const float2& texCoord, thread const float& stp)
{
#line 46 ""
    float4 _116 = heightMap.sample(heightMapSmplr, texCoord);
    float _117 = _116.x;
#line 48 ""
    for (int i = 0; i < 200; i++)
    {
#line 49 ""
        float _134 = stp * float(i);
#line 50 ""
        float2 param = texCoord;
        float param_1 = xyAngle;
        float param_2 = _134;
        float _142 = getHeightAt(param, param_1, param_2, heightMap, heightMapSmplr);
        bool _145 = _142 > _117;
        bool _155;
        if (_145)
        {
            _155 = (_142 - _117) < (50.0 * stp);
        }
        else
        {
            _155 = _145;
        }
        if (_155)
        {
            float param_3 = _117;
            float param_4 = zAngle;
            float param_5 = _134;
            if (getTraceHeight(param_3, param_4, param_5) < _142)
            {
#line 55 ""
                return true;
            }
        }
    }
#line 59 ""
    return false;
}

#line 68 ""
static inline __attribute__((always_inline))
float4 effect(thread const texture2d<float> tex, thread const sampler texSmplr, thread const float2& tex_coord, thread const float4& vert_color, constant LightParams& v_182, thread texture2d<float> height_tex, thread const sampler height_texSmplr)
{
#line 68 ""
    float param = v_182.sun_XYAngle;
    float param_1 = v_182.sun_ZAngle;
    float2 param_2 = tex_coord;
    float param_3 = 1.0 / v_182.tex_height;
    if (isInShadow(param, param_1, height_tex, height_texSmplr, param_2, param_3))
    {
#line 69 ""
        return float4(0.800000011920928955078125, 0.800000011920928955078125, 0.89999997615814208984375, 1.0);
    }
#line 71 ""
    return vert_color;
}

#line 15 ""
fragment main0_out main0(main0_in in [[stage_in]], constant LightParams& v_182 [[buffer(0)]], texture2d<float> main_tex [[texture(0)]], texture2d<float> height_tex [[texture(1)]], sampler main_texSmplr [[sampler(0)]], sampler height_texSmplr [[sampler(1)]])
{
    main0_out out = {};
#line 15 ""
    float2 param = in.uv_out;
    float4 param_1 = in.color_out;
    out.frag_color = effect(main_tex, main_texSmplr, param, param_1, v_182, height_tex, height_texSmplr);
    return out;
}

