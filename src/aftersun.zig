const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const imgui = @import("imgui");

/// pixels per unit
pub const ppu: i32 = 32;

const Gizmo = @import("gizmos/gizmos.zig").Gizmo;
const Gizmos = @import("gizmos/gizmos.zig").Gizmos;
pub var gizmos: Gizmos = undefined;

pub const enable_imgui = true;

pub const editor = @import("editor/editor.zig");
pub var enable_editor = false;

// generated
pub const assets = @import("assets.zig");
pub const shaders = @import("shaders.zig");

// manual
pub const animations = @import("animations.zig");
pub const components = @import("ecs/components/components.zig");

// shaders and textures
var aftersun_palette: zia.gfx.Texture = undefined;
var aftersun_texture: zia.gfx.Texture = undefined;
var aftersun_heightmap: zia.gfx.Texture = undefined;
var aftersun_emissionmap: zia.gfx.Texture = undefined;
var aftersun_atlas: zia.gfx.Atlas = undefined;
var light_texture: zia.gfx.Texture = undefined;
var light_atlas: zia.gfx.Atlas = undefined;
var character_shader: zia.gfx.Shader = undefined;
var environment_shader: shaders.EnvironmentShader = undefined;
var emission_shader: zia.gfx.Shader = undefined;
var bloom_shader: shaders.BloomShader = undefined;
var tiltshift_shader: shaders.TiltshiftShader = undefined;
var finalize_shader: shaders.FinalizeShader = undefined;

pub var world: flecs.World = undefined;
pub var player: flecs.Entity = undefined;

