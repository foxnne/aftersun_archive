const std = @import("std");
const zia = @import("zia");
const gfx = zia.gfx;
const math = zia.math;
const renderkit = zia.renderkit;


pub fn createSpritePaletteShader() !gfx.Shader {
    const vert = if (renderkit.current_renderer == .opengl) @embedFile("../assets/shaders/sprite_vs.glsl") else @embedFile("../assets/shaders/sprite_vs.metal");
    const frag = if (renderkit.current_renderer == .opengl) @embedFile("../assets/shaders/spritePalette_fs.glsl") else @embedFile("../assets/shaders/spritePalette_fs.metal");
    return try gfx.Shader.initWithVertFrag(VertexParams, struct {}, .{ .frag = frag, .vert = vert });
}


pub const VertexParams = extern struct {
    pub const metadata = .{
        .uniforms = .{ .VertexParams = .{ .type = .float4, .array_count = 2 } },
    };

    transform_matrix: [8]f32 = [_]f32{0} ** 8,
};

