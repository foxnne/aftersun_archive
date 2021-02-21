const zia = @import("zia");

pub const SpriteRenderer = struct {
    texture: zia.gfx.Texture,
    atlas: zia.gfx.Atlas,
    index: usize = 0,
    flipX: bool = false,
    flipY: bool = false,
};

pub const CompositeRenderer = struct {
    texture: zia.gfx.Texture,
    atlas: zia.gfx.Atlas,
    indices: []usize,
    colors: []usize,
};

pub const Material = struct {
    shader: *zia.gfx.Shader,
    textures: []const *zia.gfx.Texture,
};