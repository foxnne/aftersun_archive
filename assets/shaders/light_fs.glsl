#version 330

uniform vec4 LightParams[1];
uniform sampler2D main_tex;
uniform sampler2D height_tex;

layout(location = 0) out vec4 frag_color;
in vec2 uv_out;
in vec4 color_out;

vec2 extrude(vec2 other, float angle, float len)
{
    return vec2(other.x + (len * cos(radians(angle))), other.y + (len * sin(radians(angle))));
}

float getHeightAt(vec2 texCoord, float xyAngle, float dist, sampler2D heightMap)
{
    vec2 param = texCoord;
    float param_1 = xyAngle;
    float param_2 = dist;
    return texture(heightMap, extrude(param, param_1, param_2)).x;
}

float getTraceHeight(float height, float zAngle, float dist)
{
    return (dist * tan(radians(zAngle))) + height;
}

bool isInShadow(float xyAngle, float zAngle, sampler2D heightMap, vec2 texCoord, float stp)
{
    vec4 _116 = texture(heightMap, texCoord);
    float _117 = _116.x;
    for (int i = 0; i < 200; i++)
    {
        float _134 = stp * float(i);
        vec2 param = texCoord;
        float param_1 = xyAngle;
        float param_2 = _134;
        float _142 = getHeightAt(param, param_1, param_2, heightMap);
        bool _145 = _142 > _117;
        bool _155;
        if (_145)
        {
            _155 = (_142 - _117) < (50.0 * stp);
        }
        else
        {
            _155 = _145;
        }
        if (_155)
        {
            float param_3 = _117;
            float param_4 = zAngle;
            float param_5 = _134;
            if (getTraceHeight(param_3, param_4, param_5) < _142)
            {
                return true;
            }
        }
    }
    return false;
}

vec4 effect(sampler2D tex, vec2 tex_coord, vec4 vert_color)
{
    float param = LightParams[0].z;
    float param_1 = LightParams[0].w;
    vec2 param_2 = tex_coord;
    float param_3 = 1.0 / LightParams[0].y;
    if (isInShadow(param, param_1, height_tex, param_2, param_3))
    {
        return vec4(0.800000011920928955078125, 0.800000011920928955078125, 0.89999997615814208984375, 1.0);
    }
    return vert_color;
}

void main()
{
    vec2 param = uv_out;
    vec4 param_1 = color_out;
    frag_color = effect(main_tex, param, param_1);
}

