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
        var target_direction_ptr = world.get(follows[i].target, components.BodyDirection);

        if (world.get(follows[i].target, components.Position)) |tp| {
            var camera_position = zia.math.Vector2{ .x = positions[i].x, .y = positions[i].y};
            var target_position = zia.math.Vector2{ .x = tp.x, .y = tp.y };
            var velocity_direction: zia.math.Direction = zia.math.Direction.None;
            var body_direction: zia.math.Direction = zia.math.Direction.None;
            var head_direction: zia.math.Direction = zia.math.Direction.None;
            var target_distance = target_position.distance(.{ .x = positions[i].x, .y = positions[i].y });

            if (world.get(follows[i].target, components.Velocity)) |tv| {
                velocity_direction = zia.math.Direction.find(8, tv.x, tv.y);
            }

            if (world.get(follows[i].target, components.BodyDirection)) |fd| {
                body_direction = fd.direction;
            }

            if (world.get(follows[i].target, components.HeadDirection)) |hd| {
                head_direction = hd.direction;
            }

            if (velocity_direction != .None) {
                var vec = body_direction.normalized();

                var forward_target = target_position.add(vec.scale(follows[i].max_distance));
                forward_target = forward_target.add(head_direction.normalized().scale(follows[i].min_distance));

                var difference = forward_target.subtract(camera_position);

                velocities[i].x = difference.x * follows[i].easing;
                velocities[i].y = difference.y * follows[i].easing;

                if (lucid.gizmos.enabled) {
                    var color = zia.math.Color.fromBytes(255, 255, 255, 128);
                    lucid.gizmos.circle(forward_target, 2, color, 1);
                }
            } else {
                var vec = head_direction.normalized();
                var forward_target = target_position.add(vec.scale(follows[i].min_distance));

                var difference = forward_target.subtract(camera_position);

                velocities[i].x = difference.x * follows[i].easing;
                velocities[i].y = difference.y * follows[i].easing;

                if (lucid.gizmos.enabled) {
                    var color = zia.math.Color.fromBytes(255, 255, 255, 128);
                    lucid.gizmos.circle(forward_target, 2, color, 1);
                }
            }
        }
    }
}
