const zia = @import("zia");
const shaders = @import("../../shaders.zig");

pub const Environment = struct {
    environment_shader: *shaders.EnvironmentShader,
    sun_color: zia.math.Color = zia.math.Color.white,
    sun_xy_angle: f32 = 60,
    sun_z_angle: f32 = 22.5,
    sun_height_high: f32 = 75,
    sun_height_low: f32 = 50,
    shadow_steps_high: f32 = 150,
    shadow_steps_low: f32 = 40,
    shadow_fade_high: f32 = 8,
    shadow_fade_low: f32 = 2,
    shadow_color: zia.math.Color = zia.math.Color.fromBytes(200, 200, 200, 255),
};

