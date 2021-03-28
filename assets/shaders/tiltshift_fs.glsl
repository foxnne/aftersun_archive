#version 330

uniform vec4 TiltshiftParams[1];
uniform sampler2D main_tex;

layout(location = 0) out vec4 frag_color;
in vec2 uv_out;
in vec4 color_out;

vec4 effect(sampler2D tex, vec2 tex_coord, vec4 vert_color)
{
    float _55 = pow((tex_coord.y * 2.0) - 1.0, 2.0) * TiltshiftParams[0].x;
    vec4 blurred = vec4(0.0, 0.0, 0.0, 1.0);
    for (float offsX = -1.0; offsX <= 1.0; offsX += 1.0)
    {
        for (float offsY = -1.0; offsY <= 1.0; offsY += 1.0)
        {
            vec2 _114 = tex_coord;
            _114.x = tex_coord.x + ((offsX * _55) * 0.0040000001899898052215576171875);
            vec2 _117 = _114;
            _117.y = tex_coord.y + ((offsY * _55) * 0.0040000001899898052215576171875);
            blurred += texture(tex, _117);
        }
    }
    vec4 _107 = blurred;
    vec4 _109 = _107 * vec4(0.111111111938953399658203125);
    blurred = _109;
    return _109;
}

void main()
{
    vec2 param = uv_out;
    vec4 param_1 = color_out;
    frag_color = effect(main_tex, param, param_1);
}

