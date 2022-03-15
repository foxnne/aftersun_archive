const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const game = @import("game");
const imgui = @import("imgui");

const components = game.components;

pub const Callback = struct {
    request: *components.StackRequest,

    pub const name = "StackRequestSystem";
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
            if (it.entity().getMut(components.Stackable)) |stackable| {
                if (@intCast(i32, stackable.count) + comps.request.count <= 0) {
                    if (comps.request.other) |other| {
                        if (other.get(components.MovementCooldown)) |cooldown| {
                            if (cooldown.current < cooldown.end) {
                                continue;
                            }
                        }
                    }
                    it.entity().delete();
                }else {
                    stackable.count = @intCast(usize, @intCast(i32, stackable.count) + comps.request.count);
                    it.entity().setModified(components.Stackable);
                }

            }
        }
        it.entity().remove(components.StackRequest);
    }
}
