#version 330

uniform vec4 FinalizeParams[1];
uniform sampler2D main_tex;
uniform sampler2D bloom_t;
uniform sampler2D envir_t;

layout(location = 0) out vec4 frag_color;
in vec2 uv_out;
in vec4 color_out;

vec2 interpolate(vec2 tex_coord, vec2 tex_size, float texelsPerPixel)
{
    vec2 _43 = tex_coord * tex_size;
    vec2 _46 = fract(_43);
    return (floor(_43) + (clamp(_46 / vec2(texelsPerPixel), vec2(0.0), vec2(0.5)) + clamp(((_46 - vec2(1.0)) / vec2(texelsPerPixel)) + vec2(0.5), vec2(0.0), vec2(0.5)))) / tex_size;
}

vec4 effect(sampler2D tex, vec2 tex_coord, vec4 vert_color)
{
    vec2 param = tex_coord;
    vec2 param_1 = vec2(FinalizeParams[0].y, FinalizeParams[0].z);
    float param_2 = max(1.0 / FinalizeParams[0].y, 1.0 / FinalizeParams[0].z);
    vec2 _109 = interpolate(param, param_1, param_2);
    return (texture(tex, _109) * texture(envir_t, _109)) + texture(bloom_t, tex_coord);
}

void main()
{
    vec2 param = uv_out;
    vec4 param_1 = color_out;
    frag_color = effect(main_tex, param, param_1);
}

