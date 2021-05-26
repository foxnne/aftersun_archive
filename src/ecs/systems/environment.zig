const std = @import("std");
const flecs = @import("flecs");
const lucid = @import("lucid");
const imgui = @import("imgui");
const zia = @import("zia");
const components = lucid.components;

pub fn progress(it: *flecs.ecs_iter_t) callconv(.C) void {
    var environments = it.column(components.Environment, 1);

    var world = flecs.World{ .world = it.world.? };

    var i: usize = 0;
    while (i < it.count) : (i += 1) {

        //advance the sun angle
        environments[i].sun_xy_angle += environments[i].timescale * zia.time.dt();
        if (environments[i].sun_xy_angle > 360)
            environments[i].sun_xy_angle = 0;
    
        var max_shadow_steps: f32 = 150;
        var max_shadow_height: f32 = 100;
        var shadow_fade: f32 = environments[i].shadow_fade_high;

        const sun_morning_color = zia.math.Color.fromBytes(150, 140, 150, 255).asArray();
        const sun_noon_color = zia.math.Color.fromBytes(255, 255, 255, 255).asArray();
        const sun_night_color = zia.math.Color.fromBytes(150, 140, 150, 255).asArray();
        const sun_midnight_color = zia.math.Color.fromBytes(70, 70, 120, 255).asArray();

        // set shadow shape, length and fade
        // between morning and noon
        if (environments[i].sun_xy_angle > 0 and environments[i].sun_xy_angle <= 90) {
            var f = environments[i].sun_xy_angle / 90;
            //max_shadow_steps = lerp(environments[i].shadow_steps_high, environments[i].shadow_steps_low, f);
            //max_shadow_height = lerp(environments[i].sun_height_low, environments[i].sun_height_high, f);
            //shadow_fade = lerp (environments[i].shadow_fade_low, environments[i].shadow_fade_high, f);
            environments[i].sun_color = zia.math.Color.fromRgb(
                lerp(sun_morning_color[0], sun_noon_color[0], flip(square(flip(f)))), 
                lerp(sun_morning_color[1], sun_noon_color[1], flip(square(flip(f)))),  
                lerp(sun_morning_color[2], sun_noon_color[2], flip(square(flip(f)))), 
            );
            
        // between noon and night
        } else if (environments[i].sun_xy_angle > 90 and environments[i].sun_xy_angle <= 180) {
            var f = (environments[i].sun_xy_angle - 90) / 90;
            //max_shadow_steps = lerp(environments[i].shadow_steps_low, environments[i].shadow_steps_high, f);
            //max_shadow_height = lerp(environments[i].sun_height_high, environments[i].sun_height_low, f);
            //shadow_fade = lerp(environments[i].shadow_fade_high, environments[i].shadow_fade_low, f);
            environments[i].sun_color = zia.math.Color.fromRgb(
                lerp(sun_noon_color[0], sun_night_color[0], square(f)), 
                lerp(sun_noon_color[1], sun_night_color[1], square(f)),  
                lerp(sun_noon_color[2], sun_night_color[2], square(f)), 
            );
        // between night and midnight
        } else if (environments[i].sun_xy_angle > 180 and environments[i].sun_xy_angle <= 270) {
            var f = (environments[i].sun_xy_angle - 180) / 90;
            //max_shadow_steps = lerp(environments[i].shadow_steps_high, environments[i].shadow_steps_low, f);
           // max_shadow_height = lerp(environments[i].sun_height_low , environments[i].sun_height_high, f);
            //shadow_fade = lerp(environments[i].shadow_fade_low, environments[i].shadow_fade_high, f);
            environments[i].sun_color = zia.math.Color.fromRgb(
                lerp(sun_night_color[0], sun_midnight_color[0], flip(square(flip(f)))), 
                lerp(sun_night_color[1], sun_midnight_color[1], flip(square(flip(f)))),  
                lerp(sun_night_color[2], sun_midnight_color[2], flip(square(flip(f)))), 
            );
            
        // between midnight and morning
        } else if (environments[i].sun_xy_angle > 270) {
            var f = (environments[i].sun_xy_angle - 270) / 90;
            //max_shadow_steps = lerp(environments[i].shadow_steps_low, environments[i].shadow_steps_high, f);
            //max_shadow_height = lerp(environments[i].sun_height_high, environments[i].sun_height_low, f);
            //shadow_fade = lerp(environments[i].shadow_fade_high, environments[i].shadow_fade_low, f);
            environments[i].sun_color = zia.math.Color.fromRgb(
                lerp(sun_midnight_color[0], sun_morning_color[0], square(f)), 
                lerp(sun_midnight_color[1], sun_morning_color[1], square(f)),  
                lerp(sun_midnight_color[2], sun_morning_color[2], square(f)), 
            );
           
        }

        // send sun and shadow settings to light shader
        // sun color is sent as vertex color!
        environments[i].environment_shader.frag_uniform.sun_xy_angle = environments[i].sun_xy_angle;
        environments[i].environment_shader.frag_uniform.sun_z_angle = environments[i].sun_z_angle;
        environments[i].environment_shader.frag_uniform.max_shadow_steps = max_shadow_steps;
        environments[i].environment_shader.frag_uniform.max_shadow_height = max_shadow_height;
        environments[i].environment_shader.frag_uniform.shadow_fade = shadow_fade;
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
