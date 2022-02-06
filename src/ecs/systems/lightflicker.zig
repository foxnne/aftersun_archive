const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const game = @import("game");
const components = @import("game").components;

pub fn progress(it: *flecs.ecs_iter_t) callconv(.C) void {
    //const world = flecs.World{ .world = it.world.? };

    //const positions = it.term(components.Position, 1);
    //const renderers = it.term(components.LightRenderer, 2);

    var i: usize = 0;
    while (i < it.count) : (i += 1) {

        // var prng = std.rand.DefaultPrng.init(blk: {
        //     var seed: u64 = undefined;
        //     std.os.getrandom(std.mem.asBytes(&seed)) catch unreachable;
        //     break :blk seed;
        // });
        // const random = &prng.random();
        
    
       
    }
}
