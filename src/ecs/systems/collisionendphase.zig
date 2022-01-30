const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const game = @import("game");
const components = game.components;
const actions = game.actions;

pub fn progress(it: *flecs.ecs_iter_t) callconv(.C) void {
    const broadphase = it.term(components.CollisionBroadphase, 1);
    broadphase.*.entities.clear();
}
