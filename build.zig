const std = @import("std");

const LibExeObjStep = std.build.LibExeObjStep;
const Builder = std.build.Builder;
const Target = std.build.Target;
const Pkg = std.build.Pkg;

const zia_build = @import("src/deps/zia/build.zig");

const ShaderCompileStep = @import("src/deps/zia/src/deps/renderkit/build.zig").ShaderCompileStep;

const ProcessAssetsStep = @import("src/deps/zia/src/utils/process_assets.zig").ProcessAssetsStep;

pub fn build(b: *Builder) !void {
    const target = b.standardTargetOptions(.{});

    var exe = createExe(b, target, "run", "src/aftersun.zig");
    b.default_step.dependOn(&exe.step);

    //shader compiler, run with `zig build compile-shaders`
    const res = ShaderCompileStep.init(b, "src/deps/zia/src/deps/renderkit/shader_compiler/", .{
        .shader = "assets/shaders/shader_src.glsl",
        .shader_output_path = "assets/shaders",
        .package_output_path = "src",
        .additional_imports = &[_][]const u8{
            "const zia = @import(\"zia\");",
            "const gfx = zia.gfx;",
            "const math = zia.math;",
            "const renderkit = zia.renderkit;",
        },
    });

    const comple_shaders_step = b.step("compile-shaders", "compiles all shaders");
    //b.default_step.dependOn(comple_shaders_step);
    comple_shaders_step.dependOn(&res.step);

    const assets = ProcessAssetsStep.init(b, "assets", "src/assets.zig");

    const process_assets_step = b.step("process-assets", "generates struct for all assets");
    //b.default_step.dependOn(process_assets_step);
    process_assets_step.dependOn(&assets.step);
}

fn createExe(b: *Builder, target: std.build.Target, name: []const u8, source: []const u8) *std.build.LibExeObjStep {
    var exe = b.addExecutable(name, source);
    exe.setBuildMode(b.standardReleaseOptions());

    zia_build.addZiaToArtifact(b, exe, target, "src/deps/zia/");

    if (b.is_release) {
        exe.want_lto = false; //workaround until this is supported

        if (target.isWindows()) {
            exe.subsystem = .Windows;
        }

        if (std.builtin.os.tag == .macos and std.builtin.cpu.arch == std.Target.Cpu.Arch.aarch64) {
            exe.subsystem = .Posix;
        }
    }

    const aftersun_package = std.build.Pkg {
        .name = "game",
        .path = .{ .path = "src/aftersun.zig"},
    };

    exe.install();

    const run_cmd = exe.run();
    const exe_step = b.step("run", b.fmt("run {s}.zig", .{name}));
    run_cmd.step.dependOn(b.getInstallStep());
    exe_step.dependOn(&run_cmd.step);
    exe.addPackage(aftersun_package);

    return exe;
}
