const std = @import("std");
const sdl = @import("sdl");
const zia = @import("zia");
const flecs = @import("flecs");
const imgui = @import("imgui");

//TODO: remove this and fix the reflection data
pub const disable_reflection = true;

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
//var emission_shader: zia.gfx.Shader = undefined;
var bloom_shader: shaders.BloomShader = undefined;
var tiltshift_shader: shaders.TiltshiftShader = undefined;
var finalize_shader: shaders.FinalizeShader = undefined;

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
    aftersun_palette = zia.gfx.Texture.initFromFile(std.testing.allocator, assets.aftersunpalette_png.path, .nearest) catch unreachable;
    aftersun_texture = zia.gfx.Texture.initFromFile(std.testing.allocator, assets.aftersun_png.path, .nearest) catch unreachable;
    aftersun_heightmap = zia.gfx.Texture.initFromFile(std.testing.allocator, assets.aftersun_h_png.path, .nearest) catch unreachable;
    aftersun_atlas = zia.gfx.Atlas.initFromFile(std.testing.allocator, assets.aftersun_atlas.path) catch unreachable;
    light_texture = zia.gfx.Texture.initFromFile(std.testing.allocator, assets.lights_png.path, .nearest) catch unreachable;
    light_atlas = zia.gfx.Atlas.initFromFile(std.testing.allocator, assets.lights_atlas.path) catch unreachable;
    character_shader = shaders.createSpritePaletteShader() catch unreachable;
    environment_shader = shaders.createEnvironmentShader();
    tiltshift_shader = shaders.createTiltshiftShader();
    finalize_shader = shaders.createFinalizeShader();

    world = flecs.World.init();
    world.setTargetFps(60);
    const design_w = 1280;
    const design_h = 720;

    // register all components
    world.registerComponents(.{
        components.MoveRequest,
        components.Visible,
    });

    // time
    world.system(@import("ecs/systems/time.zig").Callback, .on_update);

    // input
    world.system(@import("ecs/systems/movementinput.zig").Callback, .on_update);
    world.system(@import("ecs/systems/mouseinput.zig").Callback, .on_update);
    world.system(@import("ecs/systems/moverequest.zig").Callback, .on_update);
    world.observer(@import("ecs/systems/mousedrag.zig").Callback, .on_set);

    // collision and interaction
    world.observer(@import("ecs/systems/collisionbroadphase.zig").Callback, .on_set);
    world.observer(@import("ecs/systems/collisionnarrowphase.zig").Callback, .on_set);

    // movement
    world.system(@import("ecs/systems/movementcooldown.zig").Callback, .on_update);
    world.system(@import("ecs/systems/movetile.zig").Callback, .on_update);
    world.system(@import("ecs/systems/movetotile.zig").Callback, .on_update);
    world.system(@import("ecs/systems/move.zig").Callback, .on_update);

    // animation
    world.system(@import("ecs/systems/characteranimator.zig").Callback, .on_update);
    world.system(@import("ecs/systems/characteranimation.zig").Callback, .on_update);
    world.system(@import("ecs/systems/spriteanimation.zig").Callback, .on_update);

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
    world.system(@import("ecs/systems/renderpassend1.zig").Callback, .on_update);
    world.system(@import("ecs/systems/renderpass2.zig").Callback, .on_update);
    world.system(@import("ecs/systems/renderpassend2.zig").Callback, .on_update);
    world.system(@import("ecs/systems/renderend.zig").Callback, .on_update);

    player = world.newEntityWithName("Player");
    player.set(&components.Position{});
    player.set(&components.Tile{ .counter = getCounter() });
    player.set(&components.PreviousTile{});
    player.set(&components.MovementCooldown{});
    player.set(&components.Velocity{});
    player.set(&components.Speed{ .value = 80 });
    player.set(&components.Material{ .shader = &character_shader, .textures = &[_]*zia.gfx.Texture{&aftersun_palette} });
    player.set(&components.CharacterRenderer{
        .texture = aftersun_texture,
        .heightmap = aftersun_heightmap,
        .atlas = aftersun_atlas,
        .body = assets.aftersun_atlas.Idle_SE_0_Body,
        .head = assets.aftersun_atlas.Idle_S_0_Head,
        .bottom = assets.aftersun_atlas.Idle_SE_0_BottomF02,
        .top = assets.aftersun_atlas.Idle_SE_0_TopF02,
        .hair = assets.aftersun_atlas.Idle_S_0_HairF01,
        .bodyColor = zia.math.Color.fromRgbBytes(5, 0, 0),
        .headColor = zia.math.Color.fromRgbBytes(5, 0, 0),
        .bottomColor = zia.math.Color.fromRgbBytes(13, 0, 0),
        .topColor = zia.math.Color.fromRgbBytes(12, 0, 0),
        .hairColor = zia.math.Color.fromRgbBytes(1, 0, 0),
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
    player.add(components.Player);
    player.set(&components.Collider{});

    camera = world.newEntityWithName("Camera");
    camera.set(&components.Camera{
        .size = .{ .x = design_w, .y = design_h },
        .pass_0 = zia.gfx.OffscreenPass.initWithOptions(design_w, design_h, .linear, .clamp),
        .pass_1 = zia.gfx.OffscreenPass.initWithOptions(design_w, design_h, .nearest, .clamp),
        .pass_2 = zia.gfx.OffscreenPass.initWithOptions(design_w, design_h, .linear, .clamp),
        .pass_3 = zia.gfx.OffscreenPass.initWithOptions(design_w, design_h, .linear, .clamp),
        .pass_4 = zia.gfx.OffscreenPass.initWithOptions(design_w, design_h, .linear, .clamp),
    });
    camera.set(&components.Zoom{});
    camera.set(&components.Position{});
    camera.set(&components.Velocity{});
    camera.set(&components.Environment{
        .environment_shader = &environment_shader,
    });
    camera.set(&components.PostProcess{
        .finalize_shader = &finalize_shader,
        .tiltshift_shader = &tiltshift_shader,
        .textures = null,
    });
    camera.set(&components.Follow{ .target = player });

    world.setSingleton(&components.Time{});
    world.setSingleton(&components.MovementInput{});
    world.setSingleton(&components.MouseInput{ .camera = camera });
    world.setSingleton(&components.Tile{}); //mouse input tile

    const treeSpawnWidth = 200;
    const treeSpawnHeight = 200;
    const treeSpawnCount = 6000;
    world.dim(treeSpawnCount);
    var prng = std.rand.DefaultPrng.init(blk: {
        var seed: u64 = 12345678900;
        break :blk seed;
    });
    const rand = &prng.random();

    var i: usize = 0;
    while (i < treeSpawnCount) : (i += 1) {
        var x = rand.intRangeAtMost(i32, -@divTrunc(treeSpawnWidth, 2), @divTrunc(treeSpawnWidth, 2));
        var y = rand.intRangeAtMost(i32, -@divTrunc(treeSpawnHeight, 2), @divTrunc(treeSpawnHeight, 2));
        var e = world.newEntity();

        e.set(&components.Position{ .x = @intToFloat(f32, x * ppu), .y = @intToFloat(f32, y * ppu) });
        e.set(&components.Tile{ .x = x, .y = y });
        e.set(&components.SpriteRenderer{
            .texture = aftersun_texture,
            .heightmap = aftersun_heightmap,
            .atlas = aftersun_atlas,
            .index = assets.aftersun_atlas.Reeds_0_Layer,
        });

        if (@mod(x, 2) != 0) {
            e.set(&components.SpriteAnimator{
                .animation = &animations.PineWind_Layer_0,
                .state = .play,
                .frame = rand.intRangeAtMost(usize, 0, 7),
                .fps = 8,
            });
            e.set(&components.Collider{});
        }
    }

    var campfire = world.newEntityWithName("Campfire");
    campfire.set(&components.Tile{ .x = 0, .y = 1 });
    campfire.set(&components.PreviousTile{ .x = 0, .y = 1});
    campfire.set(&components.Position{ .x = 0, .y = 1 * ppu });
    campfire.set(&components.Collider{ .trigger = true });
    campfire.set(&components.LightRenderer{
        .texture = light_texture,
        .atlas = light_atlas,
        .color = zia.math.Color.orange,
        .index = assets.lights_atlas.point256_png,
    });
    campfire.set(&components.SpriteRenderer{
        .texture = aftersun_texture,
        .atlas = aftersun_atlas,
        .index = assets.aftersun_atlas.Campfire_0_Layer_0,
    });
    campfire.set(&components.SpriteAnimator{
        .animation = &animations.Campfire_Layer_0,
        .state = .play,
        .fps = 16,
    });
    campfire.set(&components.ParticleRenderer{
        .position_offset = .{ .x = 0, .y = -16 },
        .worldspace = false,
        .texture = aftersun_texture,
        .atlas = aftersun_atlas,
        .active = true,
        .lifetime = 2.0,
        .rate = 5,
        .start_color = zia.math.Color.gray,
        .end_color = zia.math.Color.fromRgba(1, 1, 1, 0.5),
        .particles = std.testing.allocator.alloc(components.Particle, 100) catch unreachable,
        .animation = &animations.Smoke_Layer,
        .callback = components.ParticleRenderer.campfireSmokeCallback,
    });

    var torch = world.newEntityWithName("Torch");
    torch.set(&components.Tile{ .x = 0, .y = 4 });
    torch.set(&components.PreviousTile{ .x = 0, .y = 4 });
    torch.set(&components.Position{ .x = 0, .y = 4 * ppu });
    torch.add(components.Moveable);
    torch.set(&components.LightRenderer{
        .texture = light_texture,
        .atlas = light_atlas,
        .color = zia.math.Color.orange,
        .index = assets.lights_atlas.point128_png,
    });
    torch.set(&components.SpriteRenderer{
        .texture = aftersun_texture,
        .heightmap = aftersun_heightmap,
        .atlas = aftersun_atlas,
        .index = assets.aftersun_atlas.Torch_0_Layer,
    });
    torch.set(&components.SpriteAnimator{
        .animation = &animations.Torch_Flame_Layer,
        .state = .play,
        .fps = 16,
    });

    var ham = world.newEntityWithName("Ham");
    ham.set(&components.Tile{ .x = 1, .y = 4 });
    ham.set(&components.PreviousTile{ .x = 1, .y = 4 });
    ham.set(&components.Position{ .x = 1 * ppu, .y = 4 * ppu });
    ham.add(components.Moveable);
    ham.set(&components.SpriteRenderer{
        .texture = aftersun_texture,
        .heightmap = aftersun_heightmap,
        .atlas = aftersun_atlas,
        .index = assets.aftersun_atlas.Ham_0_Layer,
    });

    var vial = world.newEntityWithName("Vial");
    vial.set(&components.Tile{ .x = 1, .y = 5 });
    vial.set(&components.PreviousTile{ .x = 1, .y = 5 });
    vial.set(&components.Position{ .x = 1 * ppu, .y = 5 * ppu });
    vial.add(components.Moveable);
    vial.set(&components.SpriteRenderer{
        .texture = aftersun_texture,
        .heightmap = aftersun_heightmap,
        .atlas = aftersun_atlas,
        .index = assets.aftersun_atlas.Vial_0_Layer,
    });
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
