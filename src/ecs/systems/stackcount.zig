const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const game = @import("game");
const imgui = @import("imgui");

const components = game.components;

pub const Callback = struct {
    request: *components.StackRequest,
    stackable: *components.Stackable,
    count: *components.Count,

    pub const name = "StackCountSystem";
    pub const run = progress;
};

fn progress(it: *flecs.Iterator(Callback)) void {
    while (it.next()) |comps| {
        if (it.entity().get(components.MovementCooldown)) |cooldown| {
            if (cooldown.current < cooldown.end) {
                continue;
            }
        }

        if (comps.request.count != 0) {
            if (@intCast(i32, comps.count.value) + comps.request.count <= 0) {
                if (comps.request.other) |other| {
                    if (other.get(components.MovementCooldown)) |cooldown| {
                        if (cooldown.current < cooldown.end) {
                            continue;
                        }
                    }
                }
                it.entity().delete();
                continue;
            } else {
                comps.count.value = @intCast(usize, @intCast(i32, comps.count.value) + comps.request.count);
                it.entity().setModified(components.Count);
            }
        }
        it.entity().remove(components.StackRequest);
    }
}
