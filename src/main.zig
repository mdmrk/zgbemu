const std = @import("std");
const Cartridge = @import("Cartridge.zig");
const Cpu = @import("Cpu.zig");
const Bus = @import("Bus.zig");
const c = @cImport({
    @cInclude("SDL3/SDL.h");
});

const Context = struct {
    var running: bool = true;
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    defer _ = gpa.deinit();

    var args = try std.process.argsWithAllocator(alloc);
    defer args.deinit();

    _ = args.skip();
    const path = args.next() orelse return error.MissingRomPath;
    std.debug.print("{s}\n", .{path});

    var cardtrige = Cartridge.init(alloc);
    defer cardtrige.deinit();
    try cardtrige.load(path);
    try cardtrige.verify();

    var bus = Bus.init(&cardtrige);

    var cpu = Cpu.init(&bus);

    while (Context.running) {
        try cpu.step();
        cpu.print();
        _ = try std.io.getStdIn().reader().readByte();
    }
}
