#version 330

uniform vec4 UberVertexParams[3];
out vec2 uv_out;
layout(location = 1) in vec2 uv_in;
out vec4 color_out;
layout(location = 2) in vec4 color_in;
out vec4 options_out;
layout(location = 3) in vec4 options_in;
layout(location = 0) in vec2 pos_in;

void main()
{
    uv_out = uv_in;
    color_out = color_in;
    options_out = options_in;
    vec2 pos = pos_in;
    if (options_in.z == 1.0)
    {
        vec2 _103 = pos;
        _103.x = pos.x + ((sin(options_in.w) * 10.0) * (0.5 - uv_in.y));
        pos = _103;
    }
    gl_Position = vec4(mat3x2(vec2(UberVertexParams[0].x, UberVertexParams[0].y), vec2(UberVertexParams[0].z, UberVertexParams[0].w), vec2(UberVertexParams[1].x, UberVertexParams[1].y)) * vec3(pos, 1.0), 0.0, 1.0);
}

