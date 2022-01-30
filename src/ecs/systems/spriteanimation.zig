const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const components = @import("game").components;

pub fn progress(it: *flecs.ecs_iter_t) callconv(.C) void {
    const animators = it.term(components.SpriteAnimator, 1);
    const renderers = it.term(components.SpriteRenderer, 2);

    var i: usize = 0;
    while (i < it.count) : (i += 1) {
        if (animators[i].state == components.SpriteAnimator.State.play) {
            animators[i].elapsed += zia.time.dt();

            if (animators[i].elapsed > (1 / @intToFloat(f32, animators[i].fps))) {
                animators[i].elapsed = 0;

                if (animators[i].frame < animators[i].animation.len - 1) {
                    animators[i].frame += 1;
                } else animators[i].frame = 0;
            }
        }
        renderers[i].index = animators[i].animation[animators[i].frame];
    }
}
