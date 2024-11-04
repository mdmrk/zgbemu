const std = @import("std");
const Cartridge = @import("Cartridge.zig");
const Cpu = @import("Cpu.zig");
const Bus = @import("Bus.zig");
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

    if (sdl.SDL_Init(sdl.SDL_INIT_VIDEO) < 0) {
        std.debug.print("SDL2 initialization failed: {s}\n", .{sdl.SDL_GetError()});
        return error.SDLInitializationFailed;
    }
    defer sdl.SDL_Quit();

    const window = sdl.SDL_CreateWindow(
        "SDL2 Test",
        sdl.SDL_WINDOWPOS_UNDEFINED,
        sdl.SDL_WINDOWPOS_UNDEFINED,
        640,
        480,
        sdl.SDL_WINDOW_SHOWN,
    ) orelse {
        std.debug.print("Window creation failed: {s}\n", .{sdl.SDL_GetError()});
        return error.SDLWindowCreationFailed;
    };
    defer sdl.SDL_DestroyWindow(window);
    sdl.SDL_Delay(3000);

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
        if (comptime is_debug) {
            try cpu.log(&log_file);
        }
        cpu.print();
        try cpu.step();
        // _ = try std.io.getStdIn().reader().readByte();
    }
}
