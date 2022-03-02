const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const game = @import("game");

const components = game.components;
const animations = game.animations;

pub const Callback = struct {
    animator: *components.CharacterAnimator,
    renderer: *components.CharacterRenderer,
    position: *const components.Position,
    velocity: *const components.Velocity,
    body: *components.BodyDirection,
    head: *components.HeadDirection,

    pub const name = "CharacterAnimatorSystem";
    pub const run = progress;
};

fn progress(it: *flecs.Iterator(Callback)) void {
    var world = it.world();

    while (it.next()) |comps| {
        var body = zia.math.Direction.find(8, comps.velocity.x, comps.velocity.y);
        var head = zia.math.Direction.s;

        if (world.getSingleton(components.MouseInput)) |mouse_input| {
            var mousePos = mouse_input.position;
            head = zia.math.Direction.find(8, mousePos.x - comps.position.x, mousePos.y - comps.position.y);
        }

        if (body != .none) { //moving
            comps.body.direction = body;

            if (head == comps.body.direction or head == comps.body.direction.rotateCW() or head == comps.body.direction.rotateCCW()) {
                comps.head.direction = head;
            } else if (comps.head.direction == comps.body.direction or comps.head.direction == comps.body.direction.rotateCW() or comps.head.direction == comps.body.direction.rotateCCW()) {} else {
                comps.head.direction = body;
            }

            comps.animator.bodyAnimation = switch (comps.body.direction) {
                .s => &animations.Walk_S_Body,
                .se, .sw => &animations.Walk_SE_Body,
                .e, .w => &animations.Walk_E_Body,
                .ne, .nw => &animations.Walk_NE_Body,
                .n => &animations.Walk_N_Body,
                .none => unreachable,
            };

            comps.animator.bottomAnimation = switch (comps.body.direction) {
                .s => &animations.Walk_S_BottomF02,
                .se, .sw => &animations.Walk_SE_BottomF02,
                .e, .w => &animations.Walk_E_BottomF02,
                .ne, .nw => &animations.Walk_NE_BottomF02,
                .n => &animations.Walk_N_BottomF02,
                .none => unreachable,
            };

            comps.animator.topAnimation = switch (comps.body.direction) {
                .s => &animations.Walk_S_TopF02,
                .se, .sw => &animations.Walk_SE_TopF02,
                .e, .w => &animations.Walk_E_TopF02,
                .ne, .nw => &animations.Walk_NE_TopF02,
                .n => &animations.Walk_N_TopF02,
                .none => unreachable,
            };

            comps.animator.headAnimation = switch (comps.head.direction) {
                .s => &animations.Walk_S_Head,
                .se, .sw => &animations.Walk_SE_Head,
                .e, .w => &animations.Walk_E_Head,
                .ne, .nw => &animations.Walk_NE_Head,
                .n => &animations.Walk_N_Head,
                .none => unreachable,
            };

            comps.animator.hairAnimation = switch (comps.head.direction) {
                .s => &animations.Walk_S_HairF01,
                .se, .sw => &animations.Walk_SE_HairF01,
                .e, .w => &animations.Walk_E_HairF01,
                .ne, .nw => &animations.Walk_NE_HairF01,
                .n => &animations.Walk_N_HairF01,
                .none => unreachable,
            };

            comps.animator.fps = 12;
            comps.renderer.flipBody = body.flippedHorizontally();

            switch (comps.head.direction) {
                .sw, .w, .nw => comps.renderer.flipHead = true,
                .n, .s => comps.renderer.flipHead = comps.renderer.flipBody,
                else => comps.renderer.flipHead = false,
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

            switch (comps.body.direction) {
                .s => if (r > 50) {
                    comps.body.direction = .se;
                } else {
                    comps.body.direction = .sw;
                    comps.renderer.flipBody = true;
                    comps.renderer.flipHead = true;
                },
                .e => if (r > 50) {
                    comps.body.direction = .se;
                } else {
                    comps.body.direction = .ne;
                },
                .n => if (r > 50) {
                    comps.body.direction = .ne;
                } else {
                    comps.body.direction = .nw;
                    comps.renderer.flipBody = true;
                    comps.renderer.flipHead = true;
                },
                .w => if (r > 50) {
                    comps.body.direction = .nw;
                } else {
                    comps.body.direction = .sw;
                },
                else => {},
            }

            if (head == comps.body.direction or head == comps.body.direction.rotateCW() or head == comps.body.direction.rotateCCW() or head == comps.body.direction.rotateCW().rotateCW() or head == comps.body.direction.rotateCCW().rotateCCW())
                comps.head.direction = head;

            comps.animator.bodyAnimation = switch (comps.body.direction) {
                .se, .sw => &animations.Idle_SE_Body,
                .ne, .nw => &animations.Idle_NE_Body,
                .none => &animations.Idle_SE_Body,
                else => &animations.Idle_SE_Body,
            };

            comps.animator.headAnimation = switch (comps.head.direction) {
                .s => &animations.Idle_S_Head,
                .se, .sw => &animations.Idle_SE_Head,
                .e, .w => &animations.Idle_E_Head,
                .ne, .nw => &animations.Idle_NE_Head,
                .n => &animations.Idle_N_Head,
                .none => &animations.Idle_S_Head,
            };

            comps.animator.bottomAnimation = switch (comps.body.direction) {
                .se, .sw => &animations.Idle_SE_BottomF02,
                .ne, .nw => &animations.Idle_NE_BottomF02,
                .none => &animations.Idle_SE_BottomF02,
                else => &animations.Idle_SE_BottomF02,
            };

            comps.animator.topAnimation = switch (comps.body.direction) {
                .se, .sw => &animations.Idle_SE_TopF02,
                .ne, .nw => &animations.Idle_NE_TopF02,
                .none => &animations.Idle_SE_TopF02,
                else => &animations.Idle_SE_TopF02,
            };

            comps.animator.hairAnimation = switch (comps.head.direction) {
                .s => &animations.Idle_S_HairF01,
                .se, .sw => &animations.Idle_SE_HairF01,
                .e, .w => &animations.Idle_E_HairF01,
                .ne, .nw => &animations.Idle_NE_HairF01,
                .n => &animations.Idle_N_HairF01,
                .none => unreachable,
            };

            comps.animator.fps = 8;

            switch (comps.head.direction) {
                .sw, .w, .nw => comps.renderer.flipHead = true,
                .n, .s => comps.renderer.flipHead = comps.renderer.flipBody,
                else => comps.renderer.flipHead = false,
            }
        }
    }
}
