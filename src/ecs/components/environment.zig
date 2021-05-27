const zia = @import("zia");
const shaders = @import("../../shaders.zig");

pub const Environment = struct {
    environment_shader: *shaders.EnvironmentShader,
    timescale: f32 = 2,
    ambient_xy_angle: f32 = 0,
    ambient_z_angle: f32 = 82, //82 is magic
    ambient_color: zia.math.Color = zia.math.Color.white,
    shadow_color: zia.math.Color = zia.math.Color.fromBytes(200, 200, 220, 255),
    shadow_steps: f32 = 150,
};

