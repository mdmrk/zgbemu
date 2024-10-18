const std = @import("std");
const Cartridge = @import("Cartridge.zig");

const Bus = @This();

cartridge: *Cartridge,

pub fn init(cartridge_ptr: *Cartridge) Bus {
    return .{
        .cartridge = cartridge_ptr,
    };
}

pub fn read(self: *Bus, address: u16, bytes: u8) []const u8 {
    return self.cartridge.read(address, bytes);
}

pub fn write(self: *Bus, address: u16, value: u8) u8 {
    self.cartridge.write(address, value);
}
