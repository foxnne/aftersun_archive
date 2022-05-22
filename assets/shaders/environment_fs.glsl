#version 330

uniform vec4 LightParams[2];
uniform sampler2D main_tex;
uniform sampler2D height_tex;
uniform sampler2D reordered_height_tex;
uniform sampler2D light_tex;

layout(location = 0) out vec4 frag_color;
in vec2 uv_out;
in vec4 color_out;

vec2 getTargetTexCoords(float x_step, float y_step, float xy_angle, float h)
{
    return vec2((cos(radians(xy_angle)) * h) * x_step, (sin(radians(xy_angle)) * h) * y_step);
}

bool approx(float a, float b)
{
    return abs(b - a) < 0.00999999977648258209228515625;
}

vec4 find_shadow(sampler2D height_texture, float xy_angle, float z_angle, vec2 tex_coord, float stp, float shadow_steps, float tex_step_x, float tex_step_y, vec4 shadow_color, vec4 vert_color)
{
    vec4 _93 = texture(height_tex, tex_coord);
    float _104 = _93.x + (_93.z * 255.0);
    for (int i = 0; i < int(shadow_steps); i++)
    {
        float param = tex_step_x;
        float param_1 = tex_step_y;
        float param_2 = xy_angle;
        float param_3 = float(i);
        vec4 _132 = texture(height_texture, tex_coord + getTargetTexCoords(param, param_1, param_2, param_3));
        float _139 = _132.x + (_132.z * 255.0);
        float param_4 = tex_step_x;
        float param_5 = tex_step_y;
        float param_6 = xy_angle;
        float param_7 = float(i);
        if (_139 > _104)
        {
            float param_8 = (distance(tex_coord, tex_coord + getTargetTexCoords(param_4, param_5, param_6, param_7)) * tan(radians(z_angle))) + _104;
            float param_9 = _139;
            if (approx(param_8, param_9))
            {
                return shadow_color * vert_color;
            }
        }
    }
    return vert_color;
}

vec4 effect(sampler2D tex, vec2 tex_coord, vec4 vert_color)
{
    float _193 = 1.0 / LightParams[0].x;
    float _197 = 1.0 / LightParams[0].y;
    float _206 = sqrt((_193 * _193) + (_197 * _197));
    vec4 _217 = vec4(LightParams[1].x, LightParams[1].y, LightParams[1].z, 1.0);
    float param = LightParams[0].z;
    float param_1 = LightParams[0].w;
    vec2 param_2 = tex_coord;
    float param_3 = _206;
    float param_4 = LightParams[1].w;
    float param_5 = _193;
    float param_6 = _197;
    vec4 param_7 = _217;
    vec4 param_8 = vert_color;
    vec4 _243 = find_shadow(height_tex, param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8);
    vec4 shadow = _243;
    if (all(equal(_243, vert_color)))
    {
        float param_9 = LightParams[0].z;
        float param_10 = LightParams[0].w;
        vec2 param_11 = tex_coord;
        float param_12 = _206;
        float param_13 = LightParams[1].w;
        float param_14 = _193;
        float param_15 = _197;
        vec4 param_16 = _217;
        vec4 param_17 = vert_color;
        shadow = find_shadow(reordered_height_tex, param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17);
    }
    return shadow + texture(light_tex, tex_coord);
}

void main()
{
    vec2 param = uv_out;
    vec4 param_1 = color_out;
    frag_color = effect(main_tex, param, param_1);
}

