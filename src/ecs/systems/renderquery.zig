const zia = @import("zia");
const flecs = @import("flecs");
const lucid = @import("lucid");
const imgui = @import("imgui");

const components = lucid.components;
const actions = lucid.actions;
const sorters = lucid.sorters;

pub fn progress(it: *flecs.ecs_iter_t) callconv(.C) void {
    var positions = it.column(components.Position, 1);
    var cameras = it.column(components.Camera, 2);
    var renderqueues = it.column(components.RenderQueue, 3);

    var world = flecs.World{ .world = it.world.? };

    var i: usize = 0;
    while (i < it.count) : (i += 1) {

        var renderIt = flecs.ecs_query_iter(renderqueues[i].query);

        while (flecs.ecs_query_next(&renderIt)) {

            var j: usize = 0;
            while (j < renderIt.count) : (j += 1) {

                // TODO: check against the camera bounds that the entity would even be drawn?
                // TODO: ensure that this entity has a renderer at all? or handle with flecs tables?

                renderqueues[i].entities.append(renderIt.entities[j]) catch unreachable;
            }
        }
        
    }
}
