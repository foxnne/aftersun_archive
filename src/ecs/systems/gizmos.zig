const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const lucid = @import("lucid");
const components = lucid.components;
const actions = lucid.actions;

pub fn progress(it: *flecs.ecs_iter_t) callconv(.C) void {
    var gizmos = it.column(components.Gizmos, 1);
    var world = flecs.World{ .world = it.world.? };
    
    // enable/disable gizmos
    if (zia.input.keyPressed(.grave)) {
        gizmos.*.enabled = !gizmos.*.enabled;
    }
}