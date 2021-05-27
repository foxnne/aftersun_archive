const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const components = @import("game").components;

pub fn progress(it: *flecs.ecs_iter_t) callconv(.C) void {
    var input = it.column(components.MovementInput, 1);

    input.*.direction = zia.math.Direction.write(
        zia.input.keyDown(.w) or zia.input.keyDown(.up),
        zia.input.keyDown(.s) or zia.input.keyDown(.down),
        zia.input.keyDown(.a) or zia.input.keyDown(.left),
        zia.input.keyDown(.d) or zia.input.keyDown(.right),
    );
}
