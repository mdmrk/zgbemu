const std = @import("std");
const Cartridge = @import("Cartridge.zig");
const Cpu = @import("Cpu.zig");
const Bus = @import("Bus.zig");
const build_options = @import("build_options");
const sdl = @cImport({
    @cInclude("SDL2/SDL.h");
});

const Ctx = struct {
    var running: bool = true;
    const is_debug: bool = std.options.log_level == .debug;
};

fn emu_run(cpu: *Cpu, log_file: *std.fs.File) !void {
    while (Ctx.running) {
        std.log.debug("{s}", .{[_]u8{'='} ** 20});
        if (Ctx.is_debug) {
            try cpu.log(log_file);
            cpu.print();
        }
        if (Ctx.is_debug) {
            try cpu.step_debug(true, 152036);
        } else {
            try cpu.step();
        }
        std.log.debug("{s}\n", .{[_]u8{'='} ** 20});
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    defer _ = gpa.deinit();

    if (sdl.SDL_Init(sdl.SDL_INIT_VIDEO | sdl.SDL_INIT_AUDIO) < 0) {
        std.debug.print("SDL2 initialization failed: {s}\n", .{sdl.SDL_GetError()});
        return error.SDLInitializationFailed;
    }
    defer sdl.SDL_Quit();

    const window_title = std.fmt.comptimePrint("zgbemu-{s}", .{
        build_options.version,
    });
    std.log.debug("{s}\n", .{window_title});
    const window = sdl.SDL_CreateWindow(
        window_title.ptr,
        sdl.SDL_WINDOWPOS_CENTERED,
        sdl.SDL_WINDOWPOS_CENTERED,
        160 * 4,
        144 * 4,
        sdl.SDL_WINDOW_SHOWN,
    ) orelse {
        std.debug.print("Window creation failed: {s}\n", .{sdl.SDL_GetError()});
        return error.SDLWindowCreationFailed;
    };
    defer sdl.SDL_DestroyWindow(window);

    var log_file: if (Ctx.is_debug) std.fs.File else void = undefined;
    if (Ctx.is_debug) {
        const log_file_path = try std.fs.path.join(alloc, &[_][]const u8{ "zig-out", "out.log" });
        defer alloc.free(log_file_path);
        log_file = try std.fs.cwd().createFile(log_file_path, .{});
    }

    defer if (Ctx.is_debug) log_file.close();

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
    const emu_thread = try std.Thread.spawn(.{}, emu_run, .{ &cpu, &log_file });
    emu_thread.detach();

    while (Ctx.running) {
        var sdl_event: sdl.SDL_Event = undefined;

        while (sdl.SDL_PollEvent(&sdl_event) != 0) {
            switch (sdl_event.type) {
                sdl.SDL_QUIT => {
                    Ctx.running = false;
                },
                else => {},
            }
        }
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
