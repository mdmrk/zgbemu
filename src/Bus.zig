const std = @import("std");
const Cartridge = @import("Cartridge.zig");

const Bus = @This();

cartridge: *Cartridge,
wram: [8 * 1024]u8,
hram: [127]u8,
vram: [16 * 1024]u8,
oam: [0xFE9F - 0xFE00 + 1]u8,

pub fn init(cartridge: *Cartridge) Bus {
    return .{
        .cartridge = cartridge,
        .wram = [_]u8{0} ** (8 * 1024),
        .hram = [_]u8{0} ** 127,
        .vram = [_]u8{0} ** (16 * 1024),
        .oam = [_]u8{0} ** (0xFE9F - 0xFE00 + 1),
    };
}

pub inline fn read(self: *Bus, address: u16) u8 {
    return switch (address) {
        0xFF80...0xFFFE => self.hram[address - 0xFF80],
        0xFEA0...0xFEFF => undefined,
        0xFE00...0xFE9F => self.oam[address - 0xFE00],
        0xE000...0xFDFF => self.wram[address - 0xE000],
        0xC000...0xDFFF => self.wram[address - 0xC000],
        0x8000...0x9FFF => self.vram[address - 0x8000],
        0x0000...0x7FFF,
        0xA000...0xBFFF,
        => self.cartridge.read(address),
        else => unreachable,
    };
}

pub inline fn write(self: *Bus, address: u16, value: u8) void {
    switch (address) {
        0xFF80...0xFFFE => self.hram[address - 0xFF80] = value,
        0xFEA0...0xFEFF => undefined,
        0xFE00...0xFE9F => self.oam[address - 0xFE00] = value,
        0xE000...0xFDFF => self.wram[address - 0xE000] = value,
        0xC000...0xDFFF => self.wram[address - 0xC000] = value,
        0x8000...0x9FFF => self.vram[address - 0x8000] = value,
        0x0000...0x7FFF,
        0xA000...0xBFFF,
        => self.cartridge.write(address, value) catch |err| switch (err) {
            error.ReadOnlyMemory => {},
        },
        else => unreachable,
    }
}

// 0xFFFF        Interrupt Enable Register (IE)
// 0xFF80-0xFFFE High RAM (HRAM)
// 0xFF00-0xFF7F Hardware I/O Registers
// 0xFEA0-0xFEFF Not Usable
// 0xFE00-0xFE9F Object Attribute Memory (OAM)
// 0xE000-0xFDFF Echo RAM (mirror of C000-DDFF)
// 0xD000-0xDFFF Work RAM (WRAM) Bank 1-7
// 0xC000-0xCFFF Work RAM (WRAM) Bank 0
// 0xA000-0xBFFF External RAM (in cartridge)
// 0x8000-0x9FFF Video RAM (VRAM)
// 0x4000-0x7FFF Switchable ROM Banks
// 0x0000-0x3FFF ROM Bank 0
