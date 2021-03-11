const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const lucid = @import("lucid");
const components = lucid.components;

pub fn progress(it: *flecs.ecs_iter_t) callconv(.C) void {
    var cameras = it.column(components.Camera, 1);
    var follows = it.column(components.Follow, 2);
    var positions = it.column(components.Position, 3);
    var velocities = it.column(components.Velocity, 4);
    var world = flecs.World{ .world = it.world.? };

    var i: usize = 0;
    while (i < it.count) : (i += 1) {
        var target_position_ptr = world.get(follows[i].target, components.Position);
        var target_velocity_ptr = world.get(follows[i].target, components.Velocity);

        if (target_position_ptr) |target_position| {
            const target_distance = zia.math.Vector2.distance(.{ .x = target_position.x, .y = target_position.y }, .{ .x = positions[i].x, .y = positions[i].y });
            const target_direction = zia.math.Direction.find(8, target_position.x - positions[i].x, target_position.y - positions[i].y).normalized();
            

            if (target_velocity_ptr) |target_velocity| {

                if (target_distance <= follows[i].min_distance) {
                    velocities[i].x = 0;
                    velocities[i].y = 0;
                } else if (target_distance <= follows[i].max_distance) {
                    velocities[i].x = target_direction.x * zia.time.dt() * follows[i].speed;
                    velocities[i].y = target_direction.y * zia.time.dt() * follows[i].speed;
                } else { //greater than max distance
                    if (target_velocity.x != 0 or target_velocity.y != 0) {
                        var speed_x = @fabs(target_velocity.x / zia.time.dt());
                        var speed_y = @fabs(target_velocity.y / zia.time.dt());

                        velocities[i].x = target_direction.x * zia.time.dt() * follows[i].speed;
                        velocities[i].y = target_direction.y * zia.time.dt() * follows[i].speed;
                    } else {
                        velocities[i].x = target_direction.x * zia.time.dt() * follows[i].speed;
                        velocities[i].y = target_direction.y * zia.time.dt() * follows[i].speed;
                    }
                }

                if (lucid.gizmos.enabled) {
                    var color = zia.math.Color.fromBytes(255, 255, 255, 128);
                    lucid.gizmos.circle(.{ .x = target_position.x, .y = target_position.y }, follows[i].min_distance, color, 1);
                    lucid.gizmos.circle(.{ .x = target_position.x, .y = target_position.y }, 2, color, 1);
                    lucid.gizmos.line(.{ .x = positions[i].x, .y = positions[i].y }, .{ .x = target_position.x, .y = target_position.y }, color, 1);
                    lucid.gizmos.circle(.{ .x = positions[i].x, .y = positions[i].y }, 2, color, 1);
                }
            }
        }
    }
}
