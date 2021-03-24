const zia = @import("zia");


pub const PostProcess = struct {
    shader: *zia.gfx.Shader,
    textures: ?[]const *zia.gfx.Texture,
};

