const std = @import("std");
const sdl = @import("sdl");
const zia = @import("zia");
const flecs = @import("flecs");
const imgui = @import("imgui");

//TODO: remove this and fix the reflection data
pub const disable_reflection = true;

pub const RenderMode = enum {
    diffuse,
    height,
};
/// currently displayed render texture
pub var render_mode: RenderMode = .diffuse;

/// pixels per unit
pub const ppu: i32 = 32;

/// tile dimensions of cell
/// width and height
pub const cell_size: i32 = 32;

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
pub const relations = @import("ecs/relations/relations.zig");

// shaders and textures
pub var palette: zia.gfx.Texture = undefined;
pub var texture: zia.gfx.Texture = undefined;
pub var heightmap: zia.gfx.Texture = undefined;
pub var atlas: zia.gfx.Atlas = undefined;
pub var light_texture: zia.gfx.Texture = undefined;
pub var light_atlas: zia.gfx.Atlas = undefined;
pub var uber_shader: zia.gfx.Shader = undefined;
pub var environment_shader: shaders.EnvironmentShader = undefined;
pub var tiltshift_shader: shaders.TiltshiftShader = undefined;
pub var finalize_shader: shaders.FinalizeShader = undefined;

pub var world: flecs.World = undefined;
pub var camera: flecs.Entity = undefined;
pub var player: flecs.Entity = undefined;
pub var cursors: Cursors = undefined;

var counter: i32 = 0;

