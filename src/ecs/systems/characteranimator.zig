const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const game = @import("game");

const components = game.components;
const animations = game.animations;

pub fn progress(it: *flecs.ecs_iter_t) callconv(.C) void {
    var world = flecs.World{ .world = it.world.? };
    var animators = it.term(components.CharacterAnimator, 1);
    var renderers = it.term(components.CharacterRenderer, 2);
    var positions = it.term(components.Position, 3);
    var velocities = it.term(components.Velocity, 4);
    var bodies = it.term(components.BodyDirection, 5);
    var heads = it.term(components.HeadDirection, 6);

    var i: usize = 0;
    while (i < it.count) : (i += 1) {
        var body = zia.math.Direction.find(8, velocities[i].x, velocities[i].y);

        var head = zia.math.Direction.s;

        if (world.getSingleton(components.MouseInput)) |mouse_input| {
            var mousePos = mouse_input.position;
            head = zia.math.Direction.find(8, mousePos.x - positions[i].x, mousePos.y - positions[i].y);
        }

        if (body != .none) { //moving
            bodies[i].direction = body;

            if (head == bodies[i].direction or head == bodies[i].direction.rotateCW() or head == bodies[i].direction.rotateCCW()) {
                heads[i].direction = head;
            } else if (heads[i].direction == bodies[i].direction or heads[i].direction == bodies[i].direction.rotateCW() or heads[i].direction == bodies[i].direction.rotateCCW()) {} else {
                heads[i].direction = body;
            }

            animators[i].bodyAnimation = switch (bodies[i].direction) {
                .s => &animations.Walk_S_Body,
                .se, .sw => &animations.Walk_SE_Body,
                .e, .w => &animations.Walk_E_Body,
                .ne, .nw => &animations.Walk_NE_Body,
                .n => &animations.Walk_N_Body,
                .none => unreachable,
            };

            animators[i].bottomAnimation = switch (bodies[i].direction) {
                .s => &animations.Walk_S_BottomF01,
                .se, .sw => &animations.Walk_SE_BottomF01,
                .e, .w => &animations.Walk_E_BottomF01,
                .ne, .nw => &animations.Walk_NE_BottomF01,
                .n => &animations.Walk_N_BottomF01,
                .none => unreachable,
            };

            animators[i].topAnimation = switch (bodies[i].direction) {
                .s => &animations.Walk_S_TopF01,
                .se, .sw => &animations.Walk_SE_TopF01,
                .e, .w => &animations.Walk_E_TopF01,
                .ne, .nw => &animations.Walk_NE_TopF01,
                .n => &animations.Walk_N_TopF01,
                .none => unreachable,
            };

            animators[i].headAnimation = switch (heads[i].direction) {
                .s => &animations.Walk_S_Head,
                .se, .sw => &animations.Walk_SE_Head,
                .e, .w => &animations.Walk_E_Head,
                .ne, .nw => &animations.Walk_NE_Head,
                .n => &animations.Walk_N_Head,
                .none => unreachable,
            };

            animators[i].hairAnimation = switch (heads[i].direction) {
                .s => &animations.Walk_S_HairF01,
                .se, .sw => &animations.Walk_SE_HairF01,
                .e, .w => &animations.Walk_E_HairF01,
                .ne, .nw => &animations.Walk_NE_HairF01,
                .n => &animations.Walk_N_HairF01,
                .none => unreachable,
            };

            animators[i].fps = 8;
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
                .se, .sw => &animations.Idle_SE_Body,
                .ne, .nw => &animations.Idle_NE_Body,
                .none => &animations.Idle_SE_Body,
                else => &animations.Idle_SE_Body,
            };

            animators[i].headAnimation = switch (heads[i].direction) {
                .s => &animations.Idle_S_Head,
                .se, .sw => &animations.Idle_SE_Head,
                .e, .w => &animations.Idle_E_Head,
                .ne, .nw => &animations.Idle_NE_Head,
                .n => &animations.Idle_N_Head,
                .none => &animations.Idle_S_Head,
            };

            animators[i].bottomAnimation = switch (bodies[i].direction) {
                .se, .sw => &animations.Idle_SE_BottomF01,
                .ne, .nw => &animations.Idle_NE_BottomF01,
                .none => &animations.Idle_SE_BottomF01,
                else => &animations.Idle_SE_BottomF01,
            };

            animators[i].topAnimation = switch (bodies[i].direction) {
                .se, .sw => &animations.Idle_SE_TopF01,
                .ne, .nw => &animations.Idle_NE_TopF01,
                .none => &animations.Idle_SE_TopF01,
                else => &animations.Idle_SE_TopF01,
            };

            animators[i].hairAnimation = switch (heads[i].direction) {
                .s => &animations.Idle_S_HairF01,
                .se, .sw => &animations.Idle_SE_HairF01,
                .e, .w => &animations.Idle_E_HairF01,
                .ne, .nw => &animations.Idle_NE_HairF01,
                .n => &animations.Idle_N_HairF01,
                .none => unreachable,
            };

            animators[i].fps = 8;

            switch (heads[i].direction) {
                .sw, .w, .nw => renderers[i].flipHead = true,
                .n, .s => renderers[i].flipHead = renderers[i].flipBody,
                else => renderers[i].flipHead = false,
            }
        }
    }
}
