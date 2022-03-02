const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const components = @import("game").components;

pub const Callback = struct {
    input: *components.MovementInput,

    pub const name = "MovementInputSystem";
    pub const run = progress;
};

fn progress(it: *flecs.Iterator(Callback)) void {
    while (it.next()) |comps| {
        comps.input.direction = zia.math.Direction.write(
            zia.input.keyDown(.w) or zia.input.keyDown(.up),
            zia.input.keyDown(.s) or zia.input.keyDown(.down),
            zia.input.keyDown(.a) or zia.input.keyDown(.left),
            zia.input.keyDown(.d) or zia.input.keyDown(.right),
        );
    }
}
