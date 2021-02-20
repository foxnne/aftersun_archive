const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const lucid = @import("lucid");
const components = lucid.components;
const actions = lucid.actions;

pub fn progress(it: *flecs.ecs_iter_t) callconv(.C) void {

    var world = flecs.World{ .world = it.world.?};

    //var colliderQuery = flecs.ecs_query_new(world.world, "Position, Collider, ?Velocity, ?Subpixel");

    //actions.collide(colliderQuery);



}