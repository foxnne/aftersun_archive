const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const imgui = @import("imgui");

pub var gizmos: @import("gizmos/gizmos.zig").Gizmos = undefined;

pub const enable_imgui = true;

// generated
pub const assets = @import("assets.zig");
pub const shaders = @import("shaders.zig");

// manual
pub const animations = @import("animations.zig");

pub const components = @import("ecs/components/components.zig");
pub const sorters = @import("ecs/sorters/sorters.zig");
pub const actions = @import("ecs/actions/actions.zig");

var character_palette: zia.gfx.Texture = undefined;
var character_texture: zia.gfx.Texture = undefined;
var character_atlas: zia.gfx.Atlas = undefined;
var character_shader: zia.gfx.Shader = undefined;

var world: flecs.World = undefined;

pub fn main() !void {
    try zia.run(.{
        .init = init,
        .update = update,
        .shutdown = shutdown,
        .window = .{ .title = "Lucid" },
    });
}
fn init() !void {
    gizmos = @import("gizmos/gizmos.zig").Gizmos.init(null);

    // load textures, atlases and shaders
    character_palette = zia.gfx.Texture.initFromFile(std.testing.allocator, assets.characterpalette_png.path, .nearest) catch unreachable;
    character_texture = zia.gfx.Texture.initFromFile(std.testing.allocator, assets.character_png.path, .nearest) catch unreachable;
    character_atlas = zia.gfx.Atlas.initFromFile(std.testing.allocator, assets.character_atlas.path) catch unreachable;
    character_shader = shaders.createSpritePaletteShader() catch unreachable;

    world = flecs.World.init();
    world.setTargetFps(60);

    // register all components
    components.register(&world);

    // singletons
    _ = world.newSystem("MovementInputSystem", flecs.Phase.on_update, "$MovementInput", @import("ecs/systems/movementinput.zig").progress);
    _ = world.newSystem("PanInputSystem", flecs.Phase.on_update, "$PanInput", @import("ecs/systems/paninput.zig").progress);
    _ = world.newSystem("MouseInputSystem", flecs.Phase.on_update, "$MouseInput", @import("ecs/systems/mouseinput.zig").progress);

    // character
    _ = world.newSystem("InputToVelocitySystem", flecs.Phase.on_update, "Velocity, Player", @import("ecs/systems/inputvelocity.zig").progress);
    _ = world.newSystem("SubpixelMoveSystem", flecs.Phase.on_update, "Position, Subpixel, Velocity", @import("ecs/systems/subpixelmove.zig").progress);
    _ = world.newSystem("CharacterAnimatorSystem", flecs.Phase.on_update, "CharacterAnimator, CharacterRenderer, Position, Velocity, BodyDirection, HeadDirection", @import("ecs/systems/characteranimator.zig").progress);
    _ = world.newSystem("CharacterAnimationSystem", flecs.Phase.on_update, "CharacterAnimator, CharacterRenderer", @import("ecs/systems/characteranimation.zig").progress);

    // camera
    _ = world.newSystem("CameraFollowSystem", flecs.Phase.post_update, "Camera, Follow, Position, Velocity", @import("ecs/systems/camerafollow.zig").progress);
    _ = world.newSystem("CameraPanSystem", flecs.Phase.post_update, "Camera, Position, Velocity", @import("ecs/systems/camerapan.zig").progress);
    _ = world.newSystem("CameraZoomSystem", flecs.Phase.post_update, "Camera, Zoom", @import("ecs/systems/camerazoom.zig").progress);

    // create a query for renderers
    // attach directly to render system (its an entity as well, and there will only be one)
    var renderers = world.newQuery("Position, ?SpriteRenderer, ?CharacterRenderer");
    world.sortQuery(renderers, components.Position, sorters.sortY);
    var renderSystem = world.newSystem("RenderSystem", flecs.Phase.post_update, "Position, Camera", @import("ecs/systems/render.zig").progress);
    world.set(renderSystem, &components.RenderQuery{
        .renderers = renderers,
    });

    var camera = world.new();
    world.setName(camera, "Camera");
    world.set(camera, &components.Camera{ .design_w = 1280, .design_h = 720 });
    world.set(camera, &components.Zoom{});
    world.set(camera, &components.Position{});
    world.set(camera, &components.Subpixel{});
    world.set(camera, &components.Velocity{});

    world.setSingleton(&components.MovementInput{});
    world.setSingleton(&components.PanInput{});
    world.setSingleton(&components.MouseInput{ .camera = camera });

    var player = world.new();
    world.setName(player, "Player");
    world.set(player, &components.Position{});
    world.set(player, &components.Subpixel{});
    world.set(player, &components.Velocity{});
    //world.set(player, &components.Color{ .color = zia.math.Color.fromRgbBytes(5, 0, 0) });
    world.set(player, &components.Material{ .shader = &character_shader, .textures = &[_]*zia.gfx.Texture{&character_palette} });
    world.set(player, &components.CharacterRenderer{
        .texture = character_texture,
        .atlas = character_atlas,
        .body = assets.character_atlas.Female_Idle_Body_SE_0,
        .head = assets.character_atlas.Female_Idle_Head_S_0,
        .bodyColor = zia.math.Color.fromRgbBytes(5, 0, 0),
        .headColor = zia.math.Color.fromRgbBytes(5, 0, 0),
    });
    world.set(player, &components.CharacterAnimator{
        .bodyAnimation = &animations.idleBodySE,
        .headAnimation = &animations.idleHeadS,
        .state = .idle,
    });
    world.set(player, &components.BodyDirection{});
    world.set(player, &components.HeadDirection{});
    world.add(player, components.Player);

    world.set(camera, &components.Follow{ .target = player });

    var other = world.new();
    world.setName(other, "Second");
    world.set(other, &components.Position{ .x = 60, .y = 0 });
    world.set(other, &components.SpriteRenderer{
        .texture = character_texture,
        .atlas = character_atlas,
        .index = assets.character_atlas.Female_Idle_Body_S_0,
    });
    //world.set(other, &components.Color{ .color = zia.math.Color.fromRgbBytes(4, 0, 0) });
    world.set(other, &components.Material{ .shader = &character_shader, .textures = &[_]*zia.gfx.Texture{&character_palette} });

    var third = world.new();
    world.setName(third, "Third");
    world.set(third, &components.Position{ .x = -60, .y = 0 });
    world.set(third, &components.SpriteRenderer{
        .texture = character_texture,
        .atlas = character_atlas,
        .index = assets.character_atlas.Female_Idle_Body_NE_0,
        .color = zia.math.Color.fromRgbBytes(11, 0, 0),
    });
    //world.set(third, &components.Color{ .color = zia.math.Color.fromRgbBytes(11, 0, 0) });
    world.set(third, &components.Material{ .shader = &character_shader, .textures = &[_]*zia.gfx.Texture{&character_palette} });
}

fn update() !void {

    // enable/disable gizmos
    if (zia.input.keyPressed(.grave)) {
        gizmos.enabled = !gizmos.enabled;
    }

    // create a blank window to draw gizmos to
    if (zia.enable_imgui) {
        imgui.ogSetNextWindowPos(.{}, imgui.ImGuiCond_Always, .{});
        imgui.ogSetNextWindowSize(.{ .x = @intToFloat(f32, zia.window.width()), .y = @intToFloat(f32, zia.window.height()) }, imgui.ImGuiCond_Always);
        _ = imgui.igBegin("Gizmos", null, imgui.ImGuiWindowFlags_NoBackground | imgui.ImGuiWindowFlags_NoTitleBar | imgui.ImGuiWindowFlags_NoResize | imgui.ImGuiWindowFlags_NoInputs);
    }

    // run all systems
    world.progress(zia.time.dt());

    // end the window after all other systems are run
    if (zia.enable_imgui)
        imgui.igEnd();
}

fn shutdown() !void {
    world.deinit();
    character_texture.deinit();
    character_palette.deinit();
    character_shader.deinit();
}
