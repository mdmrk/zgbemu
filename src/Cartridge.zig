const std = @import("std");
const File = std.fs.File;
const Allocator = std.mem.Allocator;
const Cartridge = @This();

const header_entry_point: u16 = 0x0100;
const header_end_point: u16 = 0x014F;
const header_len: u16 = header_end_point - header_entry_point + 1;

alloc: Allocator,
filename: []const u8,
header: CartridgeHeader,
rom: []u8,

const CartridgeHeader = struct {
    entry_point: [4]u8,
    nintendo_logo: [48]u8,
    title: [16]u8,
    licensee_code: [2]u8,
    sgb_flag: [1]u8,
    cartridge_type: [1]u8,
    rom_size: [1]u8,
    ram_size: [1]u8,
    destination_code: [1]u8,
    old_licensee_code: [1]u8,
    mask_rom_version: [1]u8,
    header_checksum: [1]u8,
    global_checksum: [2]u8,

    const nintendo_logo_bytes = [48]u8{ 0xCE, 0xED, 0x66, 0x66, 0xCC, 0x0D, 0x00, 0x0B, 0x03, 0x73, 0x00, 0x83, 0x00, 0x0C, 0x00, 0x0D, 0x00, 0x08, 0x11, 0x1F, 0x88, 0x89, 0x00, 0x0E, 0xDC, 0xCC, 0x6E, 0xE6, 0xDD, 0xDD, 0xD9, 0x99, 0xBB, 0xBB, 0x67, 0x63, 0x6E, 0x0E, 0xEC, 0xCC, 0xDD, 0xDC, 0x99, 0x9F, 0xBB, 0xB9, 0x33, 0x3E };

    fn verify_checksum(_: *CartridgeHeader, rom: []const u8) bool {
        var checksum: u8 = 0;
        const address: u16 = 0x0134;

        inline for (address..(0x014C + 1)) |i| {
            checksum = checksum - rom[i] - 1;
        }
        return rom[0x14D] == checksum & 0xFF;
    }

    pub fn verify(self: *CartridgeHeader, _: []const u8) !void {
        if (!std.mem.eql(u8, &self.nintendo_logo, &nintendo_logo_bytes)) {
            return error.WrongNintendoLogo;
        }
        // if (!self.verify_checksum(rom)) {
        //     return error.BadHeader;
        // }
    }

    comptime {
        std.debug.assert(@sizeOf(CartridgeHeader) == header_len);
    }
};

pub fn load(self: *Cartridge, path: []const u8) !void {
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();
    const rom = try file.readToEndAlloc(self.alloc, std.math.maxInt(usize));

    self.filename = std.fs.path.basename(path);
    self.rom = rom;
    self.header = CartridgeHeader{
        .entry_point = self.rom[0x100..0x104].*,
        .nintendo_logo = self.rom[0x104..0x134].*,
        .title = self.rom[0x134..0x144].*,
        .licensee_code = self.rom[0x144..0x146].*,
        .sgb_flag = self.rom[0x146..0x147].*,
        .cartridge_type = self.rom[0x147..0x148].*,
        .rom_size = self.rom[0x148..0x149].*,
        .ram_size = self.rom[0x149..0x14A].*,
        .destination_code = self.rom[0x14A..0x14B].*,
        .old_licensee_code = self.rom[0x14B..0x14C].*,
        .mask_rom_version = self.rom[0x14C..0x14D].*,
        .header_checksum = self.rom[0x14D..0x14E].*,
        .global_checksum = self.rom[0x14E..0x150].*,
    };
    self.header.title[15] = 0;
}

pub fn verify(self: *Cartridge) !void {
    try self.header.verify(self.rom);
}

pub inline fn read(self: *Cartridge, address: u16, bytes: u8) []const u8 {
    return self.rom[address..(address + bytes)];
}

pub inline fn write(self: *Cartridge, address: u16, value: u8) void {
    self.rom[address] = value;
}

pub fn init(alloc: Allocator) Cartridge {
    return .{
        .alloc = alloc,
        .filename = undefined,
        .header = undefined,
        .rom = undefined,
    };
}

pub fn deinit(self: *Cartridge) void {
    self.alloc.free(self.rom);
}
