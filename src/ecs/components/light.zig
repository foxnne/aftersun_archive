const zia = @import("zia");

pub const LightRenderer = struct {
    texture: zia.gfx.Texture,
    atlas: zia.gfx.Atlas,
    index: usize = 0,
    color: zia.math.Color = zia.math.Color.white,
};