const flecs = @import("flecs");
const zia = @import("zia");

pub const Camera = struct {
    trans_mat: zia.math.Matrix3x2 = undefined,
    design_w: i32,
    design_h: i32,
};

pub const RenderQuery = struct {
    renderers: ?*flecs.Query,
};

pub const Zoom = struct {
    min: f32 = 1.0,
    max: f32 = 4.0,
    current: f32 = 1.0,
    target: f32 = 1.0,
    speed: f32 = 4.0,
};

pub const Follow = struct {
    target: flecs.Entity,
    max_distance: f32 = 120,
    min_distance: f32 = 60,
    speed: f32 = 40.0,
};