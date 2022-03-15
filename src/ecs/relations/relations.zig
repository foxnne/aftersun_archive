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

pub fn init(world: flecs.World) void {
    torch = world.newPrefab("TorchPrefab");
    torch.setOverride(&components.Tile{});
    torch.setOverride(&components.PreviousTile{});
    torch.setOverride(&components.Position{});
    torch.setOverride(&components.LightRenderer{ .color = zia.math.Color.orange, .index = assets.lights_atlas.point128_png, .active = false });
    torch.setOverride(&components.SpriteRenderer{ .index = assets.aftersun_atlas.Torch_0_Layer });
    torch.setOverride(&components.SpriteAnimator{ .animation = &animations.Torch_Flame_Layer, .state = .pause, .fps = 16 });
    torch.add(components.Moveable);
    torch.add(components.Useable);
    torch.set(&components.ToggleAnimation{ .off_index = assets.aftersun_atlas.Torch_0_Layer });
    torch.add(components.Useable);
    torch.setOverride(&components.Toggleable{ .state = false });
    torch.add(components.ToggleAnimation);

    ham = world.newPrefab("HamPrefab");
    ham.setOverride(&components.Tile{});
    ham.setOverride(&components.PreviousTile{});
    ham.setOverride(&components.Position{});
    ham.setOverride(&components.SpriteRenderer{ .index = assets.aftersun_atlas.Ham_0_Layer });
    ham.setOverride(&components.Stackable{
        .count = 1,
        .indices = &animations.Ham_Layer,
    });
    ham.add(components.Moveable);

    vial = world.newPrefab("VialPrefab");
    vial.setOverride(&components.Tile{});
    vial.setOverride(&components.PreviousTile{});
    vial.setOverride(&components.Position{});
    vial.setOverride(&components.SpriteRenderer{ .index = assets.aftersun_atlas.Vial_0_Layer });
    vial.add(components.Moveable);

    campfire = world.newPrefab("CampfirePrefab");
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
}
