const std = @import("std");
const zia = @import("zia");
const imgui = @import("imgui");
const Color = zia.math.Color;
const Direction = zia.math.Direction;

const shaders = @import("shaders.zig");

var camera: zia.utils.Camera = undefined;

var m_direction: Direction = .{};
var k_direction: Direction = .{};

var paletteTexture: zia.gfx.Texture = undefined;
var texture: zia.gfx.Texture = undefined;
var atlas: zia.gfx.Atlas = undefined;

var spritePaletteShader: zia.gfx.Shader = undefined;

var position: zia.math.Vector2 = .{};

var index: i32 = 0;

pub fn main() !void {
    try zia.run(.{
        .init = init,
        .update = update,
        .render = render,
        .shutdown = shutdown,
    });
}

fn init() !void {
    camera = zia.utils.Camera.init();
    const size = zia.window.size();
    camera.zoom = 4;

    paletteTexture = zia.gfx.Texture.initFromFile(std.testing.allocator, "assets/textures/palettes/character.png", .nearest) catch unreachable;
    texture = zia.gfx.Texture.initFromFile(std.testing.allocator, "assets/textures/test.png", .nearest) catch unreachable;
    atlas = zia.gfx.Atlas.initFromFile(std.testing.allocator, texture, "assets/textures/test.json") catch unreachable;

    spritePaletteShader = shaders.createSpritePaletteShader() catch unreachable;
}

fn update() !void {
    k_direction = k_direction.write(zia.input.keyDown(.w), zia.input.keyDown(.s), zia.input.keyDown(.a), zia.input.keyDown(.d));
    position = position.add(k_direction.normalized().scale(2 * zia.time.dt()));
    m_direction = m_direction.look(position, camera.screenToWorld(zia.input.mousePos()));
}

fn render() !void {
    zia.gfx.beginPass(.{ .color = Color.zia, .trans_mat = camera.transMat()});
    
    zia.gfx.draw.line(position, position.add(m_direction.normalized().scale(100)), 2, Color.red);
    zia.gfx.draw.line(position, position.add(k_direction.normalized().scale(100)), 2, Color.blue);

    index = switch (m_direction.get()) {
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

    zia.gfx.setShader(&spritePaletteShader);
    zia.gfx.draw.bindTexture(paletteTexture, 1);
    zia.gfx.draw.sprite(atlas, index, position, .{ .flipHorizontally = m_direction.flippedHorizontally(), .color = zia.math.Color.fromBytes(1, 0, 1, 255) });

    zia.gfx.endPass();
}

fn shutdown() !void {
    atlas.deinit();
    texture.deinit();
    spritePaletteShader.deinit();
}
