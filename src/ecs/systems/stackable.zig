const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const game = @import("game");
const imgui = @import("imgui");

const components = game.components;

pub const Callback = struct {
    stackable: *components.Stackable,

    pub const name = "StackableSystem";
    pub const run = progress;
};

fn progress(it: *flecs.Iterator(Callback)) void {
    while (it.next()) |comps| {
        if (it.entity().getMut(components.SpriteRenderer)) |renderer| {
            if (comps.stackable.indices.len > comps.stackable.count - 1 and comps.stackable.count > 0)
                renderer.index = comps.stackable.indices[comps.stackable.count - 1];
                renderer.flipX = false; //why does this observer flip the
                renderer.flipY = false;
        }
    }
}
