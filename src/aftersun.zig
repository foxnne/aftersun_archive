const std = @import("std");
const sdl = @import("sdl");
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
pub var cursors: Cursors = undefined;

var counter: i32 = 0;

const Cursors = struct {
    normal: ?*sdl.SDL_Cursor = null,
    crosshair: ?*sdl.SDL_Cursor = null,

    pub fn init () Cursors {
        return .{
            .normal = null,
            .crosshair = sdl.SDL_CreateSystemCursor(sdl.SDL_SystemCursor.SDL_SYSTEM_CURSOR_CROSSHAIR),
        };
    }
};

pub fn getCounter() i32 {
    var c = counter;

    if (c == std.math.maxInt(i32)) {
        counter = 0;
    } else {
        counter += 1;
    }

    return c;
}

pub fn main() !void {
    try zia.run(.{
        .init = init,
        .update = update,
        .shutdown = shutdown,
        .window = .{ .title = "Aftersun" },
    });
}
fn init() !void {
    cursors = Cursors.init();

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
    _ = world.newSystem("MovementInputSystem", flecs.EcsOnUpdate, "$MovementInput", @import("ecs/systems/movementinput.zig").progress);
    _ = world.newSystem("MouseInputSystem", flecs.EcsOnUpdate, "$MouseInput, $Tile", @import("ecs/systems/mouseinput.zig").progress);
    _ = world.newSystem("MoveRequestSystem", flecs.EcsOnUpdate, "$MovementInput, MovementCooldown, Tile, PreviousTile, !MoveRequest", @import("ecs/systems/moverequest.zig").progress);

    // physics
    _ = world.newSystem("CollisionBroadphaseSystem", flecs.EcsOnUpdate, "$CollisionBroadphase", @import("ecs/systems/collisionbroadphase.zig").progress);
    _ = world.newSystem("CollisionNarrowphaseSystem", flecs.EcsOnUpdate, "Collider, Cell, $CollisionBroadphase, MoveRequest, MovementCooldown, Tile", @import("ecs/systems/collisionnarrowphase.zig").progress);

    _ = world.newSystem("MouseDragSystem", flecs.EcsOnUpdate, "MouseDrag, $CollisionBroadphase", @import("ecs/systems/mousedrag.zig").progress);

    _ = world.newSystem("CollisionEndphaseSystem", flecs.EcsOnUpdate, "$CollisionBroadphase", @import("ecs/systems/collisionendphase.zig").progress);

    // // movement
    _ = world.newSystem("MoveTileSystem", flecs.EcsOnUpdate, "MoveRequest, Tile, PreviousTile", @import("ecs/systems/movetile.zig").progress);
    _ = world.newSystem("MoveToTileSystem", flecs.EcsOnUpdate, "Position, Tile, PreviousTile, MovementCooldown, Velocity", @import("ecs/systems/movetotile.zig").progress);
    _ = world.newSystem("MoveSystem", flecs.EcsOnUpdate, "Position, Velocity, !Tile", @import("ecs/systems/move.zig").progress);

    // animation
    _ = world.newSystem("CharacterAnimatorSystem", flecs.EcsOnUpdate, "CharacterAnimator, CharacterRenderer, Position, Velocity, BodyDirection, HeadDirection", @import("ecs/systems/characteranimator.zig").progress);
    _ = world.newSystem("CharacterAnimationSystem", flecs.EcsOnUpdate, "CharacterAnimator, CharacterRenderer", @import("ecs/systems/characteranimation.zig").progress);
    _ = world.newSystem("SpriteAnimationSystem", flecs.EcsOnUpdate, "SpriteAnimator, SpriteRenderer", @import("ecs/systems/spriteanimation.zig").progress);

    // camera
    _ = world.newSystem("CameraZoomSystem", flecs.EcsOnUpdate, "Camera, Zoom", @import("ecs/systems/camerazoom.zig").progress);
    _ = world.newSystem("CameraFollowSystem", flecs.EcsOnUpdate, "Camera, Follow, Position, Velocity", @import("ecs/systems/camerafollow.zig").progress);

    _ = world.newSystem("EnvironmentSystem", flecs.EcsOnUpdate, "Environment", @import("ecs/systems/environment.zig").progress);

    // rendering
    _ = world.newSystem("RenderQuerySystem", flecs.EcsOnUpdate, "Position, Camera, RenderQueue", @import("ecs/systems/renderquery.zig").progress);
    _ = world.newSystem("RenderSystem", flecs.EcsOnUpdate, "Position, Camera, PostProcess, RenderQueue, Environment", @import("ecs/systems/render.zig").progress);

    player = world.new();
    world.setName(player, "Player");
    world.set(player, &components.Position{});
    world.set(player, &components.Tile{ .counter = getCounter() });
    world.set(player, &components.Cell{});
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
    var broadphaseQuery = world.newQuery("Cell, Tile");
    flecs.ecs_query_order_by(world.world, broadphaseQuery, world.newComponent(components.Tile), sortTile);
    world.setSingleton(&components.CollisionBroadphase{
        .query = broadphaseQuery,
        .entities = zia.utils.MultiHashMap(components.Cell, flecs.Entity).init(std.testing.allocator),
    });

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
        world.set(e, &components.Cell{});
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
    world.set(campfire, &components.Tile{ .x = 0, .y = 1 });
    world.set(campfire, &components.Position{ .x = 0, .y = 1 * ppu });
    world.set(campfire, &components.Cell{});
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
    world.set(torch, &components.Cell{});
    world.add(torch, components.Moveable);
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

    var ham = world.new();
    world.set(ham, &components.Tile{ .x = 1, .y = 4 });
    world.set(ham, &components.Position{ .x = 1 * ppu, .y = 4 * ppu });
    world.set(ham, &components.Cell{});
    world.add(ham, components.Moveable);
    
    world.set(ham, &components.SpriteRenderer{
        .texture = aftersun_texture,
        .emissionmap = aftersun_emissionmap,
        .atlas = aftersun_atlas,
        .index = assets.aftersun_atlas.Ham_0_Layer,
    });

    var apple = world.new();
    world.set(apple, &components.Tile{ .x = 1, .y = 5 });
    world.set(apple, &components.Position{ .x = 1 * ppu, .y = 5 * ppu });
    world.set(apple, &components.Cell{});
    world.add(apple, components.Moveable);
    
    world.set(apple, &components.SpriteRenderer{
        .texture = aftersun_texture,
        .emissionmap = aftersun_emissionmap,
        .atlas = aftersun_atlas,
        .index = assets.aftersun_atlas.Vial_0_Layer,
    });
    
}

fn sortTile(entity1: flecs.ecs_entity_t, tile1_ptr: ?*const anyopaque, entity2: flecs.ecs_entity_t, tile2_ptr: ?*const anyopaque) callconv(.C) c_int {
    _ = tile1_ptr;
    _ = tile2_ptr;
    if (world.get(entity1, components.Tile)) |t1| {
        if (world.get(entity2, components.Tile)) |t2| {
            //return (p1->x > p2->x) - (p1->x < p2->x);
            var result1: c_int = if (t1.counter > t2.counter) 1 else 0;
            var result2: c_int = if (t1.counter < t2.counter) 1 else 0;

            return result2 - result1;
        }
    }

    return 0;
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
