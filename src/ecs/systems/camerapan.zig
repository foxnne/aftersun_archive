const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const lucid = @import("lucid");
const components = lucid.components;

pub fn progress(it: *flecs.ecs_iter_t) callconv(.C) void {
    var positions = it.column(components.Position, 2);
    //var inputs = it.column(components.PanInput, 2);
    var velocities = it.column(components.Velocity, 3);

    var world = flecs.World{ .world = it.world.? };

    var panInputPtr = world.getSingleton(components.PanInput);

    var speed: f32 = 80;

    if (panInputPtr) |panInput| {

        var i: usize = 0;
        while (i < it.count) : (i += 1) {
            //var world = flecs.World{ .world = it.world.? };
            var pan_direction = panInput.direction.vector2();

            var follow_ptr = world.get(it.entities[i], components.Follow);

            if (follow_ptr) |follow| {
                //const follow = @ptrCast(*const components.Follow, @alignCast(@alignOf(components.Follow), fol_ptr));

                var target_position_ptr = flecs.ecs_get_w_entity(world.world, follow.target, world.newComponent(components.Position));

                if (target_position_ptr) |pos_ptr| {
                    const target_position = @ptrCast(*const components.Position, @alignCast(@alignOf(components.Position), pos_ptr));
                    const target_distance = zia.math.Vector2.distance(.{ .x = target_position.x, .y = target_position.y }, .{ .x = positions[i].x, .y = positions[i].y });

                    if (target_distance < follow.max_distance) {
                        velocities[i].x += pan_direction.x * zia.time.dt() * follow.speed;
                        velocities[i].y += pan_direction.y * zia.time.dt() * follow.speed;
                    }
                }
            } else {
                velocities[i].x += pan_direction.x * zia.time.dt() * speed;
                velocities[i].y += pan_direction.y * zia.time.dt() * speed;
            }
        }
    }
}
