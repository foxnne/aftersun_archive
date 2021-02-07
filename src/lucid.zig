const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");

// generated
const assets = @import("assets.zig");
const shaders = @import("shaders.zig");

// manual
const animations = @import("animations.zig");

const components = @import("ecs/components/components.zig");
const sorters = @import("ecs/sorters/sorters.zig");
const actions = @import("ecs/actions/actions.zig");

var character_palette: zia.gfx.Texture = undefined;
var character_texture: zia.gfx.Texture = undefined;
var character_atlas: zia.gfx.Atlas = undefined;
var character_shader: zia.gfx.Shader = undefined;

var world: flecs.World = undefined;
var player: flecs.Entity = undefined;
var camera: flecs.Entity = undefined;

pub fn main() !void {
    try zia.run(.{
        .init = init,
        .update = update,
        .shutdown = shutdown,
        .window = .{ .title = "Lucid" },
    });
}

fn init() !void {

    // load textures, atlases and shaders
    character_palette = zia.gfx.Texture.initFromFile(std.testing.allocator, assets.characterpalette_png.path, .nearest) catch unreachable;
    character_texture = zia.gfx.Texture.initFromFile(std.testing.allocator, assets.character_png.path, .nearest) catch unreachable;
    character_atlas = zia.gfx.Atlas.initFromFile(std.testing.allocator, assets.character_atlas.path) catch unreachable;
    character_shader = shaders.createSpritePaletteShader() catch unreachable;

    world = flecs.World.init();

    // register components
    const e_position = world.newComponent(components.Position);
    const e_subpixel = world.newComponent(components.Subpixel);
    const e_velocity = world.newComponent(components.Velocity);
    const e_camera = world.newComponent(components.Camera);
    const e_zoom = world.newComponent(components.Zoom);
    const e_sprite_renderer = world.newComponent(components.SpriteRenderer);
    const e_color = world.newComponent(components.Color);
    const e_animator = world.newComponent(components.SpriteAnimator);

    const e_composite_renderer = world.newComponent(components.CompositeRenderer);
    const e_composite_animator = world.newComponent(components.CompositeAnimator);
    const e_body_direction = world.newComponent(components.BodyDirection);
    const e_character_input = world.newComponent(components.MovementInput);

    world.newSystem("MovementInputSystem", flecs.Phase.on_update, "MovementInput", @import("ecs/systems/movementinput.zig").process);
    world.newSystem("InputVelocitySystem", flecs.Phase.on_update, "MovementInput, Velocity", @import("ecs/systems/inputvelocity.zig").process);
    world.newSystem("ApplyVelocitySystem", flecs.Phase.on_update, "Position, Subpixel, Velocity", @import("ecs/systems/applyvelocity.zig").process);
    world.newSystem("CharacterAnimatorSystem", flecs.Phase.on_update, "SpriteAnimator, SpriteRenderer, Velocity, BodyDirection", @import("ecs/systems/characteranimator.zig").process);
    world.newSystem("SpriteAnimationSystem", flecs.Phase.on_update, "SpriteAnimator, SpriteRenderer", @import("ecs/systems/spriteanimation.zig").process);

    world.newSystem("CameraZoomSystem", flecs.Phase.post_update, "Camera, Zoom", @import("ecs/systems/camerazoom.zig").process);
    world.newSystem("CameraRenderSystem", flecs.Phase.post_update, "Position, Camera", @import("ecs/systems/camerarender.zig").process);

    camera = flecs.ecs_new_w_type(world.world, 0);
    world.setName(camera, "Camera");
    world.set(camera, &components.Camera{ .design_w = 1280, .design_h = 720 });
    world.set(camera, &components.Zoom{});
    world.set(camera, &components.Position{});
    world.set(camera, &components.Subpixel{});
    world.set(camera, &components.Velocity{});

    player = flecs.ecs_new_w_type(world.world, 0);
    world.setName(player, "Player");
    world.set(player, &components.Position{});
    world.set(player, &components.Subpixel{});
    world.set(player, &components.Velocity{});
    world.set(player, &components.Color{ .color = zia.math.Color.white });
    world.set(player, &components.MovementInput{});
    world.set(player, &components.SpriteRenderer{ .texture = character_texture, .atlas = character_atlas, .index = assets.character_atlas.Female_Idle_S_0 });
    world.set(player, &components.SpriteAnimator{ .animation = &animations.walk_S, .state = .play });
    world.set(player, &components.BodyDirection{});

    var other = flecs.ecs_new_w_type(world.world, 0);
    world.setName(other, "Second");
    world.set(other, &components.Position{ .x = 60, .y = 0 });
    world.set(other, &components.SpriteRenderer{ .texture = character_texture, .atlas = character_atlas, .index = assets.character_atlas.Female_Idle_S_0 });

    var third = flecs.ecs_new_w_type(world.world, 0);
    world.setName(third, "Third");
    world.set(third, &components.Position{ .x = -60, .y = 0 });
    world.set(third, &components.SpriteRenderer{ .texture = character_texture, .atlas = character_atlas, .index = assets.character_atlas.Female_Idle_N_0 });
    world.set(third, &components.Color{ .color = zia.math.Color.red });
}

fn update() !void {
    world.progress(zia.time.dt());
}

fn shutdown() !void {
    world.deinit();
    character_texture.deinit();
    character_palette.deinit();
    character_shader.deinit();
}
