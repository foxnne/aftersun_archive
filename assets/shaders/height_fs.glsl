#version 330

uniform sampler2D main_tex;

layout(location = 0) out vec4 frag_color;
in vec2 uv_out;
in vec4 color_out;
in vec4 options_out;

vec4 height(sampler2D tex, vec2 tex_coord, vec4 vert_color, float height_1)
{
    vec4 _45 = texture(tex, tex_coord);
    float _52 = (_45.x * 255.0) + height_1;
    float _56 = floor(_52 * 0.0039215688593685626983642578125);
    return vec4((_52 - _56) * 0.0039215688593685626983642578125, _56 * 0.0039215688593685626983642578125, 0.0, _45.w);
}

void main()
{
    vec2 param = uv_out;
    vec4 param_1 = color_out;
    float param_2 = options_out.x;
    frag_color = height(main_tex, param, param_1, param_2);
}

