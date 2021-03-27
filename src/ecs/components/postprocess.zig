const zia = @import("zia");
const shaders = @import("../../shaders.zig");


pub const PostProcess = struct {
    shader: *shaders.PostProcessShader,
    textures: ?[]const *zia.gfx.Texture,
};

