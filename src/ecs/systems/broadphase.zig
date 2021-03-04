const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const lucid = @import("lucid");
const components = lucid.components;
const actions = lucid.actions;

pub fn progress(it: *flecs.ecs_iter_t) callconv(.C) void {
    var world = flecs.World{ .world = it.world.? };

    var colliders = it.column(components.Collider, 1);
    var positions = it.column(components.Position, 2);

    var broadphase = it.column(components.Broadphase, 3);

    var grid_ptr = world.getSingleton(components.Grid);

    if (grid_ptr) |grid| {

        var i: usize = 0;
        while (i < it.count) : (i += 1) {
            var x = @floatToInt(i32, @trunc(positions[i].x / @intToFloat(f32, (grid.cellWidth * grid.chunkSize))));
            var y = @floatToInt(i32, @trunc(positions[i].y / @intToFloat(f32, (grid.cellHeight * grid.chunkSize))));

            colliders[i].chunk = .{ .x = x, .y = y };

            broadphase.*.entities.append(colliders[i].chunk, it.entities[i]);

            if (lucid.gizmos.enabled) {
                switch (colliders[i].shape)
                {
                    .circle => lucid.gizmos.circle(.{.x = positions[i].x, .y = positions[i].y}, colliders[i].shape.circle.radius, zia.math.Color.green, 1),
                    .box => lucid.gizmos.box(.{.x = positions[i].x, .y = positions[i].y}, colliders[i].shape.box.width, colliders[i].shape.box.height, zia.math.Color.green, 1),
                }
            }
        }


    }
}
