const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const components = @import("game").components;

pub const Callback = struct {
    animator: *components.CharacterAnimator,
    renderer: *components.CharacterRenderer,

    pub const name = "CharacterAnimationSystem";
    pub const run = progress;
};

fn progress(it: *flecs.Iterator(Callback)) void {
    while (it.next()) |comps| {
        comps.animator.elapsed += zia.time.dt();

        if (comps.animator.elapsed > (1 / @intToFloat(f32, comps.animator.fps))) {
            comps.animator.elapsed = 0;

            if (comps.animator.frame < comps.animator.bodyAnimation.len - 1) {
                comps.animator.frame += 1;
            } else comps.animator.frame = 0;
        }
        comps.renderer.headIndex = comps.animator.headAnimation[comps.animator.frame];
        comps.renderer.bodyIndex = comps.animator.bodyAnimation[comps.animator.frame];
        comps.renderer.bottomIndex = comps.animator.bottomAnimation[comps.animator.frame];
        comps.renderer.topIndex = comps.animator.topAnimation[comps.animator.frame];
        comps.renderer.hairIndex = comps.animator.hairAnimation[comps.animator.frame];
    }
}
