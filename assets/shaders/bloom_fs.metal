#pragma clang diagnostic ignored "-Wmissing-prototypes"
#pragma clang diagnostic ignored "-Wmissing-braces"

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

template<typename T, size_t Num>
struct spvUnsafeArray
{
    T elements[Num ? Num : 1];
    
    thread T& operator [] (size_t pos) thread
    {
        return elements[pos];
    }
    constexpr const thread T& operator [] (size_t pos) const thread
    {
        return elements[pos];
    }
    
    device T& operator [] (size_t pos) device
    {
        return elements[pos];
    }
    constexpr const device T& operator [] (size_t pos) const device
    {
        return elements[pos];
    }
    
    constexpr const constant T& operator [] (size_t pos) const constant
    {
        return elements[pos];
    }
    
    threadgroup T& operator [] (size_t pos) threadgroup
    {
        return elements[pos];
    }
    constexpr const threadgroup T& operator [] (size_t pos) const threadgroup
    {
        return elements[pos];
    }
};

struct BloomParams
{
    float horizontal;
    float tex_size_x;
    float tex_size_y;
};

constant spvUnsafeArray<float, 10> _101 = spvUnsafeArray<float, 10>({ 0.227026998996734619140625, 0.19459460675716400146484375, 0.121621601283550262451171875, 0.054053999483585357666015625, 0.01621600054204463958740234375, 0.0111343003809452056884765625, 0.008490200154483318328857421875, 0.0040293000638484954833984375, 0.0021293000318109989166259765625, 0.00011233999975956976413726806640625 });

struct main0_out
{
    float4 frag_color [[color(0)]];
};

struct main0_in
{
    float2 uv_out [[user(locn0)]];
    float4 color_out [[user(locn1)]];
};

#line 30 ""
static inline __attribute__((always_inline))
float4 effect(thread const texture2d<float> tex, thread const sampler texSmplr, thread const float2& tex_coord, thread const float4& vert_color, constant BloomParams& v_37)
{
#line 30 ""
    float2 _48 = float2(1.0) / float2(v_37.tex_size_x, v_37.tex_size_y);
#line 31 ""
    float3 result = tex.sample(texSmplr, tex_coord).xyz * 0.227026998996734619140625;
#line 32 ""
    if (v_37.horizontal > 0.0)
    {
#line 34 ""
        for (int i = 1; i < 10; i++)
        {
#line 36 ""
            float2 _86 = float2(_48.x * float(i), 0.0);
#line 37 ""
            result = (result + (tex.sample(texSmplr, (tex_coord + _86)).xyz * _101[i])) + (tex.sample(texSmplr, (tex_coord - _86)).xyz * _101[i]);
        }
    }
    else
    {
#line 42 ""
        for (int i_1 = 1; i_1 < 10; i_1++)
        {
#line 44 ""
            float2 _147 = float2(0.0, _48.y * float(i_1));
#line 45 ""
            result = (result + (tex.sample(texSmplr, (tex_coord + _147)).xyz * _101[i_1])) + (tex.sample(texSmplr, (tex_coord - _147)).xyz * _101[i_1]);
        }
    }
#line 49 ""
    return float4(result, 1.0);
}

#line 15 ""
fragment main0_out main0(main0_in in [[stage_in]], constant BloomParams& v_37 [[buffer(0)]], texture2d<float> main_tex [[texture(0)]], sampler main_texSmplr [[sampler(0)]])
{
    main0_out out = {};
#line 15 ""
    float2 param = in.uv_out;
    float4 param_1 = in.color_out;
    out.frag_color = effect(main_tex, main_texSmplr, param, param_1, v_37);
    return out;
}

