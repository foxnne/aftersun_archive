const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const game = @import("game");
const components = game.components;

pub const Callback = struct {
    pub const name = "CollisionEndphaseSystem";
    pub const run = progress;
};

fn progress(it: *flecs.Iterator(Callback)) void {
    if (it.world().getSingletonMut(components.CollisionBroadphase)) |broadphase|{
        broadphase.entities.clear();
    }
}
