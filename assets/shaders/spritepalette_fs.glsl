#version 330

uniform sampler2D main_tex;
uniform sampler2D palette_tex;

layout(location = 0) out vec4 frag_color;
in vec2 uv_out;
in vec4 color_out;

int max3(vec3 channels)
{
    return int(max(channels.z, max(channels.y, channels.x)));
}

vec2 paletteCoord(vec4 base, vec4 vert)
{
    vec3 param = vec3(clamp((base.x * vert.x) * 65025.0, 0.0, 1.0), clamp((base.y * vert.y) * 65025.0, 0.0, 1.0) * 2.0, clamp((base.z * vert.z) * 65025.0, 0.0, 1.0) * 3.0);
    int _100 = clamp(max3(param) - 1, 0, 2);
    return vec2(base[_100], vert[_100]);
}

vec4 effect(sampler2D tex, vec2 tex_coord, vec4 vert_color)
{
    vec4 _113 = texture(tex, tex_coord);
    vec4 param = _113;
    vec4 param_1 = (vert_color * 255.0) / vec4(float(textureSize(palette_tex, 0).y - 1));
    return (texture(palette_tex, paletteCoord(param, param_1)) * _113.w) * vert_color.w;
}

void main()
{
    vec2 param = uv_out;
    vec4 param_1 = color_out;
    frag_color = effect(main_tex, param, param_1);
}

