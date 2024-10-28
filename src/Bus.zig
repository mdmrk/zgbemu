const std = @import("std");
const Cartridge = @import("Cartridge.zig");

const Bus = @This();

cartridge: *Cartridge,
memory: [0xFFFF]u8,

pub fn init(cartridge: *Cartridge) Bus {
    return .{
        .cartridge = cartridge,
        .memory = [_]u8{0} ** 0xFFFF,
    };
}

pub inline fn read_byte(self: *Bus, address: u16) u8 {
    return self.cartridge.read_byte(address);
}

pub inline fn read(self: *Bus, address: u16, bytes: u8) []const u8 {
    return self.cartridge.read(address, bytes);
}

pub inline fn write(self: *Bus, address: u16, value: u8) void {
    self.cartridge.write(address, value);
}
