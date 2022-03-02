const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const game = @import("game");
const components = @import("game").components;

pub const Callback = struct {
    renderer: *components.LightRenderer,

    pub const name = "LightFlickerSystem";
    pub const run = progress;
};

fn progress(it: *flecs.Iterator(Callback)) void {
    while (it.next()) |comps| {
        if (comps.renderer.flicker_duration >= 1) {
            var prng = std.rand.DefaultPrng.init(blk: {
                var seed: u64 = undefined;
                std.os.getrandom(std.mem.asBytes(&seed)) catch unreachable;
                break :blk seed;
            });
            const random = &prng.random();

            comps.renderer.flicker_start = comps.renderer.flicker_end;
            comps.renderer.flicker_end = .{ .x = random.float(f32) * comps.renderer.flicker_max_offset, .y = random.float(f32) * comps.renderer.flicker_max_offset };
            comps.renderer.flicker_duration = 0;
        } else {
            var difference = comps.renderer.flicker_end.subtract(comps.renderer.flicker_start).scale(comps.renderer.flicker_duration);
            comps.renderer.offset = comps.renderer.flicker_start.add(difference);

            comps.renderer.flicker_duration += zia.time.dt() * 10;
        }
    }
}
