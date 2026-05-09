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

    // Extract version from build.zig.zon as the single source of truth.
    const version_str = v: {
        const zon_text = @embedFile("build.zig.zon");
        const needle = ".version = \"";
        const start = std.mem.indexOf(u8, zon_text, needle).? + needle.len;
        const end = std.mem.indexOfPos(u8, zon_text, start, "\"").?;
        break :v zon_text[start..end];
    };

    // Here we define an executable.
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

    const info_plist_content = b.fmt(@embedFile("resources/Info.plist.in"), .{ app_name, app_name, version_str });

    const write_plist = b.addWriteFile("Info.plist", info_plist_content);

    // Install a minimal macOS app bundle so the result is recognizable from Finder.
    const install_app_exe = b.addInstallArtifact(exe, .{
        .dest_dir = .{ .override = .{ .custom = app_bundle_path ++ "/Contents/MacOS" } },
        .dest_sub_path = app_name,
    });
    b.getInstallStep().dependOn(&install_app_exe.step);
    b.getInstallStep().dependOn(&b.addInstallFile(write_plist.getDirectory().path(b, "Info.plist"), app_bundle_path ++ "/Contents/Info.plist").step);

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
