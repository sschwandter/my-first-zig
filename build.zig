//! Build graph for Zig Notes.
//!
//! This file links the Zig executable against macOS AppKit/Foundation,
//! installs a minimal `.app` bundle, and keeps the standard test/run steps.

const std = @import("std");

/// Defines the package module, native AppKit executable, app bundle install,
/// run step, and test step used by `zig build`.
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Here we define an executable. An executable needs to have a root module
    // which needs to expose a `main` function.
    const exe = b.addExecutable(.{
        .name = "my_first_zig",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    exe.root_module.linkFramework("AppKit", .{});
    exe.root_module.linkFramework("Foundation", .{});
    exe.root_module.linkSystemLibrary("c", .{});
    exe.root_module.linkSystemLibrary("objc", .{});

    const app_name = "Zig Notes";
    const app_bundle_path = app_name ++ ".app";

    // Install a minimal macOS app bundle so the result is recognizable from Finder.
    const install_app_exe = b.addInstallArtifact(exe, .{
        .dest_dir = .{ .override = .{ .custom = app_bundle_path ++ "/Contents/MacOS" } },
        .dest_sub_path = app_name,
    });
    b.getInstallStep().dependOn(&install_app_exe.step);
    b.installFile("resources/Info.plist", app_bundle_path ++ "/Contents/Info.plist");

    // Top level "run" step.
    const run_step = b.step("run", "Run the app");

    // Launch the bundled app through LaunchServices.
    const run_cmd = b.addSystemCommand(&.{ "open", b.getInstallPath(.prefix, app_bundle_path) });
    run_step.dependOn(&run_cmd.step);
    run_cmd.step.dependOn(b.getInstallStep());

    // Creates an executable that will run `test` blocks from the executable's
    // root module.
    const exe_tests = b.addTest(.{
        .root_module = exe.root_module,
    });

    // A run step that will run the test executable.
    const run_exe_tests = b.addRunArtifact(exe_tests);

    // A top level step for running all tests.
    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_exe_tests.step);
}
