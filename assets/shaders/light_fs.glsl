#version 330

uniform vec4 LightParams[3];
uniform sampler2D main_tex;
uniform sampler2D height_tex;

layout(location = 0) out vec4 frag_color;
in vec2 uv_out;
in vec4 color_out;

vec2 extrude(vec2 other, float angle, float len)
{
    return vec2(other.x + (len * cos(radians(angle))), other.y + (len * sin(radians(angle))));
}

float getHeightAt(vec2 texCoord, float xyAngle, float dist)
{
    vec2 param = texCoord;
    float param_1 = xyAngle;
    float param_2 = dist;
    return texture(height_tex, extrude(param, param_1, param_2)).x;
}

float getTraceHeight(float height, float zAngle, float dist)
{
    return (dist * tan(radians(zAngle))) + height;
}

vec4 shadow(float xy_angle, float z_angle, vec2 tex_coord, float stp, float max_shadow_steps, float max_shadow_height, float shadow_fade, vec4 shadow_color, vec4 vert_color)
{
    vec4 _119 = texture(height_tex, tex_coord);
    float _120 = _119.x;
    for (int i = 0; float(i) < max_shadow_steps; i++)
    {
        float _139 = stp * float(i);
        vec2 param = tex_coord;
        float param_1 = xy_angle;
        float param_2 = _139;
        float _147 = getHeightAt(param, param_1, param_2);
        bool _150 = _147 > _120;
        bool _160;
        if (_150)
        {
            _160 = (_147 - _120) < (max_shadow_height * stp);
        }
        else
        {
            _160 = _150;
        }
        if (_160)
        {
            float param_3 = _120;
            float param_4 = z_angle;
            float param_5 = _139;
            if (getTraceHeight(param_3, param_4, param_5) < _147)
            {
                float _179 = _139 * shadow_fade;
                return clamp(shadow_color + vec4(_179, _179, _179, _139 * shadow_fade), vec4(0.0), vec4(1.0)) * vert_color;
            }
        }
    }
    return vert_color;
}

vec4 effect(sampler2D tex, vec2 tex_coord, vec4 vert_color)
{
    float param = LightParams[0].z;
    float param_1 = LightParams[0].w;
    vec2 param_2 = tex_coord;
    float param_3 = 1.0 / LightParams[0].y;
    float param_4 = LightParams[1].w;
    float param_5 = LightParams[2].x;
    float param_6 = LightParams[2].y;
    vec4 param_7 = vec4(LightParams[1].x, LightParams[1].y, LightParams[1].z, 1.0);
    vec4 param_8 = vert_color;
    return shadow(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8);
}

void main()
{
    vec2 param = uv_out;
    vec4 param_1 = color_out;
    frag_color = effect(main_tex, param, param_1);
}

