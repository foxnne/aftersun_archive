const zia = @import("zia");
const shaders = @import("../../shaders.zig");

pub const Environment = struct {
    environment_shader: *shaders.EnvironmentShader,
    ambient_xy_angle: f32 = 0,
    ambient_z_angle: f32 = 82, //82 is magic
    ambient_color: zia.math.Color = zia.math.Color.white,
    shadow_color: zia.math.Color = zia.math.Color.fromBytes(200, 200, 220, 255),
    shadow_steps: f32 = 150,
};

pub const Time = struct {
    time: f32 = 0,
    timescale: f32 = 6, // scale time passes, where 1 means a day takes an hour, 24 means a day takes a minute

    pub const day: f32 = 24 * 60 * 60;
    pub const hour: f32 = 60 * 60;
    pub const minute: f32 = 60;
};

