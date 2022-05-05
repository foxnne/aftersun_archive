const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const components = @import("game").components;

pub const Callback = struct {
    cooldown: *components.MovementCooldown,

    pub const name = "MovementCooldownSystem";
    pub const run = progress;
};

fn progress(it: *flecs.Iterator(Callback)) void {
    while (it.next()) |comps| {
        if (comps.cooldown.current < comps.cooldown.end) {
            comps.cooldown.current += it.iter.delta_time;

            if (comps.cooldown.current > comps.cooldown.end)
                comps.cooldown.current = comps.cooldown.end;
        }
    }
}
