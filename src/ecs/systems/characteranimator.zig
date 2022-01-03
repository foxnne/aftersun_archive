const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const game = @import("game");

const components = game.components;
const animations = game.animations;

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

        if (body != .none) { //moving
            bodies[i].direction = body;

            if (head == bodies[i].direction or head == bodies[i].direction.rotateCW() or head == bodies[i].direction.rotateCCW()) {
                heads[i].direction = head;
            } else if (heads[i].direction == bodies[i].direction or heads[i].direction == bodies[i].direction.rotateCW() or heads[i].direction == bodies[i].direction.rotateCCW()) {} else {
                heads[i].direction = body;
            }

            animators[i].bodyAnimation = switch (bodies[i].direction) {
                .s => &animations.walkBodyS,
                .se, .sw => &animations.walkBodySE,
                .e, .w => &animations.walkBodyE,
                .ne, .nw => &animations.walkBodyNE,
                .n => &animations.walkBodyN,
                .none => unreachable,
            };

            animators[i].bottomAnimation = switch (bodies[i].direction) {
                .s => &animations.walkBottomF01S,
                .se, .sw => &animations.walkBottomF01SE,
                .e, .w => &animations.walkBottomF01E,
                .ne, .nw => &animations.walkBottomF01NE,
                .n => &animations.walkBottomF01N,
                .none => unreachable,
            };

            animators[i].topAnimation = switch (bodies[i].direction) {
                .s => &animations.walkTopF01S,
                .se, .sw => &animations.walkTopF01SE,
                .e, .w => &animations.walkTopF01E,
                .ne, .nw => &animations.walkTopF01NE,
                .n => &animations.walkTopF01N,
                .none => unreachable,
            };

            animators[i].headAnimation = switch (heads[i].direction) {
                .s => &animations.walkHeadS,
                .se, .sw => &animations.walkHeadSE,
                .e, .w => &animations.walkHeadE,
                .ne, .nw => &animations.walkHeadNE,
                .n => &animations.walkHeadN,
                .none => unreachable,
            };

            animators[i].hairAnimation = switch (heads[i].direction) {
                .s => &animations.walkHairF01S,
                .se, .sw => &animations.walkHairF01SE,
                .e, .w => &animations.walkHairF01E,
                .ne, .nw => &animations.walkHairF01NE,
                .n => &animations.walkHairF01N,
                .none => unreachable,
            };

            animators[i].fps = 10;
            renderers[i].flipBody = body.flippedHorizontally();

            switch (heads[i].direction) {
                .sw,
                .w,
                .nw,
                => renderers[i].flipHead = true,
                .n, .s => renderers[i].flipHead = renderers[i].flipBody,
                else => renderers[i].flipHead = false,
            }
        } else { //idle

            // get random number to decide body direction
            // when the direction is ortho
            var prng = std.rand.DefaultPrng.init(blk: {
                var seed: u64 = undefined;
                std.os.getrandom(std.mem.asBytes(&seed)) catch unreachable;
                break :blk seed;
            });
            const rand = &prng.random();
    
            var r = rand.intRangeAtMost(usize, 0, 100);

            switch (bodies[i].direction) {
                .s => if (r > 50) {
                    bodies[i].direction = .se;
                } else {
                    bodies[i].direction = .sw;
                    renderers[i].flipBody = true;
                    renderers[i].flipHead = true;
                },
                .e => if (r > 50) {
                    bodies[i].direction = .se;
                } else {
                    bodies[i].direction = .ne;
                },
                .n => if (r > 50) {
                    bodies[i].direction = .ne;
                } else {
                    bodies[i].direction = .nw;
                    renderers[i].flipBody = true;
                    renderers[i].flipHead = true;
                },
                .w => if (r > 50) {
                    bodies[i].direction = .nw;
                } else {
                    bodies[i].direction = .sw;
                },
                else => {},
            }

            if (head == bodies[i].direction or head == bodies[i].direction.rotateCW() or head == bodies[i].direction.rotateCCW() or head == bodies[i].direction.rotateCW().rotateCW() or head == bodies[i].direction.rotateCCW().rotateCCW())
                heads[i].direction = head;

            animators[i].bodyAnimation = switch (bodies[i].direction) {
                .se, .sw => &animations.idleBodySE,
                .ne, .nw => &animations.idleBodyNE,
                .none => &animations.idleBodySE,
                else => &animations.idleBodySE,
            };

            animators[i].headAnimation = switch (heads[i].direction) {
                .s => &animations.idleHeadS,
                .se, .sw => &animations.idleHeadSE,
                .e, .w => &animations.idleHeadE,
                .ne, .nw => &animations.idleHeadNE,
                .n => &animations.idleHeadN,
                .none => &animations.idleHeadS,
            };

            animators[i].bottomAnimation = switch (bodies[i].direction) {
                .se, .sw => &animations.idleBottomF01SE,
                .ne, .nw => &animations.idleBottomF01NE,
                .none => &animations.idleBottomF01SE,
                else => &animations.idleBottomF01SE,
            };

            animators[i].topAnimation = switch (bodies[i].direction) {
                .se, .sw => &animations.idleTopF01SE,
                .ne, .nw => &animations.idleTopF01NE,
                .none => &animations.idleTopF01SE,
                else => &animations.idleTopF01SE,
            };

            animators[i].hairAnimation = switch (heads[i].direction) {
                .s => &animations.idleHairF01S,
                .se, .sw => &animations.idleHairF01SE,
                .e, .w => &animations.idleHairF01E,
                .ne, .nw => &animations.idleHairF01NE,
                .n => &animations.idleHairF01N,
                .none => unreachable,
            };

            animators[i].fps = 8;

            switch (heads[i].direction) {
                .sw, .w, .nw => renderers[i].flipHead = true,
                .n, .s => renderers[i].flipHead = renderers[i].flipBody,
                else => renderers[i].flipHead = false,
            }
        }

        // if (game.gizmos.enabled) {
        //     //const pos_ptr = world.get(it.entities[i], components.Position);
        //     game.gizmos.line(.{ .x = positions[i].x, .y = positions[i].y }, bodies[i].direction.normalized().scale(20).add(.{ .x = positions[i].x, .y = positions[i].y }), zia.math.Color.red, 2);
        //     game.gizmos.line(.{ .x = positions[i].x, .y = positions[i].y }, heads[i].direction.normalized().scale(20).add(.{ .x = positions[i].x, .y = positions[i].y }), zia.math.Color.blue, 2);
        // }
    }
}
