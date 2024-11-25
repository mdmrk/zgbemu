const std = @import("std");
const Cartridge = @import("Cartridge.zig");
const Cpu = @import("Cpu.zig");
const Ppu = @import("Ppu.zig");
const Bus = @import("Bus.zig");
const sdl = @import("sdl2");

const Ctx = struct {
    var running = true;
    const is_debug = std.options.log_level == .debug;
    cpu: *Cpu,
    ppu: *Ppu,
};

// Number of CPU cycles per frame (4.194304 MHz / ~60 FPS)
const CYCLES_PER_FRAME = 70224;

fn emu_run(cpu: *Cpu, ppu: *Ppu) !void {
    var log_file: std.fs.File = undefined;
    if (Ctx.is_debug) {
        const log_file_path = try std.fs.path.join(std.heap.page_allocator, &[_][]const u8{ "zig-out", "out.log" });
        log_file = try std.fs.cwd().createFile(log_file_path, .{});
    }
    defer if (Ctx.is_debug) log_file.close();

    var cycles_this_frame: usize = 0;

    while (Ctx.running) {
        if (Ctx.is_debug) {
            // std.log.debug("{s}", .{[_]u8{'='} ** 20});
            // try cpu.log(&log_file);
            // cpu.print();
            try cpu.step_debug(!true, 0);
        } else {
            try cpu.step();
        }

        // Run PPU cycles to match CPU cycles
        // Each CPU cycle = 4 PPU cycles
        const cycles = 4;
        var i: usize = 0;
        while (i < cycles) : (i += 1) {
            ppu.tick();
        }

        cycles_this_frame += cycles;

        // If we've completed a frame's worth of cycles, update the screen
        if (cycles_this_frame >= CYCLES_PER_FRAME) {
            try ppu.render();
            cycles_this_frame = 0;
        }

        // std.log.debug("{s}\n", .{[_]u8{'='} ** 20});
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    defer _ = gpa.deinit();

    try sdl.init(.{
        .video = true,
        .events = true,
    });
    defer sdl.quit();

    var args = try std.process.argsWithAllocator(alloc);
    defer args.deinit();

    _ = args.skip();
    const path = args.next() orelse return error.MissingRomPath;
    std.log.debug("filepath: {s}\n", .{path});

    var cartridge = Cartridge.init(alloc);
    defer cartridge.deinit();
    try cartridge.load(path);
    try cartridge.verify();

    var bus = Bus.init(&cartridge);
    var ppu = try Ppu.init(&bus);
    defer ppu.deinit();
    var cpu = Cpu.init(&bus, &ppu);

    // Start emulator thread
    const emu_thread = try std.Thread.spawn(.{}, emu_run, .{ &cpu, &ppu });
    defer emu_thread.join();

    // Main event and render loop
    var frame_timer = try std.time.Timer.start();
    const target_frame_time = std.time.ns_per_s / 60;

    while (Ctx.running) {
        // Handle SDL events
        while (sdl.pollEvent()) |event| {
            switch (event) {
                .quit => Ctx.running = false,
                else => {},
            }
        }

        // Render if a frame is ready
        if (ppu.frame_complete) {
            try ppu.render();
        }

        // Frame timing
        const elapsed = frame_timer.lap();
        if (elapsed < target_frame_time) {
            std.time.sleep(target_frame_time - elapsed);
        }
    }
}
