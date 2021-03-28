#version 330

const float _101[10] = float[](0.227026998996734619140625, 0.19459460675716400146484375, 0.121621601283550262451171875, 0.054053999483585357666015625, 0.01621600054204463958740234375, 0.0111343003809452056884765625, 0.008490200154483318328857421875, 0.0040293000638484954833984375, 0.0021293000318109989166259765625, 0.00011233999975956976413726806640625);

uniform vec4 BloomParams[1];
uniform sampler2D main_tex;

layout(location = 0) out vec4 frag_color;
in vec2 uv_out;
in vec4 color_out;

vec4 effect(sampler2D tex, vec2 tex_coord, vec4 vert_color)
{
    vec2 _48 = vec2(1.0) / vec2(BloomParams[0].y, BloomParams[0].z);
    vec3 result = texture(tex, tex_coord).xyz * 0.227026998996734619140625;
    if (BloomParams[0].x > 0.0)
    {
        for (int i = 1; i < 10; i++)
        {
            vec2 _86 = vec2(_48.x * float(i), 0.0);
            result = (result + (texture(tex, tex_coord + _86).xyz * _101[i])) + (texture(tex, tex_coord - _86).xyz * _101[i]);
        }
    }
    else
    {
        for (int i_1 = 1; i_1 < 10; i_1++)
        {
            vec2 _147 = vec2(0.0, _48.y * float(i_1));
            result = (result + (texture(tex, tex_coord + _147).xyz * _101[i_1])) + (texture(tex, tex_coord - _147).xyz * _101[i_1]);
        }
    }
    return vec4(result, 1.0);
}

void main()
{
    vec2 param = uv_out;
    vec4 param_1 = color_out;
    frag_color = effect(main_tex, param, param_1);
}

