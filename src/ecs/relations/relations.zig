const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const game = @import("game");
const components = game.components;
const assets = game.assets;
const animations = game.animations;

pub var torch: flecs.Entity = undefined;
pub var ham: flecs.Entity = undefined;
pub var vial: flecs.Entity = undefined;
pub var campfire: flecs.Entity = undefined;
pub var cooked_ham: flecs.Entity = undefined;

pub fn init(world: flecs.World) void {
    torch = world.newPrefab("TorchPrefab");
    torch.set(&components.Item{ .id = game.getCounter() });
    torch.setOverride(&components.Tile{});
    torch.setOverride(&components.PreviousTile{});
    torch.setOverride(&components.Position{});
    torch.setOverride(&components.LightRenderer{ .color = zia.math.Color.orange, .index = assets.lights_atlas.point128_png, .active = false });
    torch.setOverride(&components.SpriteRenderer{ .index = assets.aftersun_atlas.Torch_0_Layer });
    torch.setOverride(&components.SpriteAnimator{ .animation = &animations.Torch_Flame_Layer, .state = .pause, .fps = 16 });
    torch.setOverride(&components.Toggleable{ .state = false });
    torch.add(components.Moveable);
    torch.add(components.Useable);
    torch.set(&components.UseRecipe{ .primary = world.componentId(components.Fire) });
    torch.set(&components.ToggleAnimation{ .off_index = assets.aftersun_atlas.Torch_0_Layer });

    campfire = world.newPrefab("CampfirePrefab");
    campfire.set(&components.Item{ .id = game.getCounter() });
    campfire.set(&components.Collider{ .trigger = true });
    campfire.set(&components.LightRenderer{ .color = zia.math.Color.orange, .index = assets.lights_atlas.point256_png });
    campfire.set(&components.SpriteRenderer{ .index = assets.aftersun_atlas.Campfire_0_Layer_0 });
    campfire.set(&components.SpriteAnimator{ .animation = &animations.Campfire_Layer_0, .state = .play, .fps = 16 });
    campfire.set(&components.ParticleRenderer{
        .position_offset = .{ .x = 0, .y = -16 },
        .worldspace = false,
        .active = true,
        .lifetime = 2.0,
        .rate = 5,
        .start_color = zia.math.Color.gray,
        .end_color = zia.math.Color.fromRgb(1, 1, 1),
        .particles = std.testing.allocator.alloc(components.Particle, 100) catch unreachable,
        .animation = &animations.Smoke_Layer,
        .callback = components.ParticleRenderer.campfireSmokeCallback,
    });
    campfire.add(components.Cook);
    campfire.add(components.Fire);

    cooked_ham = world.newPrefab("CookedHamPrefab");
    cooked_ham.set(&components.Item{ .id = game.getCounter() });
    cooked_ham.setOverride(&components.Tile{});
    cooked_ham.setOverride(&components.PreviousTile{});
    cooked_ham.setOverride(&components.Position{});
    cooked_ham.setOverride(&components.SpriteRenderer{ .index = assets.aftersun_atlas.Cooked_Ham_0_Layer });
    cooked_ham.set(&components.Stackable{ .indices = &animations.Cooked_Ham_Layer });
    cooked_ham.setOverride(&components.Count{ .value = 1});
    cooked_ham.add(components.Moveable);

    ham = world.newPrefab("HamPrefab");
    ham.set(&components.Item{ .id = game.getCounter() });
    ham.setOverride(&components.Tile{});
    ham.setOverride(&components.PreviousTile{});
    ham.setOverride(&components.Position{});
    ham.setOverride(&components.SpriteRenderer{ .index = assets.aftersun_atlas.Ham_0_Layer });
    ham.setOverride(&components.Stackable{ .indices = &animations.Ham_Layer });
    ham.setOverride(&components.Count{ .value = 1});
    ham.add(components.Moveable);
    ham.set(&components.UseRecipe{ .primary = world.componentId(components.Fire), .secondary = world.componentId(components.Cook), .produces = cooked_ham, .consumes = .self });

    vial = world.newPrefab("VialPrefab");
    vial.set(&components.Item{ .id = game.getCounter() });
    vial.setOverride(&components.Tile{});
    vial.setOverride(&components.PreviousTile{});
    vial.setOverride(&components.Position{});
    vial.setOverride(&components.SpriteRenderer{ .index = assets.aftersun_atlas.Vial_0_Layer });
    vial.add(components.Moveable);

    
}
