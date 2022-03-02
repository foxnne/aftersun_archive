const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const components = @import("game").components;

pub const Callback = struct {
    animator: *components.SpriteAnimator,
    renderer: *components.SpriteRenderer,

    pub const name = "SpriteAnimationSystem";
    pub const run = progress;
};

fn progress(it: *flecs.Iterator(Callback)) void {
    while (it.next()) |comps| {
        if (comps.animator.state == components.SpriteAnimator.State.play) {
            comps.animator.elapsed += zia.time.dt();

            if (comps.animator.elapsed > (1 / @intToFloat(f32, comps.animator.fps))) {
                comps.animator.elapsed = 0;

                if (comps.animator.frame < comps.animator.animation.len - 1) {
                    comps.animator.frame += 1;
                } else comps.animator.frame = 0;
            }
        }
        comps.renderer.index = comps.animator.animation[comps.animator.frame];
    }
}
