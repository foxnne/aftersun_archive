const zia = @import("zia");
const flecs = @import("flecs");
const lucid = @import("lucid");
const components = lucid.components;

const Position = components.Position;
const Collider = components.Collider;
const Velocity = components.Velocity;
const Subpixel = components.Subpixel;

pub fn collide(query: ?*flecs.ecs_query_t) void {
    var it = flecs.ecs_query_iter(query);
    while (flecs.ecs_query_next(&it)) {
        var positions = it.column(Position, 1);
        var colliders = it.column(Collider, 2);

        var velPtr = flecs.ecs_column_w_size(&it, @sizeOf(Velocity), 3);
        var velocities = @ptrCast(?[*]Velocity, @alignCast(@alignOf(Velocity), velPtr));

        var subPtr = flecs.ecs_column_w_size(&it, @sizeOf(Subpixel), 4);
        var subpixels = @ptrCast(?[*]Subpixel, @alignCast(@alignOf(Subpixel), subPtr));

        var i: usize = 0;
        while (i < it.count) : (i += 1) {

            if (velPtr != null) {

                
            }

            if (lucid.gizmos.enabled) {
                if (colliders[i].shape == .circle)
                {
                    var cen = .{.x = positions[i].x + colliders[i].x, .y = positions[i].y + colliders[i].y};
                    lucid.gizmos.circle(cen, colliders[i].width / 2, zia.math.Color.green, 1);
                }else {
                    var cen = .{.x = positions[i].x + colliders[i].x, .y = positions[i].y + colliders[i].y};
                    lucid.gizmos.box(cen, colliders[i].width, colliders[i].height, zia.math.Color.green, 1);
                }
            }
            
        }
    }
}
