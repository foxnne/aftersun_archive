const zia = @import("zia");

pub const SpriteRenderer = struct {
    texture: zia.gfx.Texture,
    atlas: zia.gfx.Atlas,
    index: usize = 0,
    flipX: bool = false,
    flipY: bool = false,
    color: zia.math.Color = zia.math.Color.white,
};



pub const Material = struct {
    shader: *zia.gfx.Shader,
    textures: []const *zia.gfx.Texture,
};