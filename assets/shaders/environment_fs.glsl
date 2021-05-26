#version 330

uniform vec4 LightParams[3];
uniform sampler2D main_tex;
uniform sampler2D height_tex;
uniform sampler2D light_tex;

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

bool approx(float a, float b)
{
    return abs(b - a) < 0.00999999977648258209228515625;
}

vec4 shadow(float xy_angle, float z_angle, vec2 tex_coord, float stp, float max_shadow_steps, float max_shadow_height, float shadow_fade, vec4 shadow_color, vec4 vert_color)
{
    vec4 _133 = texture(height_tex, tex_coord);
    float _134 = _133.x;
    for (int i = 0; float(i) < max_shadow_steps; i++)
    {
        float _152 = stp * float(i);
        vec2 param = tex_coord;
        float param_1 = xy_angle;
        float param_2 = _152;
        float _160 = getHeightAt(param, param_1, param_2);
        if (_160 > _134)
        {
            float param_3 = _134;
            float param_4 = z_angle;
            float param_5 = _152;
            float param_6 = abs(getTraceHeight(param_3, param_4, param_5));
            float param_7 = _160;
            if (approx(param_6, param_7))
            {
                float _185 = _152 * shadow_fade;
                return clamp(shadow_color + vec4(_185, _185, _185, _152 * shadow_fade), vec4(0.0), vec4(1.0)) * vert_color;
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
    float param_3 = (1.0 / LightParams[0].x) / cos(radians(LightParams[0].z));
    float param_4 = LightParams[1].w;
    float param_5 = LightParams[2].x;
    float param_6 = LightParams[2].y;
    vec4 param_7 = vec4(LightParams[1].x, LightParams[1].y, LightParams[1].z, 1.0);
    vec4 param_8 = vert_color;
    return shadow(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8) + texture(light_tex, tex_coord);
}

void main()
{
    vec2 param = uv_out;
    vec4 param_1 = color_out;
    frag_color = effect(main_tex, param, param_1);
}

