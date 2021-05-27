const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const game = @import("game");
const components = game.components;
const actions = game.actions;

pub fn progress(it: *flecs.ecs_iter_t) callconv(.C) void {
    var world = flecs.World{ .world = it.world.? };

    var colliders = it.column(components.Collider, 1);
    var positions = it.column(components.Position, 2);
    var broadphase = it.column(components.Broadphase, 3);

    if (world.getSingleton(components.Grid)) |grid| {
        var i: usize = 0;
        while (i < it.count) : (i += 1) {
            var x = @floatToInt(i32, @trunc(positions[i].x / @intToFloat(f32, (grid.pixelsPerUnit * grid.cellSize))));
            var y = @floatToInt(i32, @trunc(positions[i].y / @intToFloat(f32, (grid.pixelsPerUnit * grid.cellSize))));

            colliders[i].cell = .{ .x = x, .y = y };

            broadphase.*.entities.append(colliders[i].cell, it.entities[i]);

            // if (world.getSingletonMut(components.Gizmos)) |gizmos| {
            //     gizmos.testAdd();
            // }

            if (game.gizmos.enabled) {
                switch (colliders[i].shape) {
                    //.circle => gizmos.circle(.{.x = positions[i].x, .y = positions[i].y}, colliders[i].shape.circle.radius, zia.math.Color.green, 1),
                    .circle => game.gizmos.circle(.{ .x = positions[i].x, .y = positions[i].y }, colliders[i].shape.circle.radius,  zia.math.Color.green, 1 ),
                    .box => game.gizmos.box(.{ .x = positions[i].x, .y = positions[i].y }, colliders[i].shape.box.width, colliders[i].shape.box.height,  zia.math.Color.green, 1 ),
                    
                    // else => {},
                }
            }
        }
    }
}
