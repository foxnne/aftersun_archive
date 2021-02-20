const zia = @import("zia");
const flecs = @import("flecs");
const lucid = @import("lucid");
const components = lucid.components;

pub fn render(query: ?*flecs.ecs_query_t) void {
    var it = flecs.ecs_query_iter(query);
    while (flecs.ecs_query_next(&it)) {
        var world = flecs.World{ .world = it.world.? };
        var positions = it.column(components.Position, 1);
        var renderers = it.column(components.SpriteRenderer, 2);

        var i: usize = 0;
        while (i < it.count) : (i += 1) {
            const colPtr = world.get(it.entities[i], components.Color);

            zia.gfx.draw.sprite(renderers[i].atlas.sprites[renderers[i].index], renderers[i].texture, .{
                .x = positions[i].x,
                .y = positions[i].y,
            }, .{
                .color = if (colPtr) |col| col.color else zia.math.Color.white,
                .flipX = renderers[i].flipX,
                .flipY = renderers[i].flipY,
            });
        }
    }
}
