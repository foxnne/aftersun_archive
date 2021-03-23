const zia = @import("zia");
const shaders = @import("../../shaders.zig");

pub const PostProcess = struct {
    shader: *zia.gfx.Shader,
    textures: ?[]const *zia.gfx.Texture,
};

pub const ShadowProcess = struct {
    shader: *shaders.LightShader,
};