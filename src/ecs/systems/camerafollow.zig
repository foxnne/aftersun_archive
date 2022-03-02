const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const game = @import("game");
const components = game.components;

pub const Callback = struct {
    follow: *components.Follow,
    position: *const components.Position,
    velocity: *components.Velocity,

    pub const name = "CameraFollowSystem";
    pub const run = progress;
    pub const modifiers = .{ flecs.queries.Filter(components.Camera )};
};

fn progress(it: *flecs.Iterator(Callback)) void {   
    while (it.next()) |comps| {
        if (comps.follow.target.get(components.Position)) |tp| {
            var camera_position = zia.math.Vector2{ .x = comps.position.x, .y = comps.position.y};
            var target_position = zia.math.Vector2{ .x = tp.x, .y = tp.y };
            var velocity_direction: zia.math.Direction = zia.math.Direction.none;
            var body_direction: zia.math.Direction = zia.math.Direction.none;
            var head_direction: zia.math.Direction = zia.math.Direction.none;

            if (comps.follow.target.get(components.Velocity)) |tv| {
                velocity_direction = zia.math.Direction.find(8, tv.x, tv.y);
            }

            if (comps.follow.target.get(components.BodyDirection)) |fd| {
                body_direction = fd.direction;
            }

            if (comps.follow.target.get(components.HeadDirection)) |hd| {
                head_direction = hd.direction;
            }

            if (velocity_direction != .none) {
                var vec = body_direction.normalized();

                var forward_target = target_position.add(vec.scale(comps.follow.max_distance));
                forward_target = forward_target.add(head_direction.normalized().scale(comps.follow.min_distance));

                var difference = forward_target.subtract(camera_position);

                comps.velocity.x = difference.x * comps.follow.easing * 1.2;
                comps.velocity.y = difference.y * comps.follow.easing * 1.2;

            } else {
                var vec = head_direction.normalized();
                var forward_target = target_position.add(vec.scale(comps.follow.min_distance));

                var difference = forward_target.subtract(camera_position);

                comps.velocity.x = difference.x * comps.follow.easing * 2;
                comps.velocity.y = difference.y * comps.follow.easing * 2;

            }
        }
    }
}
