#version 330

uniform sampler2D main_tex;
uniform sampler2D shadow_tex;

layout(location = 0) out vec4 frag_color;
in vec2 uv_out;
in vec4 color_out;

vec2 interpolate(vec2 tex_coord, ivec2 tex_size, float texelsPerPixel)
{
    vec2 _120 = tex_coord * vec2(tex_size);
    vec2 _123 = fract(_120);
    return (floor(_120) + (clamp(_123 / vec2(texelsPerPixel), vec2(0.0), vec2(0.5)) + clamp(((_123 - vec2(1.0)) / vec2(texelsPerPixel)) + vec2(0.5), vec2(0.0), vec2(0.5)))) / vec2(tex_size);
}

vec4 tiltshift(sampler2D tex, vec2 tex_coord)
{
    float _58 = pow((tex_coord.y * 2.0) - 1.0, 2.0);
    vec4 blurred = vec4(0.0, 0.0, 0.0, 1.0);
    for (float offsX = -1.0; offsX <= 1.0; offsX += 1.0)
    {
        for (float offsY = -1.0; offsY <= 1.0; offsY += 1.0)
        {
            vec2 _183 = tex_coord;
            _183.x = tex_coord.x + ((offsX * _58) * 0.0040000001899898052215576171875);
            vec2 _186 = _183;
            _186.y = tex_coord.y + ((offsY * _58) * 0.0040000001899898052215576171875);
            blurred += texture(tex, _186);
        }
    }
    vec4 _111 = blurred;
    vec4 _113 = _111 * vec4(0.111111111938953399658203125);
    blurred = _113;
    return _113;
}

vec4 effect(sampler2D tex, vec2 tex_coord, vec4 vert_color)
{
    vec2 param = tex_coord;
    ivec2 param_1 = textureSize(tex, 0);
    float param_2 = 8.0;
    vec2 _168 = interpolate(param, param_1, param_2);
    vec2 param_3 = _168;
    vec2 param_4 = _168;
    return tiltshift(tex, param_4) * tiltshift(shadow_tex, param_3);
}

void main()
{
    vec2 param = uv_out;
    vec4 param_1 = color_out;
    frag_color = effect(main_tex, param, param_1);
}

