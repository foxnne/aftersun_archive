const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const components = @import("../components/components.zig");

pub fn process(it: *flecs.ecs_iter_t) callconv(.C) void {
    var inputs = it.column(components.CharacterInput, 1);
    var i: usize = 0;
    while (i < it.count) : (i += 1) {
        inputs[i].direction = zia.math.Direction.write(
            zia.input.keyDown(.w) or zia.input.keyDown(.up),
            zia.input.keyDown(.s) or zia.input.keyDown(.down),
            zia.input.keyDown(.a) or zia.input.keyDown(.left),
            zia.input.keyDown(.d) or zia.input.keyDown(.right),
        );
    }
}
