#version 330

uniform sampler2D main_tex;

layout(location = 0) out vec4 frag_color;
in vec2 uv_out;
in vec4 color_out;

vec4 tiltshift(sampler2D tex, vec2 tex_coord)
{
    float _49 = pow((tex_coord.y * 2.0) - 1.0, 2.0);
    vec4 blurred = vec4(0.0, 0.0, 0.0, 1.0);
    for (float offsX = -1.0; offsX <= 1.0; offsX += 1.0)
    {
        for (float offsY = -1.0; offsY <= 1.0; offsY += 1.0)
        {
            vec2 _163 = tex_coord;
            _163.x = tex_coord.x + ((offsX * _49) * 0.0040000001899898052215576171875);
            vec2 _166 = _163;
            _166.y = tex_coord.y + ((offsY * _49) * 0.0040000001899898052215576171875);
            blurred += texture(tex, _166);
        }
    }
    vec4 _102 = blurred;
    vec4 _104 = _102 * vec4(0.111111111938953399658203125);
    blurred = _104;
    return _104;
}

vec4 effect(sampler2D tex, vec2 tex_coord, vec4 vert_color)
{
    vec2 _118 = vec2(textureSize(tex, 0));
    vec2 _119 = tex_coord * _118;
    vec2 _124 = fract(_119);
    vec2 param = (floor(_119) + (clamp(_124 * vec2(0.125), vec2(0.0), vec2(0.5)) + clamp(((_124 - vec2(1.0)) * vec2(0.125)) + vec2(0.5), vec2(0.0), vec2(0.5)))) / _118;
    return tiltshift(tex, param) * vert_color;
}

void main()
{
    vec2 param = uv_out;
    vec4 param_1 = color_out;
    frag_color = effect(main_tex, param, param_1);
}

