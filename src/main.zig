const std = @import("std");
const Cartridge = @import("Cartridge.zig");
const Cpu = @import("Cpu.zig");
const Bus = @import("Bus.zig");
const build_version = @import("build_version");
const sdl = @cImport({
    @cInclude("SDL2/SDL.h");
});

const Ctx = struct {
    var running: bool = true;
};

pub fn main() !void {
    const is_debug = comptime std.options.log_level == .debug;
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    defer _ = gpa.deinit();

    // if (sdl.SDL_Init(sdl.SDL_INIT_VIDEO) < 0) {
    //     std.debug.print("SDL2 initialization failed: {s}\n", .{sdl.SDL_GetError()});
    //     return error.SDLInitializationFailed;
    // }
    // defer sdl.SDL_Quit();
    //
    const window_title = std.fmt.comptimePrint("zgbemu-{s}", .{
        build_version.version,
    });
    std.log.debug("{s}\n", .{window_title});
    // defer std.heap.page_allocator.free(window_title);
    // const window = sdl.SDL_CreateWindow(
    //     window_title.ptr,
    //     sdl.SDL_WINDOWPOS_CENTERED,
    //     sdl.SDL_WINDOWPOS_CENTERED,
    //     640,
    //     480,
    //     sdl.SDL_WINDOW_SHOWN,
    // ) orelse {
    //     std.debug.print("Window creation failed: {s}\n", .{sdl.SDL_GetError()});
    //     return error.SDLWindowCreationFailed;
    // };
    // defer sdl.SDL_DestroyWindow(window);

    var log_file: if (is_debug) std.fs.File else void = undefined;
    if (is_debug) {
        const log_file_path = try std.fs.path.join(alloc, &[_][]const u8{ "zig-out", "out.log" });
        defer alloc.free(log_file_path);
        log_file = try std.fs.cwd().createFile(log_file_path, .{});
    }
    defer if (is_debug) log_file.close();

    var args = try std.process.argsWithAllocator(alloc);
    defer args.deinit();

    _ = args.skip();
    const path = args.next() orelse return error.MissingRomPath;
    std.log.debug("filepath: {s}\n", .{path});

    var cardtrige = Cartridge.init(alloc);
    defer cardtrige.deinit();
    try cardtrige.load(path);
    try cardtrige.verify();

    var bus = Bus.init(&cardtrige);
    var cpu = Cpu.init(&bus);

    while (Ctx.running) {
        std.log.debug("{s}", .{[_]u8{'='} ** 20});
        if (is_debug) {
            try cpu.log(&log_file);
            cpu.print();
        }
        if (is_debug) {
            try cpu.step_debug(true, 152036);
        } else {
            try cpu.step();
        }
        std.log.debug("{s}\n", .{[_]u8{'='} ** 20});
    }
}

// Passing test roms
// 01 - OK
// 02 - NO
// 03 - OK
// 04 - NO
// 05 - OK
// 06 - OK
// 07 - OK
// 08 - OK
// 09 - OK
