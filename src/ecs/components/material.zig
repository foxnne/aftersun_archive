const zia = @import("zia");

pub const Material = struct {
    shader: *zia.gfx.Shader,
    textures: []const *zia.gfx.Texture,
};