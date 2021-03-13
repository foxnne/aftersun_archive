const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const lucid = @import("lucid");
const components = lucid.components;
const actions = lucid.actions;

pub fn progress(it: *flecs.ecs_iter_t) callconv(.C) void {
    var world = flecs.World{ .world = it.world.? };

    var colliders = it.column(components.Collider, 1);
    var positions = it.column(components.Position, 2);
    var velocities = it.column(components.Velocity, 3);
    var broadphase = it.column(components.Broadphase, 4);

    var i: usize = 0;
    while (i < it.count) : (i += 1) {
        if (velocities[i].x == 0 and velocities[i].y == 0)
            continue;

        // get all possible chunks around the entity
        var c = colliders[i].chunk;
        var e = .{ .x = c.x + 1, .y = c.y };
        var w = .{ .x = c.x - 1, .y = c.y };
        var n = .{ .x = c.x, .y = c.y - 1 };
        var s = .{ .x = c.x, .y = c.y + 1 };
        var ne = .{ .x = c.x + 1, .y = c.y - 1 };
        var se = .{ .x = c.x + 1, .y = c.y + 1 };
        var sw = .{ .x = c.x - 1, .y = c.y + 1 };
        var nw = .{ .x = c.x - 1, .y = c.y - 1 };

        // collect into an array for iteration
        var chunks = [_]components.Collider.Chunk{
            c, e, w, n, s, ne, se, sw, nw,
        };

        // iterate chunks finding all possible collideable entities
        for (chunks) |chunk| {
            var entities_ptr = broadphase.*.entities.get(chunk);
            if (entities_ptr) |entities| {
                for (entities.items) |other| {
                    if (other != it.entities[i]) {

                        // here we have an entity that is a possible collision
                        const otherPosition = world.get(other, components.Position);
                        const otherCollider = world.get(other, components.Collider);

                        // only collide when on the same height level
                        if (positions[i].z != otherPosition.?.z)
                            continue;

                        //TODO: collision layers

                        switch (colliders[i].shape) {
                            .circle => {
                                switch (otherCollider.?.shape) {
                                    .circle => {
                                        const pos1 = zia.math.Vector2{ .x = positions[i].x + velocities[i].x, .y = positions[i].y + velocities[i].y };
                                        const pos2 = zia.math.Vector2{ .x = otherPosition.?.x, .y = otherPosition.?.y };

                                        const distSq = pos1.distanceSq(pos2);

                                        const radius = colliders[i].shape.circle.radius + otherCollider.?.shape.circle.radius;
                                        const tolerance = radius * 0;

                                        if (distSq < radius * radius) {
                                            const distance = std.math.sqrt(distSq);

                                            if (distance != 0) {
                                                const penetration = radius + tolerance - distance;
                                                const normal = .{ .x = (pos1.x - pos2.x) / distance, .y = (pos1.y - pos2.y) / distance };

                                                if (velocities[i].x > 0 and velocities[i].x + normal.x * penetration < 0) {
                                                    velocities[i].x = 0;
                                                } else if (velocities[i].x < 0 and velocities[i].x + normal.x * penetration > 0) {
                                                    velocities[i].x = 0;
                                                } else {
                                                    velocities[i].x += normal.x * penetration;
                                                }

                                                if (velocities[i].y > 0 and velocities[i].y + normal.y * penetration < 0) {
                                                    velocities[i].y = 0;
                                                } else if (velocities[i].y < 0 and velocities[i].y + normal.y * penetration > 0) {
                                                    velocities[i].y = 0;
                                                } else {
                                                    velocities[i].y += normal.y * penetration;
                                                }
                                            }
                                        }
                                    },

                                    .box => {
                                        const pos1 = zia.math.Vector2{ .x = positions[i].x + velocities[i].x, .y = positions[i].y + velocities[i].y };
                                        const pos2 = zia.math.Vector2{ .x = otherPosition.?.x, .y = otherPosition.?.y };

                                        // // TODO: handle rotation?
                                        // const aabb1 = zia.math.RectF{ .x = pos1.x, .y = pos1.y, .width = colliders[i].shape.circle.radius * 2, .height = colliders[i].shape.circle.radius * 2 };
                                        // const aabb2 = zia.math.RectF{ .x = pos2.x, .y = pos2.y, .width = otherCollider.?.shape.box.width, .height = otherCollider.?.shape.box.height };

                                        // if (aabb1.x < aabb2.x + aabb2.width and aabb1.x + aabb1.width > aabb2.x and aabb1.y < aabb2.y + aabb2.height and aabb1.y + aabb1.height > aabb2.y) {

                                        // }

                                        const aabb_halfextents = zia.math.Vector2{ .x = otherCollider.?.shape.box.width / 2, .y = otherCollider.?.shape.box.height / 2 };
                                        //const aabb_center = zia.math.Vector2{ .x = otherPosition.?.x + aabb_halfextents.x, .y = otherPosition.?.y + aabb_halfextents.y};

                                        var difference = zia.math.Vector2{ .x = pos1.x - pos2.x, .y = pos1.y - pos2.y };
                                        const clamped = zia.math.Vector2{
                                            .x = std.math.clamp(difference.x, -aabb_halfextents.x, aabb_halfextents.x),
                                            .y = std.math.clamp(difference.y, -aabb_halfextents.y, aabb_halfextents.y),
                                        };
                                        const closest = zia.math.Vector2{ .x = pos2.x + clamped.x, .y = pos2.y + clamped.y };

                                        difference.x = closest.x - pos1.x;
                                        difference.y = closest.y - pos1.y;

                                        if (std.math.sqrt(difference.x * difference.x + difference.y * difference.y) < colliders[i].shape.circle.radius) {
                                            var direction = zia.math.Direction.find(4, difference.x, difference.y);

                                            switch (direction) {
                                                .E => {
                                                    var penetration = colliders[i].shape.circle.radius - @fabs(difference.x);

                                                    velocities[i].x -= penetration;
                                                },
                                                .W => {
                                                    var penetration = colliders[i].shape.circle.radius - @fabs(difference.x);

                                                    velocities[i].x += penetration;
                                                },
                                                .N => {
                                                    var penetration = colliders[i].shape.circle.radius - @fabs(difference.y);

                                                    velocities[i].y += penetration;
                                                },
                                                .S, .None => {
                                                    var penetration = colliders[i].shape.circle.radius - @fabs(difference.y);

                                                    velocities[i].y -= penetration;
                                                },
                                                else => unreachable,
                                            }
                                        }
                                    },
                                }
                            },
                            .box => {
                                switch (otherCollider.?.shape) {
                                    .circle => {},

                                    .box => {},
                                }
                            },
                        }

                        var other_pos_ptr = world.get(other, components.Position);

                        if (other_pos_ptr) |otherpos| {
                            var pos1 = zia.math.Vector2{ .x = positions[i].x, .y = positions[i].y };
                            var pos2 = zia.math.Vector2{ .x = otherpos.x, .y = otherpos.y };

                            if (lucid.gizmos.enabled) {
                                lucid.gizmos.line(pos1, pos2, zia.math.Color.fromBytes(255, 0, 0, 128), 1);
                            }
                        }
                    }
                }
            }

            // stop checking other collision opportunities if we arent moving
            if (velocities[i].x == 0 and velocities[i].y == 0) {
                break;
            }
        }
    }
}
