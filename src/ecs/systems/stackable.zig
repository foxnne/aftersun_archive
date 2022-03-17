const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const game = @import("game");
const imgui = @import("imgui");

const components = game.components;

pub const Callback = struct {
    count: *components.Count,

    pub const name = "StackableSystem";
    pub const run = progress;
};

fn progress(it: *flecs.Iterator(Callback)) void {
    while (it.next()) |comps| {
        if (it.entity().get(components.Stackable)) |stackable| {
            if (it.entity().getMut(components.SpriteRenderer)) |renderer| {
                if (stackable.indices.len > comps.count.value - 1 and comps.count.value > 0) {}
                    renderer.index = stackable.indices[comps.count.value - 1];
                //renderer.flipX = false; //why does this observer flip the
                //renderer.flipY = false;
            }
        }
    }
}
