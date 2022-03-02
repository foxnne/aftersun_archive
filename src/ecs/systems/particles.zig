const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const game = @import("game");
const imgui = @import("imgui");

const components = game.components;

pub const Callback = struct {
    position: *const components.Position,
    renderer: *components.ParticleRenderer,

    pub const name = "ParticlesSystem";
    pub const run = progress;
};

fn progress(it: *flecs.Iterator(Callback)) void {
    while (it.next()) |comps| {

        // number of particles to emit this frame
        var particles_to_emit: usize = 0;

        if (comps.renderer.active) {
            if (comps.renderer.rate > 0) {
                comps.renderer.time_since_emit += zia.time.dt();
                const emit_time = 1 / comps.renderer.rate;

                if (comps.renderer.time_since_emit >= emit_time) {
                    particles_to_emit = @floatToInt(usize, @floor(comps.renderer.time_since_emit / emit_time));
                }
            }
        } else {
            continue;
        }

        for (comps.renderer.particles) |*particle| {
            if (particle.alive) {
                particle.life += zia.time.dt();

                if (particle.life >= particle.lifetime) {
                    particle.alive = false;
                    particle.position = .{};
                    particle.velocity = .{};
                    continue;
                }
                particle.position = particle.position.add(particle.velocity.scale(zia.time.dt()));

                if (comps.renderer.animation) |animation| {
                    const f = particle.life / particle.lifetime;
                    const count = animation.len - 1;

                    const index = @floatToInt(usize, @floor(@intToFloat(f32, count) * f));

                    particle.sprite_index = animation[index];
                }

                const f = particle.life / particle.lifetime;
                const color1 = comps.renderer.start_color.asArray();
                const color2 = comps.renderer.end_color.asArray();
                particle.color = zia.math.Color.fromRgba(lerp(color1[0], color2[0], f), lerp(color1[1], color2[1], f), lerp(color1[2], color2[2], f), lerp(color1[3], color2[3], f));
            } else if (particles_to_emit > 0) {
                particle.alive = true;
                particle.life = 0;

                if (comps.renderer.callback) |c| {
                    c(&comps.renderer.*, particle);
                }

                if (!comps.renderer.worldspace)
                    particle.position = particle.position.add(.{ .x = comps.position.x, .y = comps.position.y });

                particle.position = particle.position.add(comps.renderer.position_offset);

                particles_to_emit -= 1;
                comps.renderer.time_since_emit = 0;
            }
        }
    }
}

fn lerp(a: f32, b: f32, f: f32) f32 {
    return a + (b - a) * f;
}
