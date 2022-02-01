const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const game = @import("game");
const imgui = @import("imgui");

const components = game.components;

pub fn progress(it: *flecs.ecs_iter_t) callconv(.C) void {
    const positions = it.term(components.Position, 1);
    const particle_renderers = it.term(components.ParticleRenderer, 2);

    var i: usize = 0;
    while (i < it.count) : (i += 1) {

        // number of particles to emit this frame
        var particles_to_emit: usize = 0;

        if (particle_renderers[i].active) {
            if (particle_renderers[i].rate > 0) {
                particle_renderers[i].time_since_emit += zia.time.dt();
                const emit_time = 1 / particle_renderers[i].rate;

                if (particle_renderers[i].time_since_emit >= emit_time) {
                    particles_to_emit = @floatToInt(usize, @floor(particle_renderers[i].time_since_emit / emit_time));
                }
            }

        } else {
            continue;
        }

        for (particle_renderers[i].particles) |*particle| {
            if (particle.alive) {

                    particle.life += zia.time.dt();

                if (particle.life >= particle.lifetime) {
                    particle.alive = false;
                    particle.position = .{};
                    particle.velocity = .{};
                    continue;
                }
                particle.position = particle.position.add(particle.velocity.scale(zia.time.dt()));

                if (particle_renderers[i].animation) |animation| {
                    const f = particle.life / particle.lifetime;
                    const count = animation.len - 1;

                    const index = @floatToInt(usize, @floor(@intToFloat(f32, count) * f));

                    particle.sprite_index = animation[index];

                }

            } else if (particles_to_emit > 0) {
                particle.alive = true;
                particle.life = 0;
                

                if (particle_renderers[i].callback) |c| {
                    c(&particle_renderers[i], particle);
                }

                if (!particle_renderers[i].worldspace)
                    particle.position = particle.position.add(particle_renderers[i].position_offset).add(.{ .x = positions[i].x, .y = positions[i].y });

                particles_to_emit -= 1;
                particle_renderers[i].time_since_emit = 0;
            }
        }
    }
}
