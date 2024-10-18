const std = @import("std");

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{});

    const sdl_setup_command = b.addSystemCommand(&[_][]const u8{
        "cmake",
        "-S",
        "external/SDL",
        "-B",
        "external/SDL/build",
        "-DCMAKE_BUILD_TYPE=Release",
        "-DCMAKE_C_COMPILER='zig;cc'",
        "-DSDL_TEST_LIBRARY=OFF",
        "-DSDL_TESTS=OFF",
        "-DSDL_EXAMPLES=OFF",
        "-DSDL_STATIC=ON",
        "-DSDL_SHARED=OFF",
    });
    const sdl_build_command = b.addSystemCommand(&[_][]const u8{
        "cmake",
        "--build",
        "external/SDL/build",
    });

    const exe = b.addExecutable(.{
        .name = "zgbemu",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    sdl_build_command.step.dependOn(&sdl_setup_command.step);
    exe.step.dependOn(&sdl_build_command.step);

    exe.addIncludePath(b.path("external/SDL/include"));
    exe.addObjectFile(b.path("external/SDL/build/libSDL3.a"));
    exe.linkLibC();

    b.installArtifact(exe);
}
