const std = @import("std");
const Cartridge = @import("Cartridge.zig");

const Bus = @This();

cartridge: *Cartridge,
wram: [8 * 1024]u8,
hram: [127]u8,
vram: [16 * 1024]u8,
oam: [160]u8,
io: [128]u8,
ie: u8,

pub fn init(cartridge: *Cartridge) Bus {
    const DIV_ADDR: u16 = 0xFF04;
    var bus: Bus = .{
        .cartridge = cartridge,
        .wram = [_]u8{0} ** (8 * 1024),
        .hram = [_]u8{0} ** 127,
        .vram = [_]u8{0} ** (16 * 1024),
        .oam = [_]u8{0} ** 160,
        .io = [_]u8{0} ** 128,
        .ie = 0,
    };
    bus.io[DIV_ADDR - 0xFF00] = 0xAB;
    return bus;
}

pub inline fn read(self: *Bus, address: u16) u8 {
    return switch (address) {
        0x0000...0x7FFF,
        0xA000...0xBFFF,
        => self.cartridge.read(address),
        0x8000...0x9FFF => self.vram[address - 0x8000],
        0xC000...0xDFFF => self.wram[address - 0xC000],
        0xE000...0xFDFF => self.wram[address - 0xE000],
        0xFE00...0xFE9F => self.oam[address - 0xFE00],
        0xFEA0...0xFEFF => undefined,
        0xFF00...0xFF7F => self.io[address - 0xFF00],
        0xFF80...0xFFFE => self.hram[address - 0xFF80],
        0xFFFF => self.ie,
    };
}

pub inline fn write(self: *Bus, address: u16, value: u8) void {
    switch (address) {
        0x0000...0x7FFF,
        0xA000...0xBFFF,
        => self.cartridge.write(address, value),
        0x8000...0x9FFF => self.vram[address - 0x8000] = value,
        0xC000...0xDFFF => self.wram[address - 0xC000] = value,
        0xE000...0xFDFF => self.wram[address - 0xE000] = value,
        0xFE00...0xFE9F => self.oam[address - 0xFE00] = value,
        0xFEA0...0xFEFF => undefined,
        0xFF00...0xFF03,
        0xFF05...0xFF7F,
        => self.io[address - 0xFF00] = value,
        0xFF04 => self.io[address - 0xFF00] = 0,
        0xFF80...0xFFFE => self.hram[address - 0xFF80] = value,
        0xFFFF => self.ie = value,
    }
}

pub inline fn inc_div(self: *Bus) void {
    const DIV_ADDR: u16 = 0xFF04;
    self.io[DIV_ADDR - 0xFF00] +%= 1;
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
