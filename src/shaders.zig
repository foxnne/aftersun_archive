const std = @import("std");
const zia = @import("zia");
const gfx = zia.gfx;
const math = zia.math;
const renderkit = zia.renderkit;

pub const EnvironmentShader = gfx.ShaderState(LightParams);
pub const FinalizeShader = gfx.ShaderState(FinalizeParams);
pub const TiltshiftShader = gfx.ShaderState(TiltshiftParams);

pub fn createEnvironmentShader() EnvironmentShader {
    const frag = @embedFile("../assets/shaders/environment_fs.glsl");
    return EnvironmentShader.init(.{ .frag = frag, .onPostBind = EnvironmentShader.onPostBind });
}

pub fn createFinalizeShader() FinalizeShader {
    const frag = @embedFile("../assets/shaders/finalize_fs.glsl");
    return FinalizeShader.init(.{ .frag = frag, .onPostBind = FinalizeShader.onPostBind });
}

pub fn createSpritePaletteShader() !gfx.Shader {
    const vert = @embedFile("../assets/shaders/sprite_vs.glsl");
    const frag = @embedFile("../assets/shaders/spritePalette_fs.glsl");
    return try gfx.Shader.initWithVertFrag(VertexParams, struct { pub const metadata = .{ .images = .{ "main_tex", "palette_tex" } }; }, .{ .frag = frag, .vert = vert });
}

pub fn createTiltshiftShader() TiltshiftShader {
    const frag = @embedFile("../assets/shaders/tiltshift_fs.glsl");
    return TiltshiftShader.init(.{ .frag = frag, .onPostBind = TiltshiftShader.onPostBind });
}

pub fn createUberShader() !gfx.Shader {
    const vert = @embedFile("../assets/shaders/sprite_vs.glsl");
    const frag = @embedFile("../assets/shaders/uber_fs.glsl");
    return try gfx.Shader.initWithVertFrag(VertexParams, struct { pub const metadata = .{ .images = .{ "main_tex", "palette_tex" } }; }, .{ .frag = frag, .vert = vert });
}


pub const TiltshiftParams = extern struct {
    pub const metadata = .{
        .images = .{ "main_tex" },
        .uniforms = .{ .TiltshiftParams = .{ .type = .float4, .array_count = 1 } },
    };

    blur_amount: f32 = 0,
    _pad4_0_: [12]u8 = [_]u8{0} ** 12,
};

pub const LightParams = extern struct {
    pub const metadata = .{
        .images = .{ "main_tex", "height_tex", "light_tex" },
        .uniforms = .{ .LightParams = .{ .type = .float4, .array_count = 2 } },
    };

    tex_width: f32 = 0,
    tex_height: f32 = 0,
    ambient_xy_angle: f32 = 0,
    ambient_z_angle: f32 = 0,
    shadow_r: f32 = 0,
    shadow_g: f32 = 0,
    shadow_b: f32 = 0,
    shadow_steps: f32 = 0,
};

pub const VertexParams = extern struct {
    pub const metadata = .{
        .uniforms = .{ .VertexParams = .{ .type = .float4, .array_count = 2 } },
    };

    transform_matrix: [8]f32 = [_]f32{0} ** 8,
};

pub const FinalizeParams = extern struct {
    pub const metadata = .{
        .images = .{ "main_tex", "envir_t" },
        .uniforms = .{ .FinalizeParams = .{ .type = .float4, .array_count = 1 } },
    };

    texel_size: f32 = 0,
    tex_size_x: f32 = 0,
    tex_size_y: f32 = 0,
    _pad12_0_: [4]u8 = [_]u8{0} ** 4,
};

