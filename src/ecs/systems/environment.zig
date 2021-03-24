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
        environments[i].sun_xy_angle += 10 * zia.time.dt();
        if (environments[i].sun_xy_angle > 360)
            environments[i].sun_xy_angle = 0;
    
        var max_shadow_steps: f32 = 0;
        var max_shadow_height: f32 = 0;
        var shadow_fade: f32 = 0;

        const sun_morning_color = zia.math.Color.fromBytes(150, 140, 150, 255).asArray();
        const sun_noon_color = zia.math.Color.fromBytes(255, 255, 255, 255).asArray();
        const sun_night_color = zia.math.Color.fromBytes(100, 100, 150, 255).asArray();
        const sun_midnight_color = zia.math.Color.fromBytes(90, 90, 140, 255).asArray();

        // set shadow shape, length and fade
        // between morning and noon
        if (environments[i].sun_xy_angle > 0 and environments[i].sun_xy_angle <= 90) {
            var f = environments[i].sun_xy_angle / 90;
            max_shadow_steps = environments[i].shadow_steps_high + f * (environments[i].shadow_steps_low - environments[i].shadow_steps_high);
            max_shadow_height = environments[i].sun_height_low + f * (environments[i].sun_height_high - environments[i].sun_height_low);
            shadow_fade = environments[i].shadow_fade_low + f * (environments[i].shadow_fade_high - environments[i].shadow_fade_low);
            environments[i].sun_color = zia.math.Color.fromRgb(
                sun_morning_color[0] + f * (sun_noon_color[0] - sun_morning_color[0]), 
                sun_morning_color[1] + f * (sun_noon_color[1] - sun_morning_color[1]),  
                sun_morning_color[2] + f * (sun_noon_color[3] - sun_morning_color[2]), 
            );
            
        // between noon and night
        } else if (environments[i].sun_xy_angle > 90 and environments[i].sun_xy_angle <= 180) {
            var f = (environments[i].sun_xy_angle - 90) / 90;
            max_shadow_steps = environments[i].shadow_steps_low + f * (environments[i].shadow_steps_high - environments[i].shadow_steps_low);
            max_shadow_height = environments[i].sun_height_high + f * (environments[i].sun_height_low - environments[i].sun_height_high);
            shadow_fade = environments[i].shadow_fade_high + f * (environments[i].shadow_fade_low - environments[i].shadow_fade_high);
            environments[i].sun_color = zia.math.Color.fromRgb(
                sun_noon_color[0] + f * (sun_night_color[0] - sun_noon_color[0]), 
                sun_noon_color[1] + f * (sun_night_color[1] - sun_noon_color[1]),  
                sun_noon_color[2] + f * (sun_night_color[2] - sun_noon_color[2]), 
            );
        // between night and midnight
        } else if (environments[i].sun_xy_angle > 180 and environments[i].sun_xy_angle <= 270) {
            var f = (environments[i].sun_xy_angle - 180) / 90;
            max_shadow_steps = environments[i].shadow_steps_high + f * (environments[i].shadow_steps_low - environments[i].shadow_steps_high);
            max_shadow_height = environments[i].sun_height_low + f * (environments[i].sun_height_high - environments[i].sun_height_low);
            shadow_fade = environments[i].shadow_fade_low + f * (environments[i].shadow_fade_high - environments[i].shadow_fade_low);
            environments[i].sun_color = zia.math.Color.fromRgb(
                sun_night_color[0] + f * (sun_midnight_color[0] - sun_night_color[0]), 
                sun_night_color[1] + f * (sun_midnight_color[1] - sun_night_color[1]),  
                sun_night_color[2] + f * (sun_midnight_color[2] - sun_night_color[2]), 
            );
            
        // between midnight and morning
        } else if (environments[i].sun_xy_angle > 270) {
            var f = (environments[i].sun_xy_angle - 270) / 90;
            max_shadow_steps = environments[i].shadow_steps_low + f * (environments[i].shadow_steps_high - environments[i].shadow_steps_low);
            max_shadow_height = environments[i].sun_height_high + f * (environments[i].sun_height_low - environments[i].sun_height_high);
            shadow_fade = environments[i].shadow_fade_high + f * (environments[i].shadow_fade_low - environments[i].shadow_fade_high);
            environments[i].sun_color = zia.math.Color.fromRgb(
                sun_midnight_color[0] + f * (sun_morning_color[0] - sun_midnight_color[0]), 
                sun_midnight_color[1] + f * (sun_morning_color[1] - sun_midnight_color[1]),  
                sun_midnight_color[2] + f * (sun_morning_color[2] - sun_midnight_color[2]), 
            );
           
        }

        // send sun and shadow settings to light shader
        // sun color is sent as vertex color!
        environments[i].light_shader.frag_uniform.sun_xy_angle = environments[i].sun_xy_angle;
        environments[i].light_shader.frag_uniform.sun_z_angle = environments[i].sun_z_angle;
        environments[i].light_shader.frag_uniform.max_shadow_steps = max_shadow_steps;
        environments[i].light_shader.frag_uniform.max_shadow_height = max_shadow_height;
        environments[i].light_shader.frag_uniform.shadow_fade = shadow_fade;
        environments[i].light_shader.frag_uniform.shadow_r = @intToFloat(f32, environments[i].shadow_color.channels.r) / 255;
        environments[i].light_shader.frag_uniform.shadow_g = @intToFloat(f32, environments[i].shadow_color.channels.g) / 255;
        environments[i].light_shader.frag_uniform.shadow_b = @intToFloat(f32, environments[i].shadow_color.channels.b) / 255;
    }
}
