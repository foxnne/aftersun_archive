const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const game = @import("game");
const imgui = @import("imgui");

const components = game.components;

pub fn progress(it: *flecs.ecs_iter_t) callconv(.C) void {
    const times = it.term(components.Time, 1);

    var i: usize = 0;
    while (i < it.count) : (i += 1) {

        times[i].time += times[i].timescale * components.Time.minute * zia.time.dt();
        if (times[i].time >= components.Time.day)
            times[i].time = 0;

        std.log.debug("Hour: {d}", .{ times[i].time / components.Time.hour});
    }
}
