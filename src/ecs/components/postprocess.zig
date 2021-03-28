const zia = @import("zia");
const shaders = @import("../../shaders.zig");


pub const PostProcess = struct {
    tiltshift_shader: *shaders.TiltshiftShader,
    emission_shader: *zia.gfx.Shader,
    bloom_shader: *shaders.BloomShader,
    finalize_shader: *shaders.FinalizeShader,
    textures: ?[]const *zia.gfx.Texture,
};

