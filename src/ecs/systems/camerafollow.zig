const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const components = @import("../components/components.zig");

pub fn process(it: *flecs.ecs_iter_t) callconv(.C) void {
    var cameras = it.column(components.Camera, 1);
    var follows = it.column(components.Follow, 2);
    var positions = it.column(components.Position, 3);
    var velocities = it.column(components.Velocity, 4);

    var i: usize = 0;
    while (i < it.count) : (i += 1) {
        var world = flecs.World{ .world = it.world.? };

        var target_position_ptr = flecs.ecs_get_w_entity(world.world, follows[i].target, world.newComponent(components.Position));
        var target_velocity_ptr = flecs.ecs_get_w_entity(world.world, follows[i].target, world.newComponent(components.Velocity));

        if (target_position_ptr) |pos_ptr| {
            const target_position = @ptrCast(*const components.Position, @alignCast(@alignOf(components.Position), pos_ptr));

            var target_distance = zia.math.Vector2.distance(.{ .x = target_position.x, .y = target_position.y }, .{ .x = positions[i].x, .y = positions[i].y });
            var target_direction = zia.math.Direction.find(8, target_position.x - positions[i].x, target_position.y - positions[i].y).normalized();

            if (target_velocity_ptr) |vel_ptr| {
                const target_velocity = @ptrCast(*const components.Velocity, @alignCast(@alignOf(components.Velocity), vel_ptr));

                var margin: f32 = 5;

                if (target_distance <= follows[i].min_distance) {
                    velocities[i].x = 0;
                    velocities[i].y = 0;
                } else if (target_distance <= follows[i].max_distance) {
                    velocities[i].x = target_direction.x * zia.time.dt() * follows[i].follow_speed;
                    velocities[i].y = target_direction.y * zia.time.dt() * follows[i].follow_speed;
                } else { //greater than max distance
                    if (target_velocity.x != 0 or target_velocity.y != 0) {
                        velocities[i].x = target_velocity.x;
                        velocities[i].y = target_velocity.y;
                    } else {
                        velocities[i].x = target_direction.x * zia.time.dt() * follows[i].follow_speed;
                        velocities[i].y = target_direction.y * zia.time.dt() * follows[i].follow_speed;
                    }
                }
            }
        }
    }
}
