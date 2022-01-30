const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const game = @import("game");
const components = game.components;

pub fn progress(it: *flecs.ecs_iter_t) callconv(.C) void {
    var world = flecs.World{ .world = it.world.? };
    //var cameras = it.term(components.Camera, 1);
    const follows = it.term(components.Follow, 2);
    const positions = it.term(components.Position, 3);
    const velocities = it.term(components.Velocity, 4);

    var i: usize = 0;
    while (i < it.count) : (i += 1) {
        //var target_direction_ptr = world.get(follows[i].target, components.BodyDirection);

        if (world.get(follows[i].target, components.Position)) |tp| {
            var camera_position = zia.math.Vector2{ .x = positions[i].x, .y = positions[i].y};
            var target_position = zia.math.Vector2{ .x = tp.x, .y = tp.y };
            var velocity_direction: zia.math.Direction = zia.math.Direction.none;
            var body_direction: zia.math.Direction = zia.math.Direction.none;
            var head_direction: zia.math.Direction = zia.math.Direction.none;

            if (world.get(follows[i].target, components.Velocity)) |tv| {
                velocity_direction = zia.math.Direction.find(8, tv.x, tv.y);
            }

            if (world.get(follows[i].target, components.BodyDirection)) |fd| {
                body_direction = fd.direction;
            }

            if (world.get(follows[i].target, components.HeadDirection)) |hd| {
                head_direction = hd.direction;
            }

            if (velocity_direction != .none) {
                var vec = body_direction.normalized();

                var forward_target = target_position.add(vec.scale(follows[i].max_distance));
                forward_target = forward_target.add(head_direction.normalized().scale(follows[i].min_distance));

                var difference = forward_target.subtract(camera_position);

                velocities[i].x = difference.x * follows[i].easing * 1.2;
                velocities[i].y = difference.y * follows[i].easing * 1.2;

                if (game.gizmos.enabled) {
                    var color = zia.math.Color.fromBytes(255, 255, 255, 128);
                    game.gizmos.circle(forward_target, 2, color, 1);
                }
            } else {
                var vec = head_direction.normalized();
                var forward_target = target_position.add(vec.scale(follows[i].min_distance));

                var difference = forward_target.subtract(camera_position);

                velocities[i].x = difference.x * follows[i].easing * 2;
                velocities[i].y = difference.y * follows[i].easing * 2;

                if (game.gizmos.enabled) {
                    var color = zia.math.Color.fromBytes(255, 255, 255, 128);
                    game.gizmos.circle(forward_target, 2, color, 1);
                }
            }
        }
    }
}
