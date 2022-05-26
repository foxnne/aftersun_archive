const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const components = @import("components.zig");
const game = @import("game");

// Defaults to Sunny
pub const Weather = struct {
    ambient_morning_color: zia.math.Color = zia.math.Color.fromBytes(130, 140, 150, 255),
    ambient_noon_color: zia.math.Color = zia.math.Color.fromBytes(245, 245, 255, 255),
    ambient_night_color: zia.math.Color = zia.math.Color.fromBytes(130, 140, 150, 255),
    ambient_midnight_color: zia.math.Color = zia.math.Color.fromBytes(50, 50, 120, 255),
    precipitation: ?Precipitation = null,

    pub const Precipitation = struct {
        particle_animation: []usize,
    };

    pub fn sunny() Weather {
        return .{};
    }

    pub fn rainy() Weather {
        return .{
            .precipitation = game.animations.Drop_Layer_0,
        };
    }
};
