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

var bodyName = "Body_RotationClothed_0.png";
var headName = "Head_RotationClothed_0.png";

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

    bodyName = switch (body_direction) {
        .S => "Body_RotationClothed_0.png",
        .SE => "Body_RotationClothed_1.png",
        .E => "Body_RotationClothed_2.png",
        .NE => "Body_RotationClothed_3.png",
        .N => "Body_RotationClothed_4.png",
        .NW => "Body_RotationClothed_3.png",
        .W => "Body_RotationClothed_2.png",
        .SW => "Body_RotationClothed_1.png",
        else => "Body_RotationClothed_0.png",
    };

    headName = switch (head_direction) {
        .S => "Head_RotationClothed_0.png",
        .SE => "Head_RotationClothed_1.png",
        .E => "Head_RotationClothed_2.png",
        .NE => "Head_RotationClothed_3.png",
        .N => "Head_RotationClothed_4.png",
        .NW => "Head_RotationClothed_3.png",
        .W => "Head_RotationClothed_2.png",
        .SW => "Head_RotationClothed_1.png",
        else => "Head_RotationClothed_0.png",
    };

    zia.gfx.draw.bindTexture(palette, 1);

    zia.gfx.setShader(&spritePaletteShader);


    zia.gfx.draw.sprite(atlas.sprite(bodyName) catch unreachable, texture, position.add(.{ .x = -30, .y = 0 }), .{
        .flipHorizontally = body_direction.flippedHorizontally(),
        .color = zia.math.Color.fromBytes(9, 0, 2, 255),
    });
    zia.gfx.draw.sprite(atlas.sprite(headName) catch unreachable, texture, position.add(.{ .x = -30, .y = 0 }), .{
        .flipHorizontally = head_direction.flippedHorizontally(),
        .color = zia.math.Color.fromBytes(9, 0, 1, 255),
    });

    zia.gfx.draw.sprite(atlas.sprite(bodyName) catch unreachable, texture, position, .{
        .flipHorizontally = body_direction.flippedHorizontally(),
        .color = zia.math.Color.fromBytes(5, 3, 0, 255),
    });
    zia.gfx.draw.sprite(atlas.sprite(headName) catch unreachable, texture, position, .{
        .flipHorizontally = head_direction.flippedHorizontally(),
        .color = zia.math.Color.fromBytes(5, 0, 0, 255),
    });

    zia.gfx.draw.sprite(atlas.sprite(bodyName) catch unreachable, texture, position.add(.{ .x = 30, .y = 0 }), .{
        .flipHorizontally = body_direction.flippedHorizontally(),
        .color = zia.math.Color.fromBytes(4, 6, 3, 255),
    });
    zia.gfx.draw.sprite(atlas.sprite(headName) catch unreachable, texture, position.add(.{ .x = 30, .y = 0 }), .{
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
