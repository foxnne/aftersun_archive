const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const imgui = @import("imgui");

const Gizmo = @import("gizmos/gizmos.zig").Gizmo;
const Gizmos = @import("gizmos/gizmos.zig").Gizmos;
pub var gizmos: Gizmos = undefined;

pub const enable_imgui = @import("build_options").enable_imgui;
pub const editor = @import("editor/editor.zig");
pub var enable_editor = false;

// generated
pub const assets = @import("assets.zig");
pub const shaders = @import("shaders.zig");

// manual
pub const animations = @import("animations/animations.zig");

pub const components = @import("ecs/components/components.zig");
pub const sorters = @import("ecs/sorters/sorters.zig");
pub const actions = @import("ecs/actions/actions.zig");

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

var world: flecs.World = undefined;

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
    //_ = world.newSystem("GizmoInputSystem", flecs.Phase.on_update, "$Gizmos", @import("ecs/systems/gizmos.zig").progress);
    _ = world.newSystem("MovementInputSystem", flecs.Phase.on_update, "$MovementInput", @import("ecs/systems/movementinput.zig").progress);
    _ = world.newSystem("MouseInputSystem", flecs.Phase.on_update, "$MouseInput", @import("ecs/systems/mouseinput.zig").progress);
    _ = world.newSystem("InputToVelocitySystem", flecs.Phase.on_update, "Velocity, Player", @import("ecs/systems/inputvelocity.zig").progress);

    // physics
    _ = world.newSystem("BroadphaseSystem", flecs.Phase.on_update, "Collider, Position, $Broadphase", @import("ecs/systems/broadphase.zig").progress);
    _ = world.newSystem("NarrowphaseSystem", flecs.Phase.on_update, "Collider, Position, Velocity, $Broadphase", @import("ecs/systems/narrowphase.zig").progress);
    _ = world.newSystem("EndphaseSystem", flecs.Phase.on_update, "$Broadphase", @import("ecs/systems/endphase.zig").progress);

    // correction
    _ = world.newSystem("MoveSystem", flecs.Phase.on_update, "Position, Velocity", @import("ecs/systems/move.zig").progress);

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

    var player = world.new();
    world.setName(player, "Player");
    world.set(player, &components.Position{});
    world.set(player, &components.Velocity{});
    world.set(player, &components.Material{ .shader = &character_shader, .textures = &[_]*zia.gfx.Texture{&aftersun_palette} });
    world.set(player, &components.CharacterRenderer{
        .texture = aftersun_texture,
        .heightmap = aftersun_heightmap,
        .atlas = aftersun_atlas,
        .body = assets.aftersun_atlas.Body_Idle_SE_0,
        .head = assets.aftersun_atlas.Head_Idle_SE_0,
        .bottom = assets.aftersun_atlas.BottomF01_Idle_SE_0,
        .top = assets.aftersun_atlas.TopF01_Idle_SE_0,
        .hair = assets.aftersun_atlas.HairF01_Idle_S_0,
        .bodyColor = zia.math.Color.fromRgbBytes(5, 0, 0),
        .headColor = zia.math.Color.fromRgbBytes(5, 0, 0),
        .bottomColor = zia.math.Color.fromRgbBytes(13, 0, 0),
        .topColor = zia.math.Color.fromRgbBytes(13, 0, 0),
        .hairColor = zia.math.Color.fromRgbBytes(1, 0, 0),
    });
    world.set(player, &components.CharacterAnimator{
        .bodyAnimation = &animations.idleBodySE,
        .headAnimation = &animations.idleHeadS,
        .bottomAnimation = &animations.idleBottomF01SE,
        .topAnimation = &animations.idleTopF01SE,
        .hairAnimation = &animations.idleHairF01SE,
        .state = .idle,
    });
    world.set(player, &components.BodyDirection{});
    world.set(player, &components.HeadDirection{});
    world.add(player, components.Player);
    world.set(player, &components.Collider{ .shape = .{ .circle = .{ .radius = 8 } } });
    // world.set(player, &components.LightRenderer{
    //     .texture = light_texture,
    //     .atlas = light_atlas,
    //     .color = zia.math.Color.fromRgbBytes(50, 50, 50),
    // });

    var camera = world.new();
    world.setName(camera, "Camera");
    world.set(camera, &components.Camera{
        .design_w = design_w,
        .design_h = design_h,
        .pass_0 = zia.gfx.OffscreenPass.initWithOptions(design_w, design_h, .linear, .clamp),
        .pass_1 = zia.gfx.OffscreenPass.initWithOptions(design_w, design_h, .nearest, .clamp),
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

    //world.setSingleton(&components.Gizmos{.gizmos = std.ArrayList(components.Gizmo).init(std.testing.allocator)});
    world.setSingleton(&components.MovementInput{});
    world.setSingleton(&components.MouseInput{ .camera = camera });
    world.setSingleton(&components.Grid{});
    world.setSingleton(&components.Broadphase{ .entities = zia.utils.MultiHashMap(components.Collider.Cell, flecs.Entity).init(std.testing.allocator) });

    const treeSpawnWidth = 5000;
    const treeSpawnHeight = 5000;
    const treeSpawnCount = 2000;

    var prng = std.rand.DefaultPrng.init(blk: {
        var seed: u64 = 1234567890;
        //std.os.getrandom(std.mem.asBytes(&seed)) catch unreachable;
        break :blk seed;
    });
    const rand = &prng.random;

    var i: usize = 0;
    while (i < treeSpawnCount) : (i += 1) {
        var x = @intToFloat(f32, rand.intRangeAtMost(i32, -@divTrunc(treeSpawnWidth, 2), @divTrunc(treeSpawnWidth, 2)));
        var y = @intToFloat(f32, rand.intRangeAtMost(i32, -@divTrunc(treeSpawnHeight, 2), @divTrunc(treeSpawnHeight, 2)));
        var e = world.new();

        world.set(e, &components.Position{ .x = x, .y = y });
        world.set(e, &components.SpriteRenderer{
            .texture = aftersun_texture,
            .heightmap = aftersun_heightmap,
            .atlas = aftersun_atlas,
            .index = assets.aftersun_atlas.Trees_PineWind_6,
        });

        world.set(e, &components.SpriteAnimator{
            .animation = &animations.pineWind,
            .state = .play,
            .frame = rand.intRangeAtMost(usize, 0, 7),
            .fps = 8,
        });
        world.set(e, &components.Collider{ .shape = .{ .box = .{ .width = 16, .height = 16 } } });
    }

    var campfire = world.new();
    world.set(campfire, &components.Position{ .x = 0, .y = 50 });
    world.set(campfire, &components.LightRenderer{
        .texture = light_texture,
        .atlas = light_atlas,
        .color = zia.math.Color.orange,
        .index = assets.lights_atlas.point256,
    });
    world.set(campfire, &components.SpriteRenderer{
        .texture = aftersun_texture,
        .emissionmap = aftersun_emissionmap,
        .atlas = aftersun_atlas,
        .index = assets.aftersun_atlas.Campfire_Flame_0,
    });
    world.set(campfire, &components.SpriteAnimator{
        .animation = &animations.campfireFlame,
        .state = .play,
        .fps = 16,
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
