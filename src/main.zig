const std = @import("std");
const Cartridge = @import("Cartridge.zig");
const Cpu = @import("Cpu.zig");
const Ppu = @import("Ppu.zig");
const Bus = @import("Bus.zig");
const sdl = @import("sdl2");

const Ctx = struct {
    var running = true;
    const is_debug = std.options.log_level == .debug;
};

fn emu_run(cpu: *Cpu) !void {
    var log_file: std.fs.File = undefined;
    if (Ctx.is_debug) {
        const log_file_path = try std.fs.path.join(std.heap.page_allocator, &[_][]const u8{ "zig-out", "out.log" });
        log_file = try std.fs.cwd().createFile(log_file_path, .{});
    }
    defer if (Ctx.is_debug) log_file.close();

    while (Ctx.running) {
        std.log.debug("{s}", .{[_]u8{'='} ** 20});
        if (Ctx.is_debug) {
            try cpu.log(&log_file);
            cpu.print();
            try cpu.step_debug(!true, 0);
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

    try sdl.init(.{
        .video = true,
        .audio = true,
        .events = true,
    });
    defer sdl.quit();

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
    var ppu = try Ppu.init(&bus);
    defer ppu.deinit();
    var cpu = Cpu.init(&bus, &ppu);

    const emu_thread = try std.Thread.spawn(.{}, emu_run, .{&cpu});
    emu_thread.detach();

    while (Ctx.running) {
        while (sdl.pollEvent()) |event| {
            switch (event) {
                .quit => {
                    Ctx.running = false;
                },
                else => {},
            }
        }
        try ppu.render();
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
