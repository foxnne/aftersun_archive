const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const components = @import("../components/components.zig");

const CharacterInput = components.CharacterInput;

pub fn process(it: *flecs.ecs_iter_t) callconv(.C) void {
    var inputs = it.column(CharacterInput, 1);
    var i: usize = 0;
    while (i < it.count) : (i += 1) {
        inputs[i].direction = zia.math.Direction.write(
            zia.input.keyDown(.w),
            zia.input.keyDown(.s),
            zia.input.keyDown(.a),
            zia.input.keyDown(.d),
        );
    }
}