pub fn main() !void {
    try zia.run(.{
        .init = init,
        .update = update,
        .shutdown = shutdown,
        .window = .{ .title = "Aftersun" },
    });
}
fn init() !void {
    // initialize gizmos
    gizmos = Gizmos{ .gizmos = std.ArrayList(Gizmo).init(std.testing.allocator) };

    // load textures, atlases and shaders
    aftersun_palette = zia.gfx.Texture.initFromFile(std.testing.allocator, assets.aftersunpalette_png.path, .nearest) catch unreachable;
    aftersun_texture = zia.gfx.Texture.initFromFile(std.testing.allocator, assets.aftersun_png.path, .nearest) catch unreachable;
    aftersun_heightmap = zia.gfx.Texture.initFromFile(std.testing.allocator, assets.aftersun_h_png.path, .nearest) catch unreachable;
    aftersun_emissionmap = zia.gfx.Texture.initFromFile(std.testing.allocator, assets.aftersun_e_png.path, .nearest) catch unreachable;
    aftersun_atlas = zia.gfx.Atlas.initFromFile(std.testing.allocator, assets.aftersun_atlas.path) catch unreachable;
    light_texture = zia.gfx.Texture.initFromFile(std.testing.allocator, assets.lights_png.path, .nearest) catch unreachable;
    light_atlas = zia.gfx.Atlas.initFromFile(std.testing.allocator, assets.lights_atlas.path) catch unreachable;
    character_shader = shaders.createSpritePaletteShader() catch unreachable;
    emission_shader = shaders.createEmissionShader() catch unreachable;
    environment_shader = shaders.createEnvironmentShader();
    bloom_shader = shaders.createBloomShader();
    tiltshift_shader = shaders.createTiltshiftShader();
    finalize_shader = shaders.createFinalizeShader();

    world = flecs.World.init();
    world.setTargetFps(60);
    const design_w = 1280;
    const design_h = 720;

    // register all components
    components.register(&world);

    // input
    _ = world.newSystem("MovementInputSystem", flecs.Phase.on_update, "$MovementInput", @import("ecs/systems/movementinput.zig").progress);
    _ = world.newSystem("MouseInputSystem", flecs.Phase.on_update, "$MouseInput, $Tile", @import("ecs/systems/mouseinput.zig").progress);
    _ = world.newSystem("MoveRequestSystem", flecs.Phase.on_update, "$MovementInput, MovementCooldown, Tile, PreviousTile, !MoveRequest", @import("ecs/systems/moverequest.zig").progress);

    // physics
    _ = world.newSystem("BroadphaseSystem", flecs.Phase.on_update, "Collider, Tile, $Broadphase", @import("ecs/systems/broadphase.zig").progress);
    _ = world.newSystem("NarrowphaseSystem", flecs.Phase.on_update, "Collider, $Broadphase, MoveRequest, MovementCooldown, Tile", @import("ecs/systems/narrowphase.zig").progress);

    _ = world.newSystem("MouseDragSystem", flecs.Phase.on_update, "MouseDrag, $Broadphase", @import("ecs/systems/mousedrag.zig").progress);

    _ = world.newSystem("EndphaseSystem", flecs.Phase.on_update, "$Broadphase", @import("ecs/systems/endphase.zig").progress);

    // movement
    _ = world.newSystem("MoveTileSystem", flecs.Phase.on_update, "MoveRequest, Tile, PreviousTile", @import("ecs/systems/movetile.zig").progress);
    _ = world.newSystem("MoveToTileSystem", flecs.Phase.on_update, "Position, Tile, PreviousTile, MovementCooldown, Velocity", @import("ecs/systems/movetotile.zig").progress);
    _ = world.newSystem("MoveSystem", flecs.Phase.on_update, "Position, Velocity, !Tile", @import("ecs/systems/move.zig").progress);

    // animation
    _ = world.newSystem("CharacterAnimatorSystem", flecs.Phase.on_update, "CharacterAnimator, CharacterRenderer, Position, Velocity, BodyDirection, HeadDirection", @import("ecs/systems/characteranimator.zig").progress);
    _ = world.newSystem("CharacterAnimationSystem", flecs.Phase.on_update, "CharacterAnimator, CharacterRenderer", @import("ecs/systems/characteranimation.zig").progress);
    _ = world.newSystem("SpriteAnimationSystem", flecs.Phase.on_update, "SpriteAnimator, SpriteRenderer", @import("ecs/systems/spriteanimation.zig").progress);

    // camera
    _ = world.newSystem("CameraZoomSystem", flecs.Phase.post_update, "Camera, Zoom", @import("ecs/systems/camerazoom.zig").progress);
    _ = world.newSystem("CameraFollowSystem", flecs.Phase.post_update, "Camera, Follow, Position, Velocity", @import("ecs/systems/camerafollow.zig").progress);

    _ = world.newSystem("EnvironmentSystem", flecs.Phase.post_update, "Environment", @import("ecs/systems/environment.zig").progress);

    // rendering
    _ = world.newSystem("RenderQuerySystem", flecs.Phase.post_update, "Position, Camera, RenderQueue", @import("ecs/systems/renderquery.zig").progress);
    _ = world.newSystem("RenderSystem", flecs.Phase.post_update, "Position, Camera, PostProcess, RenderQueue, Environment", @import("ecs/systems/render.zig").progress);

    player = world.new();
    world.setName(player, "Player");
    world.set(player, &components.Position{});
    world.set(player, &components.Tile{});
    world.set(player, &components.PreviousTile{});
    world.set(player, &components.MovementCooldown{});
    world.set(player, &components.Velocity{});
    world.set(player, &components.Speed{ .value = 80 });
    world.set(player, &components.Material{ .shader = &character_shader, .textures = &[_]*zia.gfx.Texture{&aftersun_palette} });
    world.set(player, &components.CharacterRenderer{
        .texture = aftersun_texture,
        .heightmap = aftersun_heightmap,
        .atlas = aftersun_atlas,
        .body = assets.aftersun_atlas.Idle_SE_0_Body,
        .head = assets.aftersun_atlas.Idle_S_0_Head,
        .bottom = assets.aftersun_atlas.Idle_SE_0_BottomF01,
        .top = assets.aftersun_atlas.Idle_SE_0_TopF01,
        .hair = assets.aftersun_atlas.Idle_S_0_HairF01,
        .bodyColor = zia.math.Color.fromRgbBytes(5, 0, 0),
        .headColor = zia.math.Color.fromRgbBytes(5, 0, 0),
        .bottomColor = zia.math.Color.fromRgbBytes(13, 0, 0),
        .topColor = zia.math.Color.fromRgbBytes(12, 0, 0),
        .hairColor = zia.math.Color.fromRgbBytes(4, 0, 0),
    });
    world.set(player, &components.CharacterAnimator{
        .bodyAnimation = &animations.Idle_SE_Body,
        .headAnimation = &animations.Idle_SE_Head,
        .bottomAnimation = &animations.Idle_SE_BottomF01,
        .topAnimation = &animations.Idle_SE_TopF01,
        .hairAnimation = &animations.Idle_SE_HairF01,
        .state = .idle,
    });
    world.set(player, &components.BodyDirection{});
    world.set(player, &components.HeadDirection{});
    world.add(player, components.Player);
    world.set(player, &components.Collider{});
    // world.set(player, &components.LightRenderer{
    //     .texture = light_texture,
    //     .atlas = light_atlas,
    //     .color = zia.math.Color.fromRgbBytes(50, 50, 50),
    // });

    var camera = world.new();
    world.setName(camera, "Camera");
    world.set(camera, &components.Camera{
        .size = .{ .x = design_w, .y = design_h },
        .pass_0 = zia.gfx.OffscreenPass.initWithOptions(design_w, design_h, .linear, .clamp),
        .pass_1 = zia.gfx.OffscreenPass.initWithStencil(design_w, design_h, .nearest, .clamp),
        .pass_2 = zia.gfx.OffscreenPass.initWithOptions(design_w, design_h, .linear, .clamp),
        .pass_3 = zia.gfx.OffscreenPass.initWithOptions(design_w, design_h, .linear, .clamp),
        .pass_4 = zia.gfx.OffscreenPass.initWithOptions(design_w, design_h, .linear, .clamp),
        .pass_5 = zia.gfx.OffscreenPass.initWithOptions(design_w, design_h, .linear, .clamp),
    });
    world.set(camera, &components.Zoom{});
    world.set(camera, &components.Position{});
    world.set(camera, &components.Velocity{});
    // create a query for renderers we want to draw using this camera
    world.set(camera, &components.RenderQueue{
        .query = world.newQuery("Position, SpriteRenderer || CharacterRenderer || LightRenderer"),
        .entities = std.ArrayList(flecs.Entity).init(std.testing.allocator),
    });
    world.set(camera, &components.Environment{
        .environment_shader = &environment_shader,
    });
    world.set(camera, &components.PostProcess{
        .bloom_shader = &bloom_shader,
        .finalize_shader = &finalize_shader,
        .tiltshift_shader = &tiltshift_shader,
        .emission_shader = &emission_shader,
        .textures = null,
    });
    world.set(camera, &components.Follow{ .target = player });

    world.setSingleton(&components.MovementInput{});
    world.setSingleton(&components.MouseInput{ .camera = camera });
    world.setSingleton(&components.Tile{}); //mouse input tile
    world.setSingleton(&components.Grid{});
    world.setSingleton(&components.Broadphase{ .entities = zia.utils.MultiHashMap(components.Grid.Cell, flecs.Entity).init(std.testing.allocator) });

    const treeSpawnWidth = 200;
    const treeSpawnHeight = 200;
    const treeSpawnCount = 3000;
    var prng = std.rand.DefaultPrng.init(blk: {
        var seed: u64 = 12345678900;
        break :blk seed;
    });
    const rand = &prng.random();

    var i: usize = 0;
    while (i < treeSpawnCount) : (i += 1) {
        var x = rand.intRangeAtMost(i32, -@divTrunc(treeSpawnWidth, 2), @divTrunc(treeSpawnWidth, 2));
        var y = rand.intRangeAtMost(i32, -@divTrunc(treeSpawnHeight, 2), @divTrunc(treeSpawnHeight, 2));
        var e = world.new();

        world.set(e, &components.Position{ .x = @intToFloat(f32, x * ppu), .y = @intToFloat(f32, y * ppu) });
        world.set(e, &components.Tile{ .x = x, .y = y });
        world.set(e, &components.SpriteRenderer{
            .texture = aftersun_texture,
            .heightmap = aftersun_heightmap,
            .atlas = aftersun_atlas,
            .index = assets.aftersun_atlas.PineWind_0_Layer_0,
        });

        world.set(e, &components.SpriteAnimator{
            .animation = &animations.PineWind_Layer_0,
            .state = .play,
            .frame = rand.intRangeAtMost(usize, 0, 7),
            .fps = 8,
        });
        world.set(e, &components.Collider{});
    }

    var campfire = world.new();
    world.set(campfire, &components.Position{ .x = 0, .y = 32 });
    world.set(campfire, &components.LightRenderer{
        .texture = light_texture,
        .atlas = light_atlas,
        .color = zia.math.Color.orange,
        .index = assets.lights_atlas.point256_png,
    });
    world.set(campfire, &components.SpriteRenderer{
        .texture = aftersun_texture,
        .emissionmap = aftersun_emissionmap,
        .atlas = aftersun_atlas,
        .index = assets.aftersun_atlas.Campfire_0_Layer_0,
    });
    world.set(campfire, &components.SpriteAnimator{
        .animation = &animations.Campfire_Layer_0,
        .state = .play,
        .fps = 16,
    });

    var torch = world.new();
    world.set(torch, &components.Tile{ .x = 0, .y = 4 });
    world.set(torch, &components.Position{ .x = 0, .y = 4 * ppu });
    world.set(torch, &components.LightRenderer{
        .texture = light_texture,
        .atlas = light_atlas,
        .color = zia.math.Color.orange,
        .index = assets.lights_atlas.point128_png,
    });
    world.set(torch, &components.SpriteRenderer{
        .texture = aftersun_texture,
        .emissionmap = aftersun_emissionmap,
        .atlas = aftersun_atlas,
        .index = assets.aftersun_atlas.Torch_0_Layer,
    });
    world.set(torch, &components.SpriteAnimator{
        .animation = &animations.Torch_Layer,
        .state = .play,
        .fps = 16,
    });
    world.set(torch, &components.Collider{ .trigger = true });
    world.add(torch, components.Moveable);
}

fn update() !void {
    if (zia.input.keyPressed(.grave)) {
        gizmos.enabled = !gizmos.enabled;

        if (enable_imgui)
            enable_editor = !enable_editor;
    }

    if (enable_editor) {
        editor.drawMenuBar();
        editor.drawDebugWindow();
    }

    // run all systems
    world.progress(zia.time.dt());
}

fn shutdown() !void {
    world.deinit();
    aftersun_texture.deinit();
    aftersun_palette.deinit();
    character_shader.deinit();
}
