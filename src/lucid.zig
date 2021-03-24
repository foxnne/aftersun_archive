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

var lucid_palette: zia.gfx.Texture = undefined;
var lucid_texture: zia.gfx.Texture = undefined;
var lucid_heightmap: zia.gfx.Texture = undefined;
var lucid_atlas: zia.gfx.Atlas = undefined;
var character_shader: zia.gfx.Shader = undefined;
var light_shader: shaders.LightShader = undefined;
var post_process_shader: zia.gfx.Shader = undefined;

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
    lucid_palette = zia.gfx.Texture.initFromFile(std.testing.allocator, assets.lucidpalette_png.path, .nearest) catch unreachable;
    lucid_texture = zia.gfx.Texture.initFromFile(std.testing.allocator, assets.lucid_png.path, .nearest) catch unreachable;
    lucid_heightmap = zia.gfx.Texture.initFromFile(std.testing.allocator, assets.lucid_h_png.path , .nearest) catch unreachable;
    lucid_atlas = zia.gfx.Atlas.initFromFile(std.testing.allocator, assets.lucid_atlas.path) catch unreachable;
    character_shader = shaders.createSpritePaletteShader() catch unreachable;
    light_shader = shaders.createLightShader();
    
    post_process_shader = shaders.createPostProcessShader() catch unreachable;

    world = flecs.World.init();
    world.setTargetFps(60);

    // register all components
    components.register(&world);

    // input
    _ = world.newSystem("MovementInputSystem", flecs.Phase.on_update, "$MovementInput", @import("ecs/systems/movementinput.zig").progress);
    _ = world.newSystem("MouseInputSystem", flecs.Phase.on_update, "$MouseInput", @import("ecs/systems/mouseinput.zig").progress);
    _ = world.newSystem("InputToVelocitySystem", flecs.Phase.on_update, "Velocity, Player", @import("ecs/systems/inputvelocity.zig").progress);

    // physics
    _ = world.newSystem("BroadphaseSystem", flecs.Phase.on_update, "Collider, Position, $Broadphase", @import("ecs/systems/broadphase.zig").progress);
    _ = world.newSystem("NarrowphaseSystem", flecs.Phase.on_update, "Collider, Position, Velocity, $Broadphase", @import("ecs/systems/narrowphase.zig").progress);

    // correction
    _ = world.newSystem("MoveSystem", flecs.Phase.on_update, "Position, Velocity", @import("ecs/systems/move.zig").progress);

    // animation
    _ = world.newSystem("CharacterAnimatorSystem", flecs.Phase.on_update, "CharacterAnimator, CharacterRenderer, Position, Velocity, BodyDirection, HeadDirection", @import("ecs/systems/characteranimator.zig").progress);
    _ = world.newSystem("CharacterAnimationSystem", flecs.Phase.on_update, "CharacterAnimator, CharacterRenderer", @import("ecs/systems/characteranimation.zig").progress);

    // camera
    _ = world.newSystem("CameraZoomSystem", flecs.Phase.post_update, "Camera, Zoom", @import("ecs/systems/camerazoom.zig").progress);
    _ = world.newSystem("CameraFollowSystem", flecs.Phase.post_update, "Camera, Follow, Position, Velocity", @import("ecs/systems/camerafollow.zig").progress);
    _ = world.newSystem("EnvironmentSystem", flecs.Phase.post_update, "Environment", @import("ecs/systems/environment.zig").progress);

    // rendering
    _ = world.newSystem("RenderQuerySystem", flecs.Phase.post_update, "Position, Camera, RenderQueue", @import("ecs/systems/renderquery.zig").progress);
    _ = world.newSystem("RenderSystem", flecs.Phase.post_update, "Position, Camera, PostProcess, RenderQueue, Environment", @import("ecs/systems/render.zig").progress);

    var player = world.new();
    world.setName(player, "Player");
    world.set(player, &components.Position{});
    //world.set(player, &components.Subpixel{});
    world.set(player, &components.Velocity{});
    world.set(player, &components.Material{ .shader = &character_shader, .textures = &[_]*zia.gfx.Texture{&lucid_palette} });
    world.set(player, &components.CharacterRenderer{
        .texture = lucid_texture,
        .heightmap = lucid_heightmap,
        .atlas = lucid_atlas,
        .body = assets.lucid_atlas.Body_Idle_S_0,
        .head = assets.lucid_atlas.Head_Idle_S_0,
        .hair = assets.lucid_atlas.HairF01_Idle_S_0,
        .bodyColor = zia.math.Color.fromRgbBytes(5, 0, 0),
        .headColor = zia.math.Color.fromRgbBytes(5, 0, 0),
        .hairColor = zia.math.Color.fromRgbBytes(1, 0, 0),
    });
    world.set(player, &components.CharacterAnimator{
        .bodyAnimation = &animations.idleBodySE,
        .headAnimation = &animations.idleHeadS,
        .hairAnimation = &animations.idleHairF01SE,
        .state = .idle,
    });
    world.set(player, &components.BodyDirection{});
    world.set(player, &components.HeadDirection{});
    world.add(player, components.Player);
    world.set(player, &components.Collider{ .shape = .{ .circle = .{ .radius = 8 } } });

    var camera = world.new();
    world.setName(camera, "Camera");
    world.set(camera, &components.Camera{ .design_w = 1280, .design_h = 720 });
    world.set(camera, &components.Zoom{});
    world.set(camera, &components.Position{});
    world.set(camera, &components.Velocity{});
    // create a query for renderers we want to draw using this camera
    world.set(camera, &components.RenderQueue{
        .query = world.newQuery("Position, SpriteRenderer || CharacterRenderer"),
        .entities = std.ArrayList(flecs.Entity).init(std.testing.allocator),
    });

    world.set(camera, &components.Environment {
        .light_shader = &light_shader,
    });

    world.set(camera, &components.PostProcess{
        .shader = &post_process_shader,
        .textures = null,
    });
    world.set(camera, &components.Follow{ .target = player });

    world.setSingleton(&components.MovementInput{});
    world.setSingleton(&components.MouseInput{ .camera = camera });
    world.setSingleton(&components.Grid{});
    world.setSingleton(&components.Broadphase{ .entities = zia.utils.MultiHashMap(components.Collider.Cell, flecs.Entity).init(std.testing.allocator) });

    var other = world.new();
    world.set(other, &components.Position{ .x = 60, .y = 0 });
    world.set(other, &components.SpriteRenderer{
        .texture = lucid_texture,
        .heightmap = lucid_heightmap,
        .atlas = lucid_atlas,
        .index = assets.lucid_atlas.Trees_PineWind_0,
    });
    world.set(other, &components.Collider{ .shape = .{ .box = .{ .width = 16, .height = 16 } } });

    var other2 = world.new();
    world.set(other2, &components.Position{ .x = 78, .y = -40 });
    world.set(other2, &components.SpriteRenderer{
        .texture = lucid_texture,
        .heightmap = lucid_heightmap,
        .atlas = lucid_atlas,
        .index = assets.lucid_atlas.Trees_PineWind_0,
    });
    world.set(other2, &components.Collider{ .shape = .{ .box = .{ .width = 16, .height = 16 } } });

    var third = world.new();
    world.set(third, &components.Position{ .x = -160, .y = 10 });
    world.set(third, &components.SpriteRenderer{
        .texture = lucid_texture,
        .heightmap = lucid_heightmap,
        .atlas = lucid_atlas,
        .index = assets.lucid_atlas.Trees_PineWind_1,
    });
    world.set(third, &components.Collider{ .shape = .{ .circle = .{ .radius = 8 } } });

    var fourth = world.new();
    world.set(fourth, &components.Position{ .x = -175, .y = 25 });
    world.set(fourth, &components.SpriteRenderer{
        .texture = lucid_texture,
        .heightmap = lucid_heightmap,
        .atlas = lucid_atlas,
        .index = assets.lucid_atlas.Trees_PineWind_2,
    });
    world.set(fourth, &components.Collider{ .shape = .{ .circle = .{ .radius = 10 } } });

    var fifth = world.new();
    world.set(fifth, &components.Position{ .x = -160, .y = 220 });
    world.set(fifth, &components.SpriteRenderer{
        .texture = lucid_texture,
        .heightmap = lucid_heightmap,
        .atlas = lucid_atlas,
        .index = assets.lucid_atlas.Trees_PineWind_1,
    });
    world.set(fifth, &components.Collider{ .shape = .{ .box = .{ .width = 16, .height = 16 } } });

    var sixth = world.new();
    world.set(sixth, &components.Position{ .x = -250, .y = -80 });
    world.set(sixth, &components.SpriteRenderer{
        .texture = lucid_texture,
        .heightmap = lucid_heightmap,
        .atlas = lucid_atlas,
        .index = assets.lucid_atlas.Trees_PineWind_1,
    });
    world.set(sixth, &components.Collider{ .shape = .{ .box = .{ .width = 16, .height = 16 } } });
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

    // clear the broadphase collection and reinit
    var broadphase_ptr = world.getSingletonMut(components.Broadphase);
    if (broadphase_ptr) |broadphase| {
        broadphase.*.entities.deinit();
        world.setSingleton(&components.Broadphase{ .entities = zia.utils.MultiHashMap(components.Collider.Cell, flecs.Entity).init(std.testing.allocator) });
    }

    // end the window after all other systems are run
    if (zia.enable_imgui)
        imgui.igEnd();
}

fn shutdown() !void {
    world.deinit();
    lucid_texture.deinit();
    lucid_palette.deinit();
    character_shader.deinit();
}
