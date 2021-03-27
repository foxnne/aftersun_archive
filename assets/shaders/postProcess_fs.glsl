#version 330

uniform vec4 PostProcessingParams[1];
uniform sampler2D main_tex;
uniform sampler2D emission_tex;
uniform sampler2D environment_texture;

layout(location = 0) out vec4 frag_color;
in vec2 uv_out;
in vec4 color_out;

vec2 interpolate(vec2 tex_coord, ivec2 tex_size, float texelsPerPixel)
{
    vec2 _142 = tex_coord * vec2(tex_size);
    vec2 _145 = fract(_142);
    return (floor(_142) + (clamp(_145 / vec2(texelsPerPixel), vec2(0.0), vec2(0.5)) + clamp(((_145 - vec2(1.0)) / vec2(texelsPerPixel)) + vec2(0.5), vec2(0.0), vec2(0.5)))) / vec2(tex_size);
}

vec4 bloom(sampler2D tex, vec2 tex_coord)
{
    return texture(tex, tex_coord);
}

vec4 tiltshift(sampler2D tex, vec2 tex_coord)
{
    float _81 = pow((tex_coord.y * 2.0) - 1.0, 2.0) * PostProcessingParams[0].x;
    vec4 blurred = vec4(0.0, 0.0, 0.0, 1.0);
    for (float offsX = -1.0; offsX <= 1.0; offsX += 1.0)
    {
        for (float offsY = -1.0; offsY <= 1.0; offsY += 1.0)
        {
            vec2 _213 = tex_coord;
            _213.x = tex_coord.x + ((offsX * _81) * 0.0040000001899898052215576171875);
            vec2 _216 = _213;
            _216.y = tex_coord.y + ((offsY * _81) * 0.0040000001899898052215576171875);
            blurred += texture(tex, _216);
        }
    }
    vec4 _133 = blurred;
    vec4 _135 = _133 * vec4(0.111111111938953399658203125);
    blurred = _135;
    return _135;
}

vec4 effect(sampler2D tex, vec2 tex_coord, vec4 vert_color)
{
    vec2 param = tex_coord;
    ivec2 param_1 = textureSize(tex, 0);
    float param_2 = 8.0;
    vec2 _189 = interpolate(param, param_1, param_2);
    vec2 param_3 = _189;
    vec2 param_4 = _189;
    vec2 param_5 = _189;
    return (tiltshift(tex, param_5) * tiltshift(environment_texture, param_4)) + bloom(emission_tex, param_3);
}

void main()
{
    vec2 param = uv_out;
    vec4 param_1 = color_out;
    frag_color = effect(main_tex, param, param_1);
}

