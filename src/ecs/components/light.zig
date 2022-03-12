const zia = @import("zia");

pub const LightRenderer = struct {
    index: usize = 0,
    color: zia.math.Color = zia.math.Color.white,
    offset: zia.math.Vector2 = .{.x = 0, .y = 0},
    size: zia.math.Vector2 = .{.x = 1, .y = 1},
    flicker_max_offset: f32 = 10.0,
    flicker_duration: f32 = 0.0,
    flicker_end: zia.math.Vector2 = .{},
    flicker_start: zia.math.Vector2 = .{},
};