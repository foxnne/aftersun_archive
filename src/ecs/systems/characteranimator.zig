const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const lucid = @import("lucid");

const components = lucid.components;
const animations = lucid.animations;

pub fn progress(it: *flecs.ecs_iter_t) callconv(.C) void {
    var world = flecs.World{ .world = it.world.? };
    var animators = it.column(components.SpriteAnimator, 1);
    var renderers = it.column(components.SpriteRenderer, 2);
    var velocities = it.column(components.Velocity, 3);
    var bodies = it.column(components.BodyDirection, 4);
    var heads = it.column(components.HeadDirection, 5);

    var i: usize = 0;
    while (i < it.count) : (i += 1) {
        var body = zia.math.Direction.find(8, velocities[i].x, velocities[i].y);

        if (body != .None) {
            bodies[i].direction = body;

            animators[i].animation = switch (body) {
                .S => &animations.walk_S,
                .SE, .SW => &animations.walk_SE,
                .E, .W => &animations.walk_E,
                .NE, .NW => &animations.walk_NE,
                .N => &animations.walk_N,
                .None => unreachable,
            };

            animators[i].fps = 10;
            renderers[i].flipX = body.flippedHorizontally();
        } else {

            // get random number to decide body direction
            // when the direction is ortho
            var prng = std.rand.DefaultPrng.init(blk: {
                var seed: u64 = undefined;
                std.os.getrandom(std.mem.asBytes(&seed)) catch unreachable;
                break :blk seed;
            });
            const rand = &prng.random;
            var r = rand.intRangeAtMost(usize, 0, 100);

            switch (bodies[i].direction) {
                .S => if (r > 50) {
                    bodies[i].direction = .SE;
                } else {
                    bodies[i].direction = .SW;
                    renderers[i].flipX = true;
                },
                .E => if (r > 50) {
                    bodies[i].direction = .SE;
                } else {
                    bodies[i].direction = .NE;
                },
                .N => if (r > 50) {
                    bodies[i].direction = .NE;
                } else {
                    bodies[i].direction = .NW;
                    renderers[i].flipX = true;
                },
                .W => if (r > 50) {
                    bodies[i].direction = .NW;
                } else {
                    bodies[i].direction = .SW;
                },
                else => {},
            }

            animators[i].animation = switch (bodies[i].direction) {
                .SE, .SW => &animations.idle_SE,
                .NE, .NW => &animations.idle_NE,
                .None => &animations.idle_SE,
                else => &animations.idle_SE,
            };
            animators[i].fps = 8;
        }

        if (lucid.gizmos.enabled) {
            const pos_ptr = world.get(it.entities[i], components.Position);
            if (pos_ptr) |pos| {
                lucid.gizmos.line(.{ .x = pos.x, .y = pos.y }, bodies[i].direction.normalized().scale(20).add(.{ .x = pos.x, .y = pos.y }), zia.math.Color.red, 2);
            }
        }
    }
}
