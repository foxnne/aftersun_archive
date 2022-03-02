const std = @import("std");
const flecs = @import("flecs");
const game = @import("game");
const imgui = @import("imgui");
const zia = @import("zia");
const components = game.components;

pub const Callback = struct {
    environment: *components.Environment,
    //time: *const components.Time,

    pub const name = "EnvironmentSystem";
    pub const run = progress;
};

fn progress(it: *flecs.Iterator(Callback)) void {
    while (it.next()) |comps| {
        if (it.world().getSingleton(components.Time)) |time| {

            //advance the ambient angle
            comps.environment.ambient_xy_angle = (time.time / components.Time.day) * 360;
            if (comps.environment.ambient_xy_angle > 360)
                comps.environment.ambient_xy_angle = 0;

            const ambient_morning_color = zia.math.Color.fromBytes(150, 140, 150, 255).asArray();
            const ambient_noon_color = zia.math.Color.fromBytes(255, 255, 255, 255).asArray();
            const ambient_night_color = zia.math.Color.fromBytes(150, 140, 150, 255).asArray();
            const ambient_midnight_color = zia.math.Color.fromBytes(70, 70, 120, 255).asArray();

            // between morning and noon
            if (comps.environment.ambient_xy_angle > 0 and comps.environment.ambient_xy_angle <= 90) {
                var f = comps.environment.ambient_xy_angle / 90;
                comps.environment.ambient_color = zia.math.Color.fromRgb(
                    lerp(ambient_morning_color[0], ambient_noon_color[0], flip(square(flip(f)))),
                    lerp(ambient_morning_color[1], ambient_noon_color[1], flip(square(flip(f)))),
                    lerp(ambient_morning_color[2], ambient_noon_color[2], flip(square(flip(f)))),
                );

                // between noon and night
            } else if (comps.environment.ambient_xy_angle > 90 and comps.environment.ambient_xy_angle <= 180) {
                var f = (comps.environment.ambient_xy_angle - 90) / 90;
                comps.environment.ambient_color = zia.math.Color.fromRgb(
                    lerp(ambient_noon_color[0], ambient_night_color[0], square(f)),
                    lerp(ambient_noon_color[1], ambient_night_color[1], square(f)),
                    lerp(ambient_noon_color[2], ambient_night_color[2], square(f)),
                );
                // between night and midnight
            } else if (comps.environment.ambient_xy_angle > 180 and comps.environment.ambient_xy_angle <= 270) {
                var f = (comps.environment.ambient_xy_angle - 180) / 90;
                comps.environment.ambient_color = zia.math.Color.fromRgb(
                    lerp(ambient_night_color[0], ambient_midnight_color[0], flip(square(flip(f)))),
                    lerp(ambient_night_color[1], ambient_midnight_color[1], flip(square(flip(f)))),
                    lerp(ambient_night_color[2], ambient_midnight_color[2], flip(square(flip(f)))),
                );

                // between midnight and morning
            } else if (comps.environment.ambient_xy_angle > 270) {
                var f = (comps.environment.ambient_xy_angle - 270) / 90;
                comps.environment.ambient_color = zia.math.Color.fromRgb(
                    lerp(ambient_midnight_color[0], ambient_morning_color[0], square(f)),
                    lerp(ambient_midnight_color[1], ambient_morning_color[1], square(f)),
                    lerp(ambient_midnight_color[2], ambient_morning_color[2], square(f)),
                );
            }

            // send ambient and shadow settings to light shader
            // ambient color is sent as vertex color!
            comps.environment.environment_shader.frag_uniform.ambient_xy_angle = comps.environment.ambient_xy_angle;
            comps.environment.environment_shader.frag_uniform.ambient_z_angle = comps.environment.ambient_z_angle;
            comps.environment.environment_shader.frag_uniform.shadow_steps = comps.environment.shadow_steps;
            comps.environment.environment_shader.frag_uniform.shadow_r = @intToFloat(f32, comps.environment.shadow_color.channels.r) / 255;
            comps.environment.environment_shader.frag_uniform.shadow_g = @intToFloat(f32, comps.environment.shadow_color.channels.g) / 255;
            comps.environment.environment_shader.frag_uniform.shadow_b = @intToFloat(f32, comps.environment.shadow_color.channels.b) / 255;
        }
    }
}

fn lerp(a: f32, b: f32, f: f32) f32 {
    return a + (b - a) * f;
}

fn flip(a: f32) f32 {
    return 1 - a;
}

fn square(a: f32) f32 {
    return a * a;
}
