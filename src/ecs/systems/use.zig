const std = @import("std");
const zia = @import("zia");
const flecs = @import("flecs");
const game = @import("game");
const components = game.components;
const relations = game.relations;

pub const Callback = struct {
    request: *const components.UseRequest,

    pub const name = "UseSystem";
    pub const run = progress;
};

fn progress(it: *flecs.Iterator(Callback)) void {
    while (it.next()) |comps| {
        const self = it.entity();
        const target = flecs.Entity.init(it.world().world, comps.request.target);
        blk: {
            if (self.get(components.UseCooldown)) |cooldown| {
                if (cooldown.current < cooldown.end)
                    break :blk;
            }
            if (self.get(components.MovementCooldown)) |cooldown| {
                if (cooldown.current < cooldown.end)
                    break :blk;
            }
            if (target.get(components.UseCooldown)) |cooldown| {
                if (cooldown.current < cooldown.end)
                    break :blk;
            }
            if (target.get(components.MovementCooldown)) |cooldown| {
                if (cooldown.current < cooldown.end)
                    break :blk;
            }
            if (self.get(components.Tile)) |self_tile| {
                if (target.get(components.Tile)) |target_tile| {

                    //only allow using items nearest the user
                    const dist_x = std.math.absInt(target_tile.x - self_tile.x) catch unreachable;
                    const dist_y = std.math.absInt(target_tile.y - self_tile.y) catch unreachable;

                    if (dist_x > 1 or dist_y > 1) {
                        self.remove(components.UseRequest);
                        return;
                    }
                }

                if (self.get(components.UseRecipe)) |recipe| {
                    var meets_required: bool = true;

                    if (!target.has(recipe.primary))
                        meets_required = false;

                    if (recipe.secondary) |secondary| {
                        if (!target.has(secondary))
                            meets_required = false;
                    }

                    if (recipe.tertiary) |tertiary| {
                        if (!target.has(tertiary))
                            meets_required = false;
                    }

                    if (recipe.not) |not| {
                        if (target.has(not))
                            meets_required = false;
                    }

                    if (meets_required) {
                        if (recipe.produces) |result| {
                            var new = it.world().newEntity();
                            new.isA(result);

                            if (self.get(components.Tile)) |tile| {
                                new.set(&components.Tile{
                                    .x = tile.x,
                                    .y = tile.y,
                                    .z = tile.z,
                                    .counter = game.getCounter(),
                                });
                                if (self.get(components.PreviousTile)) |_| {
                                    new.set(&components.PreviousTile{
                                        .x = tile.x,
                                        .y = tile.y,
                                        .z = tile.z,
                                    });
                                }
                            }

                            if (self.get(components.Position)) |position|
                                new.set(position);

                            new.set(&components.MoveRequest{});

                            new.set(&components.MovementCooldown{
                                .current = 0,
                                .end = 0.2,
                            });
                        }

                        if (recipe.consumes == .self or recipe.consumes == .both) {
                            if (self.getMut(components.Count)) |count| {
                                if (count.value > 1) {
                                    count.value -= 1;
                                    self.setModified(components.Count);
                                    self.set(&components.UseCooldown{
                                        .current = 0,
                                        .end = 0.5,
                                    });
                                    break :blk;
                                } else {
                                    self.delete();
                                }
                            } else {
                                self.delete();
                            }
                        }
                    }
                } else if (target.get(components.UseRecipe)) |recipe| {
                    var meets_required: bool = true;

                    if (!self.has(recipe.primary))
                        meets_required = false;

                    if (recipe.secondary) |secondary| {
                        if (!self.has(secondary))
                            meets_required = false;
                    }

                    if (recipe.tertiary) |tertiary| {
                        if (!self.has(tertiary))
                            meets_required = false;
                    }

                    if (recipe.not) |not| {
                        if (self.has(not))
                            meets_required = false;
                    }

                    if (meets_required) {
                        if (recipe.produces) |result| {
                            var new = it.world().newEntity();
                            new.isA(result);

                            if (target.get(components.Tile)) |tile| {
                                new.set(&components.Tile{
                                    .x = tile.x,
                                    .y = tile.y,
                                    .z = tile.z,
                                    .counter = game.getCounter(),
                                });
                                if (target.get(components.PreviousTile)) |_| {
                                    new.set(&components.PreviousTile{
                                        .x = tile.x,
                                        .y = tile.y,
                                        .z = tile.z,
                                    });
                                }
                            }

                            if (target.get(components.Position)) |position|
                                new.set(position);

                            new.set(&components.MoveRequest{});

                            new.set(&components.MovementCooldown{
                                .current = 0,
                                .end = 0.2,
                            });
                        }

                        if (recipe.consumes == .self or recipe.consumes == .both) {
                            if (target.getMut(components.Count)) |count| {
                                if (count.value > 1) {
                                    count.value -= 1;
                                    target.setModified(components.Count);
                                    target.set(&components.UseCooldown{
                                        .current = 0,
                                        .end = 0.5,
                                    });
                                    break :blk;
                                } else {
                                    target.delete();
                                }
                            } else {
                                target.delete();
                            }
                        }
                    }
                }
            }
            self.remove(components.UseRequest);
        }
    }
}
