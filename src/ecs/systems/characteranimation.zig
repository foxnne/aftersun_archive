const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const components = @import("game").components;

pub fn progress(it: *flecs.ecs_iter_t) callconv(.C) void {
    const animators = it.term(components.CharacterAnimator, 1);
    const renderers = it.term(components.CharacterRenderer, 2);

    var i: usize = 0;
    while (i < it.count) : (i += 1) {
        animators[i].elapsed += zia.time.dt();

        if (animators[i].elapsed > (1 / @intToFloat(f32, animators[i].fps))) {
            animators[i].elapsed = 0;

            if (animators[i].frame < animators[i].bodyAnimation.len - 1) {
                animators[i].frame += 1;
            } else animators[i].frame = 0;
        }
        renderers[i].head = animators[i].headAnimation[animators[i].frame];
        renderers[i].body = animators[i].bodyAnimation[animators[i].frame];
        renderers[i].bottom = animators[i].bottomAnimation[animators[i].frame];
        renderers[i].top = animators[i].topAnimation[animators[i].frame];
        renderers[i].hair = animators[i].hairAnimation[animators[i].frame];
    }
}
