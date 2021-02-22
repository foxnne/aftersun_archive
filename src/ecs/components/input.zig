const zia = @import("zia");
const flecs = @import("flecs");

pub const MovementInput = struct {
    direction: zia.math.Direction = .None,
};

pub const PanInput = struct {
    direction: zia.math.Direction = .None,
};

pub const MouseInput = struct {
    position: zia.math.Vector2 = .{},
    camera: flecs.Entity,
};