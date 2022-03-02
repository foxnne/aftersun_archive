const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const game = @import("game");
const imgui = @import("imgui");

const components = game.components;

pub const Callback = struct {
    time: *components.Time,

    pub const name = "TimeSystem";
    pub const run = progress;
};

fn progress(it: *flecs.Iterator(Callback)) void {
    while (it.next()) |comps| {

        comps.time.time += comps.time.timescale * components.Time.minute * zia.time.dt();
        if (comps.time.time >= components.Time.day)
            comps.time.time = 0;

    }
}
