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

        // get all possible cells around the entity
        const current = colliders[i].cell;

        // collect all cells around the current cell
        var cells = [_]components.Collider.Cell{
            current,
            .{ .x = current.x + 1, .y = current.y }, //east
            .{ .x = current.x - 1, .y = current.y }, //west
            .{ .x = current.x, .y = current.y - 1 }, //north
            .{ .x = current.x, .y = current.y + 1 }, //south
            .{ .x = current.x + 1, .y = current.y - 1 }, //ne
            .{ .x = current.x + 1, .y = current.y + 1 }, //se
            .{ .x = current.x - 1, .y = current.y + 1 }, //sw
            .{ .x = current.x - 1, .y = current.y - 1 }, //nw
        };

        // iterate cells finding all possible collideable entities
        for (cells) |cell| {
            if (broadphase.*.entities.get(cell)) |entities| {
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
                                        const pos1 = zia.math.Vector2{ .x = positions[i].x + velocities[i].x, .y = positions[i].y };
                                        const pos2 = zia.math.Vector2{ .x = otherPosition.?.x, .y = otherPosition.?.y };

                                        // // TODO: handle rotation?

                                        const aabb_halfextents = zia.math.Vector2{ .x = otherCollider.?.shape.box.width / 2, .y = otherCollider.?.shape.box.height / 2 };

                                        var difference = zia.math.Vector2{ .x = pos1.x - pos2.x, .y = pos1.y - pos2.y };
                                        const clamped = zia.math.Vector2{
                                            .x = std.math.clamp(difference.x, -aabb_halfextents.x, aabb_halfextents.x),
                                            .y = std.math.clamp(difference.y, -aabb_halfextents.y, aabb_halfextents.y),
                                        };
                                        const closest = zia.math.Vector2{ .x = pos2.x + clamped.x, .y = pos2.y + clamped.y };

                                        difference.x = closest.x - pos1.x;
                                        difference.y = closest.y - pos1.y;

                                        if (difference.x * difference.x + difference.y * difference.y < colliders[i].shape.circle.radius * colliders[i].shape.circle.radius) {
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

                       

                        if (lucid.gizmos.enabled) {
                            if (world.get(other, components.Position)) |otherpos| {
                                var pos1 = zia.math.Vector2{ .x = positions[i].x, .y = positions[i].y };
                                var pos2 = zia.math.Vector2{ .x = otherpos.x, .y = otherpos.y };

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
