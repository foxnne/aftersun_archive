const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const components = @import("game").components;

pub const Callback = struct {
    movement: ?*components.MovementCooldown,
    use: ?*components.UseCooldown,

    pub const name = "CooldownSystem";
    pub const run = progress;
};

fn progress(it: *flecs.Iterator(Callback)) void {
    while (it.next()) |comps| {

        //movement
        if (comps.movement) |movement_cooldown| {
            if (movement_cooldown.current < movement_cooldown.end) {
                movement_cooldown.current += it.iter.delta_time;

                if (movement_cooldown.current > movement_cooldown.end)
                    movement_cooldown.current = movement_cooldown.end;
            }
        }

        //use
        if (comps.use) |use_cooldown| {
            if (use_cooldown.current < use_cooldown.end) {
                use_cooldown.current += it.iter.delta_time;

                if (use_cooldown.current > use_cooldown.end)
                    use_cooldown.current = use_cooldown.end;
            }
        }
    }
}
