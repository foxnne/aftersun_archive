#version 330

uniform sampler2D main_tex;
uniform sampler2D height_tex;
uniform sampler2D palette_tex;

layout(location = 0) out vec4 frag_color_0;
in vec2 uv_out;
in vec4 color_out;
in vec4 options_out;
layout(location = 1) out vec4 frag_color_1;

int max3(vec3 channels)
{
    return int(max(channels.z, max(channels.y, channels.x)));
}

vec2 paletteCoord(vec3 base, vec3 vert)
{
    vec3 param = vec3(clamp((base.x * vert.x) * 65025.0, 0.0, 1.0), clamp((base.y * vert.y) * 65025.0, 0.0, 1.0) * 2.0, clamp((base.z * vert.z) * 65025.0, 0.0, 1.0) * 3.0);
    uint _121 = uvec4(2u, 0u, 1u, 2u)[max3(param)];
    return vec2(base[_121], vert[_121]);
}

vec4 effect(sampler2D tex, vec2 tex_coord, vec4 vert_color, float frag_mode)
{
    vec4 base_color = texture(tex, tex_coord);
    if (int(frag_mode) == 1)
    {
        vec3 param = base_color.xyz;
        vec3 param_1 = (vert_color.xyz * 255.0) / vec3(float(textureSize(palette_tex, 0).y - 1));
        base_color = texture(palette_tex, paletteCoord(param, param_1)) * base_color.w;
    }
    return base_color;
}

vec4 height(sampler2D tex, vec2 tex_coord, vec4 vert_color, float height_1)
{
    vec4 _181 = texture(tex, tex_coord);
    float _187 = (_181.x * 255.0) + height_1;
    float _191 = floor(_187 * 0.0039215688593685626983642578125);
    return vec4((_187 - _191) * 0.0039215688593685626983642578125, _191 * 0.0039215688593685626983642578125, 0.0, _181.w);
}

void main()
{
    vec2 param = uv_out;
    vec4 param_1 = color_out;
    float param_2 = options_out.y;
    frag_color_0 = effect(main_tex, param, param_1, param_2);
    vec2 param_3 = uv_out;
    vec4 param_4 = color_out;
    float param_5 = options_out.x;
    frag_color_1 = height(height_tex, param_3, param_4, param_5);
}

