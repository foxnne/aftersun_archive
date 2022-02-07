const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const game = @import("game");
const components = @import("game").components;

pub fn progress(it: *flecs.ecs_iter_t) callconv(.C) void {
    //const world = flecs.World{ .world = it.world.? };
    const renderers = it.term(components.LightRenderer, 1);

    var i: usize = 0;
    while (i < it.count) : (i += 1) {
        if (renderers[i].flicker_duration >= 1) {
            var prng = std.rand.DefaultPrng.init(blk: {
                var seed: u64 = undefined;
                std.os.getrandom(std.mem.asBytes(&seed)) catch unreachable;
                break :blk seed;
            });
            const random = &prng.random();

            renderers[i].flicker_start = renderers[i].flicker_end;
            renderers[i].flicker_end = .{ .x = random.float(f32) * renderers[i].flicker_max_offset, .y = random.float(f32) * renderers[i].flicker_max_offset };
            renderers[i].flicker_duration = 0;
        } else {
            var difference = renderers[i].flicker_end.subtract(renderers[i].flicker_start).scale(renderers[i].flicker_duration);
            renderers[i].offset = renderers[i].flicker_start.add(difference);

            renderers[i].flicker_duration += zia.time.dt() * 10;
        }
    }
}
