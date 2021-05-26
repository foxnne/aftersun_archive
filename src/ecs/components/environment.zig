const zia = @import("zia");
const shaders = @import("../../shaders.zig");

pub const Environment = struct {
    timescale: f32 = 2,
    environment_shader: *shaders.EnvironmentShader,
    sun_color: zia.math.Color = zia.math.Color.white,
    sun_xy_angle: f32 = 0,
    sun_z_angle: f32 = 85,
    sun_height_high: f32 = 75,
    sun_height_low: f32 = 50,
    shadow_steps_high: f32 = 150,
    shadow_steps_low: f32 = 150,
    shadow_fade_high: f32 = 8,
    shadow_fade_low: f32 = 2,
    shadow_color: zia.math.Color = zia.math.Color.fromBytes(150, 150, 160, 255),
};
