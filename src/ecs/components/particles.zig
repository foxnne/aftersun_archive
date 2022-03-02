const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const assets = @import("../../assets.zig");

pub const Particle = struct {
    sprite_index: usize = 0,
    position: zia.math.Vector2 = .{},
    velocity: zia.math.Vector2 = .{},
    color: zia.math.Color = zia.math.Color.white,
    lifetime: f32 = 1.0,
    life: f32 = 0.0,
    alive: bool = false,
};

pub const ParticleRenderer = struct {
    position_offset: zia.math.Vector2 = .{},
    texture: zia.gfx.Texture,
    atlas: zia.gfx.Atlas,
    animation: ?[]usize = null,
    start_color: zia.math.Color = zia.math.Color.white,
    end_color: zia.math.Color = zia.math.Color.white,
    active: bool = false,
    particles: []Particle,
    worldspace: bool = true, // if false, particles remain relative to renderer
    rate: f32 = 5, //particles emitted per second
    lifetime: f32 = 1.0, //time new particles should live
    time_since_emit: f32 = 0,
    callback: ?fn (*const ParticleRenderer, *Particle) void, // called when particle is about to be emitted

    pub fn campfireSmokeCallback(self: *const ParticleRenderer, particle: *Particle) void {
        _ = self;

        var prng = std.rand.DefaultPrng.init(blk: {
            var seed: u64 = undefined;
            std.os.getrandom(std.mem.asBytes(&seed)) catch unreachable;
            break :blk seed;
        });
        const rand = &prng.random();
        var vel_x = rand.intRangeAtMost(i32, -10, -5);
        var vel_y = rand.intRangeAtMost(i32, -40, -20);

        particle.sprite_index = assets.aftersun_atlas.Smoke_0_Layer;
        particle.lifetime = self.lifetime;
        particle.velocity = .{ .x = @intToFloat(f32, vel_x), .y = @intToFloat(f32, vel_y) };
        particle.color = self.start_color;
    }
};
