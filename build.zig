const std = @import("std");

fn getVersion(alloc: std.mem.Allocator) !struct { date: []const u8, commit: []const u8 } {
    const result = try std.process.Child.run(.{
        .allocator = alloc,
        .argv = &.{ "date", "+%Y%m%d" },
    });
    const date = std.mem.trim(u8, result.stdout, &std.ascii.whitespace);

    const git_result = try std.process.Child.run(.{
        .allocator = alloc,
        .argv = &.{ "git", "rev-parse", "--short", "HEAD" },
    });
    const commit = std.mem.trim(u8, git_result.stdout, &std.ascii.whitespace);

    return .{
        .date = date,
        .commit = commit,
    };
}

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{});

    const version = getVersion(b.allocator) catch |err| {
        std.debug.print("Failed to get version info: {}\n", .{err});
        return;
    };

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

    const options = b.addOptions();
    options.addOption([]const u8, "version", b.fmt("{s}-{s}", .{ version.date, version.commit }));
    exe.root_module.addOptions("build_options", options);

    exe.linkLibrary(sdl_dep.artifact("SDL2"));
    exe.addIncludePath(sdl_dep.path("include"));
    exe.linkLibC();
    b.installArtifact(exe);
}
