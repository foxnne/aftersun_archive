const std = @import("std");
const zia = @import("zia");
const imgui = @import("imgui");
const Color = zia.math.Color;
const Direction = zia.math.Direction;

// generated
const assets = @import("assets.zig");
const shaders = @import("shaders.zig");

var camera: zia.utils.Camera = undefined;

var mouse_direction: Direction = .None;
var keyboard_direction: Direction = .None;

var body_direction: Direction = .S;
var head_direction: Direction = .S;

var palette: zia.gfx.Texture = undefined;
var texture: zia.gfx.Texture = undefined;
var atlas: zia.gfx.Atlas = undefined;

var spritePaletteShader: zia.gfx.Shader = undefined;

var position: zia.math.Vector2 = .{};
var mouse_position: zia.math.Vector2 = .{};

var bodyIndex: usize = 0;
var headIndex: usize = 0;

pub fn main() !void {
    try zia.run(.{
        .init = init,
        .update = update,
        .render = render,
        .shutdown = shutdown,
    });
}

fn init() !void {
    palette = zia.gfx.Texture.initFromFile(std.testing.allocator, assets.characterpalette_png.path, .nearest) catch unreachable;
    texture = zia.gfx.Texture.initFromFile(std.testing.allocator, assets.character_png.path, .nearest) catch unreachable;
    atlas = zia.gfx.Atlas.initFromFile(std.testing.allocator, assets.character_atlas.path) catch unreachable;

    camera = zia.utils.Camera.init();
    const size = zia.window.size();
    camera.zoom = 3;

    spritePaletteShader = shaders.createSpritePaletteShader() catch unreachable;
}

fn update() !void {
    keyboard_direction = Direction.write(zia.input.keyDown(.w), zia.input.keyDown(.s), zia.input.keyDown(.a), zia.input.keyDown(.d));
    body_direction = keyboard_direction;
    position = position.add(keyboard_direction.normalized().scale(20 * zia.time.rawDeltaTime()));

    mouse_position = camera.screenToWorld(zia.input.mousePos());
    mouse_direction = Direction.find(8, mouse_position.x - position.x, mouse_position.y - position.y);
    head_direction = mouse_direction;
}

fn render() !void {
    zia.gfx.beginPass(.{ .color = Color.zia, .trans_mat = camera.transMat() });

    zia.gfx.draw.line(position, position.add(body_direction.normalized().scale(100)), 2, Color.red);
    zia.gfx.draw.line(position, position.add(head_direction.normalized().scale(100)), 2, Color.blue);

    zia.gfx.draw.bindTexture(palette, 1);

    zia.gfx.setShader(&spritePaletteShader);

    bodyIndex = switch (body_direction) {
        .S => assets.character_atlas.Body_RotationClothed_0,
        .SE => assets.character_atlas.Body_RotationClothed_1,
        .E => assets.character_atlas.Body_RotationClothed_2,
        .NE => assets.character_atlas.Body_RotationClothed_3,
        .N => assets.character_atlas.Body_RotationClothed_4,
        .NW => assets.character_atlas.Body_RotationClothed_3,
        .W => assets.character_atlas.Body_RotationClothed_2,
        .SW => assets.character_atlas.Body_RotationClothed_1,
        else => assets.character_atlas.Body_RotationClothed_0,
    };

    headIndex = switch (head_direction) {
        .S => assets.character_atlas.Head_RotationClothed_0,
        .SE => assets.character_atlas.Head_RotationClothed_1,
        .E => assets.character_atlas.Head_RotationClothed_2,
        .NE => assets.character_atlas.Head_RotationClothed_3,
        .N => assets.character_atlas.Head_RotationClothed_4,
        .NW => assets.character_atlas.Head_RotationClothed_3,
        .W => assets.character_atlas.Head_RotationClothed_2,
        .SW => assets.character_atlas.Head_RotationClothed_1,
        else => assets.character_atlas.Head_RotationClothed_0,
    };

    zia.gfx.draw.sprite(atlas.sprites[bodyIndex], texture, position.add(.{ .x = -30, .y = 0 }), .{
        .flipHorizontally = body_direction.flippedHorizontally(),
        .color = zia.math.Color.fromBytes(9, 0, 2, 255),
    });
    zia.gfx.draw.sprite(atlas.sprites[headIndex], texture, position.add(.{ .x = -30, .y = 0 }), .{
        .flipHorizontally = head_direction.flippedHorizontally(),
        .color = zia.math.Color.fromBytes(9, 0, 1, 255),
    });

    zia.gfx.draw.sprite(atlas.sprites[bodyIndex], texture, position, .{
        .flipHorizontally = body_direction.flippedHorizontally(),
        .color = zia.math.Color.fromBytes(5, 3, 0, 255),
    });
    zia.gfx.draw.sprite(atlas.sprites[headIndex], texture, position, .{
        .flipHorizontally = head_direction.flippedHorizontally(),
        .color = zia.math.Color.fromBytes(5, 0, 0, 255),
    });

    zia.gfx.draw.sprite(atlas.sprites[bodyIndex], texture, position.add(.{ .x = 30, .y = 0 }), .{
        .flipHorizontally = body_direction.flippedHorizontally(),
        .color = zia.math.Color.fromBytes(4, 6, 3, 255),
    });
    zia.gfx.draw.sprite(atlas.sprites[headIndex], texture, position.add(.{ .x = 30, .y = 0 }), .{
        .flipHorizontally = head_direction.flippedHorizontally(),
        .color = zia.math.Color.fromBytes(4, 0, 2, 255),
    });

    zia.gfx.endPass();
}

fn shutdown() !void {
    //atlas.deinit();
    texture.deinit();
    palette.deinit();
    spritePaletteShader.deinit();
}
