const std = @import("std");
const zia = @import("zia");
const imgui = @import("imgui");
const Color = zia.math.Color;
const Direction = zia.math.Direction;

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

const body0 = "Body_RotationClothed_0.png";
const body1 = "Body_RotationClothed_1.png";
const body2 = "Body_RotationClothed_2.png";
const body3 = "Body_RotationClothed_3.png";
const body4 = "Body_RotationClothed_4.png";

var bodyName = body0;

pub fn main() !void {
    try zia.run(.{
        .init = init,
        .update = update,
        .render = render,
        .shutdown = shutdown,
    });
}

fn init() !void {


    palette = zia.gfx.Texture.initFromFile(std.testing.allocator, "assets/textures/palettes/character.png", .nearest) catch unreachable;
    texture = zia.gfx.Texture.initFromFile(std.testing.allocator, "assets/textures/test.png", .nearest) catch unreachable;
    atlas = zia.gfx.Atlas.initFromFile(std.testing.allocator, "assets/textures/test.json") catch unreachable;

    camera = zia.utils.Camera.init();
    const size = zia.window.size();
    camera.zoom = 3;

    spritePaletteShader = shaders.createSpritePaletteShader() catch unreachable;
}

fn update() !void {


    keyboard_direction = Direction.write(zia.input.keyDown(.w), zia.input.keyDown(.s), zia.input.keyDown(.a), zia.input.keyDown(.d));
    body_direction = keyboard_direction;
    position = position.add(keyboard_direction.normalized().scale(2 * zia.time.dt()));

    mouse_position = camera.screenToWorld(zia.input.mousePos());
    mouse_direction = Direction.find(8, mouse_position.x - position.x, mouse_position.y - position.y);
    head_direction = mouse_direction;
}

fn render() !void {

    zia.gfx.beginPass(.{ .color = Color.zia, .trans_mat = camera.transMat() });

    zia.gfx.draw.line(position, position.add(body_direction.normalized().scale(100)), 2, Color.red);                                                                                                                    
    zia.gfx.draw.line(position, position.add(head_direction.normalized().scale(100)), 2, Color.blue);

    bodyIndex = switch (body_direction) {
        .S => 0,
        .SE => 1,
        .E => 2,
        .NE => 3,
        .N => 4,
        .NW => 3,
        .W => 2,
        .SW => 1,
        else => 0,
    };

    headIndex = switch (head_direction) {
        .S => 5,
        .SE => 6,
        .E => 7,
        .NE => 8,
        .N => 9,
        .NW => 8,
        .W => 7,
        .SW => 6,
        else => 5,
    };

    bodyName = switch (body_direction) {
        .S => body0,
        .SE => body1,
        .E => body2,
        .NE => body3,
        .N => body4,
        .NW => body3,
        .W => body2,
        .SW => body1,
        else => body0,
    };

    zia.gfx.draw.bindTexture(palette, 1);

    zia.gfx.setShader(&spritePaletteShader);


    zia.gfx.draw.sprite(atlas.sprite(bodyName) catch unreachable, texture, position.add(.{ .x = -30, .y = 0 }), .{
        .flipHorizontally = body_direction.flippedHorizontally(),
        .color = zia.math.Color.fromBytes(9, 0, 2, 255),
    });
    zia.gfx.draw.sprite(atlas.sprites.items[headIndex], texture, position.add(.{ .x = -30, .y = 0 }), .{
        .flipHorizontally = head_direction.flippedHorizontally(),
        .color = zia.math.Color.fromBytes(9, 0, 1, 255),
    });

    zia.gfx.draw.sprite(atlas.sprites.items[bodyIndex], texture, position, .{
        .flipHorizontally = body_direction.flippedHorizontally(),
        .color = zia.math.Color.fromBytes(5, 3, 0, 255),
    });
    zia.gfx.draw.sprite(atlas.sprites.items[headIndex], texture, position, .{
        .flipHorizontally = head_direction.flippedHorizontally(),
        .color = zia.math.Color.fromBytes(5, 0, 0, 255),
    });

    zia.gfx.draw.sprite(atlas.sprites.items[bodyIndex], texture, position.add(.{ .x = 30, .y = 0 }), .{
        .flipHorizontally = body_direction.flippedHorizontally(),
        .color = zia.math.Color.fromBytes(4, 6, 3, 255),
    });
    zia.gfx.draw.sprite(atlas.sprites.items[headIndex], texture, position.add(.{ .x = 30, .y = 0 }), .{
        .flipHorizontally = head_direction.flippedHorizontally(),
        .color = zia.math.Color.fromBytes(4, 0, 2, 255),
    });

    zia.gfx.endPass();
}

fn shutdown() !void {
    atlas.deinit();
    texture.deinit();
    palette.deinit();
    spritePaletteShader.deinit();
}
