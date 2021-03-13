#version 330

uniform sampler2D main_tex;

layout(location = 0) out vec4 frag_color;
in vec2 uv_out;
in vec4 color_out;

vec4 effect(sampler2D tex, vec2 tex_coord, vec4 vert_color)
{
    vec2 _44 = vec2(textureSize(tex, 0));
    vec2 _45 = tex_coord * _44;
    vec2 _51 = fract(_45);
    return texture(tex, (floor(_45) + (clamp(_51 * vec2(0.125), vec2(0.0), vec2(0.5)) + clamp(((_51 - vec2(1.0)) * vec2(0.125)) + vec2(0.5), vec2(0.0), vec2(0.5)))) / _44) * vert_color;
}

void main()
{
    vec2 param = uv_out;
    vec4 param_1 = color_out;
    frag_color = effect(main_tex, param, param_1);
}

