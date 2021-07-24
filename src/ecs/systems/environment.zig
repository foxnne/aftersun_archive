const std = @import("std");
const flecs = @import("flecs");
const game = @import("game");
const imgui = @import("imgui");
const zia = @import("zia");
const components = game.components;

pub fn progress(it: *flecs.ecs_iter_t) callconv(.C) void {
    var environments = it.column(components.Environment, 1);

    //var world = flecs.World{ .world = it.world.? };

    var i: usize = 0;
    while (i < it.count) : (i += 1) {

        //advance the ambient angle
        environments[i].ambient_xy_angle += environments[i].timescale * zia.time.dt();
        if (environments[i].ambient_xy_angle > 360)
            environments[i].ambient_xy_angle = 0;
    

        const ambient_morning_color = zia.math.Color.fromBytes(150, 140, 150, 255).asArray();
        const ambient_noon_color = zia.math.Color.fromBytes(255, 255, 255, 255).asArray();
        const ambient_night_color = zia.math.Color.fromBytes(150, 140, 150, 255).asArray();
        const ambient_midnight_color = zia.math.Color.fromBytes(70, 70, 120, 255).asArray();

        // set shadow shape, length and fade
        // between morning and noon
        if (environments[i].ambient_xy_angle > 0 and environments[i].ambient_xy_angle <= 90) {
            var f = environments[i].ambient_xy_angle / 90;
            environments[i].ambient_color = zia.math.Color.fromRgb(
                lerp(ambient_morning_color[0], ambient_noon_color[0], flip(square(flip(f)))), 
                lerp(ambient_morning_color[1], ambient_noon_color[1], flip(square(flip(f)))),  
                lerp(ambient_morning_color[2], ambient_noon_color[2], flip(square(flip(f)))), 
            );
            
        // between noon and night
        } else if (environments[i].ambient_xy_angle > 90 and environments[i].ambient_xy_angle <= 180) {
            var f = (environments[i].ambient_xy_angle - 90) / 90;
            environments[i].ambient_color = zia.math.Color.fromRgb(
                lerp(ambient_noon_color[0], ambient_night_color[0], square(f)), 
                lerp(ambient_noon_color[1], ambient_night_color[1], square(f)),  
                lerp(ambient_noon_color[2], ambient_night_color[2], square(f)), 
            );
        // between night and midnight
        } else if (environments[i].ambient_xy_angle > 180 and environments[i].ambient_xy_angle <= 270) {
            var f = (environments[i].ambient_xy_angle - 180) / 90;
            environments[i].ambient_color = zia.math.Color.fromRgb(
                lerp(ambient_night_color[0], ambient_midnight_color[0], flip(square(flip(f)))), 
                lerp(ambient_night_color[1], ambient_midnight_color[1], flip(square(flip(f)))),  
                lerp(ambient_night_color[2], ambient_midnight_color[2], flip(square(flip(f)))), 
            );
            
        // between midnight and morning
        } else if (environments[i].ambient_xy_angle > 270) {
            var f = (environments[i].ambient_xy_angle - 270) / 90;
            environments[i].ambient_color = zia.math.Color.fromRgb(
                lerp(ambient_midnight_color[0], ambient_morning_color[0], square(f)), 
                lerp(ambient_midnight_color[1], ambient_morning_color[1], square(f)),  
                lerp(ambient_midnight_color[2], ambient_morning_color[2], square(f)), 
            );
           
        }

        // send ambient and shadow settings to light shader
        // ambient color is sent as vertex color!
        environments[i].environment_shader.frag_uniform.ambient_xy_angle = environments[i].ambient_xy_angle;
        environments[i].environment_shader.frag_uniform.ambient_z_angle = environments[i].ambient_z_angle;
        environments[i].environment_shader.frag_uniform.shadow_steps = environments[i].shadow_steps;
        environments[i].environment_shader.frag_uniform.shadow_r = @intToFloat(f32, environments[i].shadow_color.channels.r) / 255;
        environments[i].environment_shader.frag_uniform.shadow_g = @intToFloat(f32, environments[i].shadow_color.channels.g) / 255;
        environments[i].environment_shader.frag_uniform.shadow_b = @intToFloat(f32, environments[i].shadow_color.channels.b) / 255;
    }
}

fn lerp (a: f32, b: f32, f: f32) f32 {
    return a + (b - a) * f;
}

fn flip (a: f32) f32 {
    return 1 - a;
}

fn square (a: f32) f32 {
    return a * a;
}
