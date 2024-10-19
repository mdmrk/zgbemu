const std = @import("std");
const Cartridge = @import("Cartridge.zig");

const Bus = @This();

cartridge: *Cartridge,

pub fn init(cartridge: *Cartridge) Bus {
    return .{
        .cartridge = cartridge,
    };
}

pub inline fn read(self: *Bus, address: u16, bytes: u8) []const u8 {
    return self.cartridge.read(address, bytes);
}

pub inline fn write(self: *Bus, address: u16, value: u8) u8 {
    self.cartridge.write(address, value);
}
