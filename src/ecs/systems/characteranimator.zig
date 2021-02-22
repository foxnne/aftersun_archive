
const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const lucid = @import("lucid");

const components = lucid.components;
const animations = lucid.animations;

pub fn progress(it: *flecs.ecs_iter_t) callconv(.C) void {
    var world = flecs.World{ .world = it.world.? };
    var animators = it.column(components.CharacterAnimator, 1);
    var renderers = it.column(components.CharacterRenderer, 2);
    var positions = it.column(components.Position, 3);
    var velocities = it.column(components.Velocity, 4);
    var bodies = it.column(components.BodyDirection, 5);
    var heads = it.column(components.HeadDirection, 6);

    var i: usize = 0;
    while (i < it.count) : (i += 1) {
        var body = zia.math.Direction.find(8, velocities[i].x, velocities[i].y);

        // get camera matrix to find mouse position
        var mouseInput = world.getSingleton(components.MouseInput);
        var mousePos = mouseInput.?.position;

        var head = zia.math.Direction.find(8, mousePos.x - positions[i].x, mousePos.y - positions[i].y);

        if (body != .None) { //moving
            bodies[i].direction = body;

            if (head == body or head == body.rotateCW() or head == body.rotateCCW()) {
                heads[i].direction = head;
            } else {
                heads[i].direction = body;
            }

            animators[i].bodyAnimation = switch (bodies[i].direction) {
                .S => &animations.walkBodyS,
                .SE, .SW => &animations.walkBodySE,
                .E, .W => &animations.walkBodyE,
                .NE, .NW => &animations.walkBodyNE,
                .N => &animations.walkBodyN,
                .None => unreachable,
            };

            animators[i].headAnimation = switch (heads[i].direction) {
                .S => &animations.walkHeadS,
                .SE, .SW => &animations.walkHeadSE,
                .E, .W => &animations.walkHeadE,
                .NE, .NW => &animations.walkHeadNE,
                .N => &animations.walkHeadN,
                .None => unreachable,
            };

            

            animators[i].fps = 10;
            renderers[i].flipX = body.flippedHorizontally();

            switch (heads[i].direction) {
                .SW, .W, .NW => renderers[i].flipX = true,
                else => {}
            }
        } else { //idle

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

            if (head == bodies[i].direction or head == bodies[i].direction.rotateCW() or head == bodies[i].direction.rotateCCW())
                heads[i].direction = head;

            animators[i].bodyAnimation = switch (bodies[i].direction) {
                .SE, .SW => &animations.idleBodySE,
                .NE, .NW => &animations.idleBodyNE,
                .None => &animations.idleBodySE,
                else => &animations.idleBodySE,
            };

            animators[i].headAnimation = switch (heads[i].direction) {
                .S => &animations.idleHeadS,
                .SE, .SW => &animations.idleHeadSE,
                .E, .W => &animations.idleHeadE,
                .NE, .NW => &animations.idleHeadNE,
                .N => &animations.idleHeadN,
                .None => &animations.idleHeadS,
            };

            animators[i].fps = 8;
        }

        if (lucid.gizmos.enabled) {
            //const pos_ptr = world.get(it.entities[i], components.Position);
            lucid.gizmos.line(.{ .x = positions[i].x, .y = positions[i].y }, bodies[i].direction.normalized().scale(20).add(.{ .x = positions[i].x, .y = positions[i].y }), zia.math.Color.red, 2);
            lucid.gizmos.line(.{ .x = positions[i].x, .y = positions[i].y }, heads[i].direction.normalized().scale(20).add(.{ .x = positions[i].x, .y = positions[i].y }), zia.math.Color.blue, 2);
        }
    }
}
