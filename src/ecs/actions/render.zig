const zia = @import("zia");
const flecs = @import("flecs");
const lucid = @import("lucid");
const components = lucid.components;

const Position = components.Position;
const SpriteRenderer = components.SpriteRenderer;
const Color = components.Color;

pub fn render(query: ?*flecs.ecs_query_t) void {
    var it = flecs.ecs_query_iter(query);
    while (flecs.ecs_query_next(&it)) {
        var positions = it.column(Position, 1);
        var renderers = it.column(SpriteRenderer, 2);

        var colPtr = flecs.ecs_column_w_size(&it, @sizeOf(Color), 3);
        var colors = @ptrCast(?[*]Color, @alignCast(@alignOf(Color), colPtr));

        var i: usize = 0;
        while (i < it.count) : (i += 1) {
            if (colPtr != null) {
                zia.gfx.draw.sprite(renderers[i].atlas.sprites[renderers[i].index], renderers[i].texture, .{
                    .x = positions[i].x,
                    .y = positions[i].y,
                }, .{
                    .color = colors.?[i].color,
                    .flipX = renderers[i].flipX,
                    .flipY = renderers[i].flipY,
                });
            } else {
                zia.gfx.draw.sprite(renderers[i].atlas.sprites[renderers[i].index], renderers[i].texture, .{
                    .x = positions[i].x,
                    .y = positions[i].y,
                }, .{
                    .flipX = renderers[i].flipX,
                    .flipY = renderers[i].flipY,
                });
            }
        }
    }
}