const Cursors = struct {
    normal: ?*sdl.SDL_Cursor = null,
    hand: ?*sdl.SDL_Cursor = null,

    pub fn init() Cursors {
        return .{
            .normal = null,
            .hand = sdl.SDL_CreateSystemCursor(sdl.SDL_SystemCursor.SDL_SYSTEM_CURSOR_SIZEALL),
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
    palette = zia.gfx.Texture.initFromFile(std.testing.allocator, assets.aftersunpalette_png.path, .nearest) catch unreachable;
    texture = zia.gfx.Texture.initFromFile(std.testing.allocator, assets.aftersun_png.path, .nearest) catch unreachable;
    heightmap = zia.gfx.Texture.initFromFile(std.testing.allocator, assets.aftersun_h_png.path, .nearest) catch unreachable;
    atlas = zia.gfx.Atlas.initFromFile(std.testing.allocator, assets.aftersun_atlas.path) catch unreachable;
    light_texture = zia.gfx.Texture.initFromFile(std.testing.allocator, assets.lights_png.path, .nearest) catch unreachable;
    light_atlas = zia.gfx.Atlas.initFromFile(std.testing.allocator, assets.lights_atlas.path) catch unreachable;
    uber_shader = shaders.createUberShader() catch unreachable;
    environment_shader = shaders.createEnvironmentShader();
    tiltshift_shader = shaders.createTiltshiftShader();
    finalize_shader = shaders.createFinalizeShader();

    world = flecs.World.init();
    world.setTargetFps(60);
    const design_w = 1280;
    const design_h = 720;

    // register all components
    // only components used in strings (DSL) are required to be registered
    world.registerComponents(.{
        components.MoveRequest,
        components.Visible,
    });

    relations.init(world);
    

    // time
    world.system(@import("ecs/systems/time.zig").Callback, .on_update);

    // input
    world.system(@import("ecs/systems/directionalinput.zig").Callback, .on_update);
    world.system(@import("ecs/systems/mouseinput.zig").Callback, .on_update);
    world.system(@import("ecs/systems/moverequest.zig").Callback, .on_update);
    world.observer(@import("ecs/systems/mousedrag.zig").Callback, .on_set);
    world.system(@import("ecs/systems/use.zig").Callback, .on_update);

    // collision
    world.observer(@import("ecs/systems/collisionbroadphase.zig").Callback, .on_set);
    world.observer(@import("ecs/systems/collisionnarrowphase.zig").Callback, .on_set);

    // movement
    world.system(@import("ecs/systems/movementcooldown.zig").Callback, .on_update);
    world.system(@import("ecs/systems/movetotile.zig").Callback, .on_update);
    world.system(@import("ecs/systems/move.zig").Callback, .on_update);

    // animation
    world.system(@import("ecs/systems/characteranimator.zig").Callback, .on_update);
    world.system(@import("ecs/systems/characteranimation.zig").Callback, .on_update);
    world.system(@import("ecs/systems/spriteanimation.zig").Callback, .on_update);
    world.observer(@import("ecs/systems/use.zig").Callback, .on_set);
    world.observer(@import("ecs/systems/stackable.zig").Callback, .on_set);
    world.system(@import("ecs/systems/stackrequest.zig").Callback, .on_update);

    // camera
    world.system(@import("ecs/systems/camerazoom.zig").Callback, .on_update);
    world.system(@import("ecs/systems/camerafollow.zig").Callback, .on_update);

    // environment
    world.system(@import("ecs/systems/environment.zig").Callback, .on_update);
    world.system(@import("ecs/systems/particles.zig").Callback, .on_update);
    world.system(@import("ecs/systems/lightflicker.zig").Callback, .on_update);

    // rendering
    world.system(@import("ecs/systems/renderculling.zig").Callback, .on_update);
    world.system(@import("ecs/systems/prerender.zig").Callback, .on_update);
    world.system(@import("ecs/systems/renderpass0.zig").Callback, .on_update);
    world.system(@import("ecs/systems/renderpassend0.zig").Callback, .on_update);
    world.system(@import("ecs/systems/renderpass1.zig").Callback, .on_update);
    world.system(@import("ecs/systems/renderend.zig").Callback, .on_update);

    player = world.newEntityWithName("Player");
    player.add(components.Player);
    player.set(&components.Position{});
    player.set(&components.Tile{ .counter = getCounter() });
    player.set(&components.PreviousTile{});
    player.set(&components.Velocity{});
    player.set(&components.Speed{ .value = 80 });
    player.set(&components.CharacterRenderer{
        .bodyIndex = assets.aftersun_atlas.Idle_SE_0_Body,
        .headIndex = assets.aftersun_atlas.Idle_S_0_Head,
        .bottomIndex = assets.aftersun_atlas.Idle_SE_0_BottomF02,
        .topIndex = assets.aftersun_atlas.Idle_SE_0_TopF02,
        .hairIndex = assets.aftersun_atlas.Idle_S_0_HairF01,
        .bodyColor = zia.math.Color.fromBytes(5, 0, 0, 1), 
        .headColor = zia.math.Color.fromBytes(5, 0, 0, 1),
        .bottomColor = zia.math.Color.fromBytes(13, 0, 0, 1),
        .topColor = zia.math.Color.fromBytes(12, 0, 0, 1),
        .hairColor = zia.math.Color.fromBytes(1, 0, 0, 1),
    });
    player.set(&components.CharacterAnimator{
        .bodyAnimation = &animations.Idle_SE_Body,
        .headAnimation = &animations.Idle_SE_Head,
        .bottomAnimation = &animations.Idle_SE_BottomF02,
        .topAnimation = &animations.Idle_SE_TopF02,
        .hairAnimation = &animations.Idle_SE_HairF01,
        .state = .idle,
    });
    player.set(&components.BodyDirection{});
    player.set(&components.HeadDirection{});
    player.set(&components.Collider{});

    camera = world.newEntityWithName("Camera");
    camera.set(&components.Camera{
        .size = .{ .x = design_w, .y = design_h },
        .pass_0 = zia.gfx.OffscreenPass.initMrt(design_w, design_h, 2),
        .pass_1 = zia.gfx.OffscreenPass.initWithOptions(design_w, design_h, .nearest, .clamp),
        .pass_2 = zia.gfx.OffscreenPass.initWithOptions(design_w, design_h, .nearest, .clamp),
        .pass_3 = zia.gfx.OffscreenPass.initWithOptions(design_w, design_h, .linear, .clamp),
        .pass_4 = zia.gfx.OffscreenPass.initWithOptions(design_w, design_h, .linear, .clamp),
    });
    camera.set(&components.Zoom{});
    camera.set(&components.Position{});
    camera.set(&components.Velocity{});
    camera.set(&components.Environment{});
    camera.set(&components.Follow{ .target = player });

    world.setSingleton(&components.Time{});
    world.setSingleton(&components.DirectionalInput{});
    world.setSingleton(&components.MousePosition{});
    world.setSingleton(&components.MouseTile{}); //mouse input tile

    const treeSpawnWidth = 220;
    const treeSpawnHeight = 220;
    const treeSpawnCount = 6000;
    world.dim(treeSpawnCount);
    var prng = std.rand.DefaultPrng.init(blk: {
        var seed: u64 = 123456789900;
        break :blk seed;
    });
    const rand = &prng.random();

    var i: usize = 0;
    while (i < treeSpawnCount) : (i += 1) {
        var x = rand.intRangeAtMost(i32, -@divTrunc(treeSpawnWidth, 2), @divTrunc(treeSpawnWidth, 2));
        var y = rand.intRangeAtMost(i32, -@divTrunc(treeSpawnHeight, 2), @divTrunc(treeSpawnHeight, 2));
        var e = world.newEntity();

        e.set(&components.Position{ .x = @intToFloat(f32, x * ppu), .y = @intToFloat(f32, y * ppu) });
        e.set(&components.Tile{ .x = x, .y = y, .counter = getCounter() });

        if (@mod(x, 2) != 0) {
            e.set(&components.SpriteRenderer{
                .index = assets.aftersun_atlas.TX_Plant_0_Layer_0,
            });
            e.set(&components.Collider{});
        } else {
            e.set(&components.SpriteRenderer{
                .index = assets.aftersun_atlas.Reeds_0_Layer,
            });
        }
    }

    var campfire = world.newEntityWithName("Campfire");
    campfire.set(&components.Tile{ .x = 0, .y = 1 });
    campfire.set(&components.PreviousTile{ .x = 0, .y = 1 });
    campfire.set(&components.Position{ .x = 0, .y = 1 * ppu });
    campfire.addPair(flecs.c.EcsIsA, relations.campfire);

    var torch = world.newEntityWithName("Torch");
    torch.set(&components.Tile{ .x = 0, .y = 4 });
    torch.set(&components.PreviousTile{ .x = 0, .y = 4 });
    torch.set(&components.Position{ .x = 0, .y = 4 * ppu });
    torch.addPair(flecs.c.EcsIsA, relations.torch);

    var ham = world.newEntityWithName("Ham");
    ham.set(&components.Tile{ .x = 1, .y = 4 });
    ham.set(&components.PreviousTile{ .x = 1, .y = 4 });
    ham.set(&components.Position{ .x = 1 * ppu, .y = 4 * ppu });
    ham.set(&components.Stackable{ .count = 1 });
    ham.addPair(flecs.c.EcsIsA, relations.ham);
    ham.set(&components.Stackable{
        .count = 1,
        .indices = &animations.Ham_Layer,
    });

    var ham2 = world.newEntityWithName("Ham2");
    ham2.set(&components.Tile{ .x = 2, .y = 4 });
    ham2.set(&components.PreviousTile{ .x = 2, .y = 4 });
    ham2.set(&components.Position{ .x = 2 * ppu, .y = 4 * ppu });
    ham2.set(&components.Stackable{ .count = 2 });
    ham2.addPair(flecs.c.EcsIsA, relations.ham);
    ham2.set(&components.Stackable{
        .count = 4,
        .indices = &animations.Ham_Layer,
    });
    

    var vial = world.newEntityWithName("Vial");
    vial.set(&components.Tile{ .x = 1, .y = 5 });
    vial.set(&components.PreviousTile{ .x = 1, .y = 5 });
    vial.set(&components.Position{ .x = 1 * ppu, .y = 5 * ppu });
    vial.addPair(flecs.c.EcsIsA, relations.vial);
    
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
    texture.deinit();
    palette.deinit();
    heightmap.deinit();
}
