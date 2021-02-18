const flecs = @import("flecs");
const components = @import("lucid").components;

// sort renderers by y position
pub fn sortY(e1: flecs.ecs_entity_t, p1: ?*const c_void, e2: flecs.ecs_entity_t, p2: ?*const c_void) callconv(.C) c_int {
    var pos1 = @ptrCast(?*const components.Position, @alignCast(@alignOf(components.Position), p1)).?;
    var pos2 = @ptrCast(?*const components.Position, @alignCast(@alignOf(components.Position), p2)).?;

    if (pos1.z == pos2.z) {
        return @boolToInt(pos1.y > pos2.y);
    } else {
        return @boolToInt(pos1.z > pos2.z);
    }
}