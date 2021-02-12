const std = @import("std");
const zia = @import("zia");
const imgui = @import("imgui");

pub const Gizmos = struct {
    enabled: bool = false,
    trans_mat: ?zia.math.Matrix3x2 = null,

    pub fn init( trans_mat: ?zia.math.Matrix3x2) Gizmos {
        return .{
            .trans_mat = trans_mat orelse null
        };
    }

    pub fn setTransmat (self: *Gizmos, trans_mat: zia.math.Matrix3x2) void {
        self.trans_mat = trans_mat;
    }

    pub fn line(self: Gizmos, start: zia.math.Vector2, end: zia.math.Vector2, color: zia.math.Color, thickness: f32) void {
        if (!self.enabled or !zia.enable_imgui)
            return;

        if (self.trans_mat) |mat| {
            var scaled_start = mat.transformVec2(.{ .x = start.x, .y = start.y });
            var scaled_end = mat.transformVec2(.{ .x = end.x, .y = end.y });
            imgui.ogImDrawList_AddLine(imgui.igGetWindowDrawList(), &imgui.ImVec2{ .x = scaled_start.x, .y = scaled_start.y }, &imgui.ImVec2{ .x = scaled_end.x, .y = scaled_end.y }, color.value, thickness);
        } else {
            imgui.ogImDrawList_AddLine(imgui.igGetWindowDrawList(), &imgui.ImVec2{ .x = start.x, .y = start.y }, &imgui.ImVec2{ .x = end.x, .y = end.y }, color.value, thickness);
        }
    }

    pub fn circle(self: Gizmos, center: zia.math.Vector2, radius: f32, color: zia.math.Color, thickness: f32) void {
        if (!self.enabled or !zia.enable_imgui)
            return;

        if (self.trans_mat) |mat| {
            var scaled_center = mat.transformVec2(.{ .x = center.x, .y = center.y });
            var scaled_radius = mat.scaleVec2(.{ .x = radius, .y = radius });
            imgui.ogImDrawList_AddCircle(imgui.igGetWindowDrawList(), &imgui.ImVec2{ .x = scaled_center.x, .y = scaled_center.y }, scaled_radius.x, color.value, 50, thickness);
        } else {
            imgui.ogImDrawList_AddCircle(imgui.igGetWindowDrawList(), &imgui.ImVec2{ .x = center.x, .y = center.y }, radius, color.value, 50, thickness);
        }
    }

    pub fn box(self: Gizmos, center: zia.math.Vector2, width: f32, height: f32, color: zia.math.Color, thickness: f32) void {
        if (!self.enabled or !zia.enable_imgui)
            return;
            
        if (self.trans_mat) |mat| {
            var scaled_center = mat.transformVec2(.{ .x = center.x, .y = center.y });
            var scaled_size = mat.scaleVec2(.{ .x = width, .y = height });
            var p1 = imgui.ImVec2{ .x = scaled_center.x + (scaled_size.x / 2), .y = scaled_center.y - (scaled_size.y / 2) };
            var p2 = imgui.ImVec2{ .x = scaled_center.x - (scaled_size.x / 2), .y = scaled_center.y - (scaled_size.y / 2) };
            var p3 = imgui.ImVec2{ .x = scaled_center.x - (scaled_size.x / 2), .y = scaled_center.y + (scaled_size.y / 2) };
            var p4 = imgui.ImVec2{ .x = scaled_center.x + (scaled_size.x / 2), .y = scaled_center.y + (scaled_size.y / 2) };
            imgui.ogImDrawList_AddQuad(imgui.igGetWindowDrawList(), &p1, &p2, &p3, &p4, color.value, thickness);
        } else {
            var p1 = imgui.ImVec2{ .x = center.x + (width / 2), .y = center.y - (height / 2) };
            var p2 = imgui.ImVec2{ .x = center.x - (width / 2), .y = center.y - (height / 2) };
            var p3 = imgui.ImVec2{ .x = center.x - (width / 2), .y = center.y + (height / 2) };
            var p4 = imgui.ImVec2{ .x = center.x + (width / 2), .y = center.y + (height / 2) };
            imgui.ogImDrawList_AddQuad(imgui.igGetWindowDrawList(), &p1, &p2, &p3, &p4, color.value, thickness);
        }
    }
};
