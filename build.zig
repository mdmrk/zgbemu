const std = @import("std");

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{});

    const sdl_dep = b.dependency("SDL", .{
        .target = target,
        .optimize = optimize,
    });
    const exe = b.addExecutable(.{
        .name = "zgbemu",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .strip = optimize != .Debug,
    });

    exe.linkLibrary(sdl_dep.artifact("SDL2"));
    exe.addIncludePath(sdl_dep.path("include"));
    exe.linkLibC();
    b.installArtifact(exe);
}
