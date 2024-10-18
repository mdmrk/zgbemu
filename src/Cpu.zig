const std = @import("std");
const Bus = @import("Bus.zig");

const Cpu = @This();

const Clock = struct {
    m: u16 = 0,
    t: u16 = 0,
};

const Operand = struct {
    name: []const u8,
    immediate: bool,
    bytes: u8 = undefined,
};

const Op = struct {
    mnemonic: []const u8,
    bytes: u8,
    cycles: []const u8,
    operands: []const Operand = &[_]Operand{},
    immediate: bool,
    flags: struct {
        z: u8,
        n: u8,
        h: u8,
        c: u8,
    },
};

fn fetch_op(opcode: u8) Op {
    return switch (opcode) {
        0x00 => Op{
            .mnemonic = "NOP",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0x01 => Op{
            .mnemonic = "LD",
            .bytes = 3,
            .cycles = &[_]u8{12},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "BC",
                    .immediate = true,
                },
                .{
                    .name = "n16",
                    .bytes = 2,
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0x02 => Op{
            .mnemonic = "LD",
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = false,
            .operands = &[_]Operand{
                .{
                    .name = "BC",
                    .immediate = false,
                },
                .{
                    .name = "A",
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0x03 => Op{
            .mnemonic = "INC",
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "BC",
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0x04 => Op{
            .mnemonic = "INC",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "B",
                    .immediate = true,
                },
            },
            .flags = .{ .z = 'z', .n = '0', .h = 'h', .c = '-' },
        },
        0x05 => Op{
            .mnemonic = "DEC",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "B",
                    .immediate = true,
                },
            },
            .flags = .{ .z = 'z', .n = '1', .h = 'h', .c = '-' },
        },
        0x06 => Op{
            .mnemonic = "LD",
            .bytes = 2,
            .cycles = &[_]u8{8},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "B",
                    .immediate = true,
                },
                .{
                    .name = "n8",
                    .bytes = 1,
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0x07 => Op{
            .mnemonic = "RLCA",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .flags = .{ .z = '0', .n = '0', .h = '0', .c = 'c' },
        },
        0x08 => Op{
            .mnemonic = "LD",
            .bytes = 3,
            .cycles = &[_]u8{20},
            .immediate = false,
            .operands = &[_]Operand{
                .{
                    .name = "a16",
                    .bytes = 2,
                    .immediate = false,
                },
                .{
                    .name = "SP",
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0x09 => Op{
            .mnemonic = "ADD",
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "HL",
                    .immediate = true,
                },
                .{
                    .name = "BC",
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '0', .h = 'h', .c = 'c' },
        },
        0x0A => Op{
            .mnemonic = "LD",
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = false,
            .operands = &[_]Operand{
                .{
                    .name = "A",
                    .immediate = true,
                },
                .{
                    .name = "BC",
                    .immediate = false,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0x0B => Op{
            .mnemonic = "DEC",
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "BC",
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0x0C => Op{
            .mnemonic = "INC",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "C",
                    .immediate = true,
                },
            },
            .flags = .{ .z = 'z', .n = '0', .h = 'h', .c = '-' },
        },
        0x0D => Op{
            .mnemonic = "DEC",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "C",
                    .immediate = true,
                },
            },
            .flags = .{ .z = 'z', .n = '1', .h = 'h', .c = '-' },
        },
        0x0E => Op{
            .mnemonic = "LD",
            .bytes = 2,
            .cycles = &[_]u8{8},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "C",
                    .immediate = true,
                },
                .{
                    .name = "n8",
                    .bytes = 1,
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0x0F => Op{
            .mnemonic = "RRCA",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .flags = .{ .z = '0', .n = '0', .h = '0', .c = 'c' },
        },
        0x10 => Op{
            .mnemonic = "STOP",
            .bytes = 2,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "n8",
                    .bytes = 1,
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0x11 => Op{
            .mnemonic = "LD",
            .bytes = 3,
            .cycles = &[_]u8{12},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "DE",
                    .immediate = true,
                },
                .{
                    .name = "n16",
                    .bytes = 2,
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0x12 => Op{
            .mnemonic = "LD",
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = false,
            .operands = &[_]Operand{
                .{
                    .name = "DE",
                    .immediate = false,
                },
                .{
                    .name = "A",
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0x13 => Op{
            .mnemonic = "INC",
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "DE",
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0x14 => Op{
            .mnemonic = "INC",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "D",
                    .immediate = true,
                },
            },
            .flags = .{ .z = 'z', .n = '0', .h = 'h', .c = '-' },
        },
        0x15 => Op{
            .mnemonic = "DEC",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "D",
                    .immediate = true,
                },
            },
            .flags = .{ .z = 'z', .n = '1', .h = 'h', .c = '-' },
        },
        0x16 => Op{
            .mnemonic = "LD",
            .bytes = 2,
            .cycles = &[_]u8{8},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "D",
                    .immediate = true,
                },
                .{
                    .name = "n8",
                    .bytes = 1,
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0x17 => Op{
            .mnemonic = "RLA",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .flags = .{ .z = '0', .n = '0', .h = '0', .c = 'c' },
        },
        0x18 => Op{
            .mnemonic = "JR",
            .bytes = 2,
            .cycles = &[_]u8{12},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "e8",
                    .bytes = 1,
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0x19 => Op{
            .mnemonic = "ADD",
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "HL",
                    .immediate = true,
                },
                .{
                    .name = "DE",
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '0', .h = 'h', .c = 'c' },
        },
        0x1A => Op{
            .mnemonic = "LD",
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = false,
            .operands = &[_]Operand{
                .{
                    .name = "A",
                    .immediate = true,
                },
                .{
                    .name = "DE",
                    .immediate = false,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0x1B => Op{
            .mnemonic = "DEC",
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "DE",
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0x1C => Op{
            .mnemonic = "INC",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "E",
                    .immediate = true,
                },
            },
            .flags = .{ .z = 'z', .n = '0', .h = 'h', .c = '-' },
        },
        0x1D => Op{
            .mnemonic = "DEC",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "E",
                    .immediate = true,
                },
            },
            .flags = .{ .z = 'z', .n = '1', .h = 'h', .c = '-' },
        },
        0x1E => Op{
            .mnemonic = "LD",
            .bytes = 2,
            .cycles = &[_]u8{8},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "E",
                    .immediate = true,
                },
                .{
                    .name = "n8",
                    .bytes = 1,
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0x1F => Op{
            .mnemonic = "RRA",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .flags = .{ .z = '0', .n = '0', .h = '0', .c = 'c' },
        },
        0x20 => Op{
            .mnemonic = "JR",
            .bytes = 2,
            .cycles = &[_]u8{ 12, 8 },
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "NZ",
                    .immediate = true,
                },
                .{
                    .name = "e8",
                    .bytes = 1,
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0x21 => Op{
            .mnemonic = "LD",
            .bytes = 3,
            .cycles = &[_]u8{12},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "HL",
                    .immediate = true,
                },
                .{
                    .name = "n16",
                    .bytes = 2,
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0x22 => Op{
            .mnemonic = "LD",
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = false,
            .operands = &[_]Operand{
                .{
                    .name = "HL",
                    .immediate = false,
                },
                .{
                    .name = "A",
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0x23 => Op{
            .mnemonic = "INC",
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "HL",
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0x24 => Op{
            .mnemonic = "INC",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "H",
                    .immediate = true,
                },
            },
            .flags = .{ .z = 'z', .n = '0', .h = 'h', .c = '-' },
        },
        0x25 => Op{
            .mnemonic = "DEC",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "H",
                    .immediate = true,
                },
            },
            .flags = .{ .z = 'z', .n = '1', .h = 'h', .c = '-' },
        },
        0x26 => Op{
            .mnemonic = "LD",
            .bytes = 2,
            .cycles = &[_]u8{8},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "H",
                    .immediate = true,
                },
                .{
                    .name = "n8",
                    .bytes = 1,
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0x27 => Op{
            .mnemonic = "DAA",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .flags = .{ .z = 'z', .n = '-', .h = '0', .c = 'c' },
        },
        0x28 => Op{
            .mnemonic = "JR",
            .bytes = 2,
            .cycles = &[_]u8{ 12, 8 },
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "Z",
                    .immediate = true,
                },
                .{
                    .name = "e8",
                    .bytes = 1,
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0x29 => Op{
            .mnemonic = "ADD",
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "HL",
                    .immediate = true,
                },
                .{
                    .name = "HL",
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '0', .h = 'h', .c = 'c' },
        },
        0x2A => Op{
            .mnemonic = "LD",
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = false,
            .operands = &[_]Operand{
                .{
                    .name = "A",
                    .immediate = true,
                },
                .{
                    .name = "HL",
                    .immediate = false,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0x2B => Op{
            .mnemonic = "DEC",
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "HL",
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0x2C => Op{
            .mnemonic = "INC",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "L",
                    .immediate = true,
                },
            },
            .flags = .{ .z = 'z', .n = '0', .h = 'h', .c = '-' },
        },
        0x2D => Op{
            .mnemonic = "DEC",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "L",
                    .immediate = true,
                },
            },
            .flags = .{ .z = 'z', .n = '1', .h = 'h', .c = '-' },
        },
        0x2E => Op{
            .mnemonic = "LD",
            .bytes = 2,
            .cycles = &[_]u8{8},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "L",
                    .immediate = true,
                },
                .{
                    .name = "n8",
                    .bytes = 1,
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0x2F => Op{
            .mnemonic = "CPL",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .flags = .{ .z = '-', .n = '1', .h = '1', .c = '-' },
        },
        0x30 => Op{
            .mnemonic = "JR",
            .bytes = 2,
            .cycles = &[_]u8{ 12, 8 },
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "NC",
                    .immediate = true,
                },
                .{
                    .name = "e8",
                    .bytes = 1,
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0x31 => Op{
            .mnemonic = "LD",
            .bytes = 3,
            .cycles = &[_]u8{12},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "SP",
                    .immediate = true,
                },
                .{
                    .name = "n16",
                    .bytes = 2,
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0x32 => Op{
            .mnemonic = "LD",
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = false,
            .operands = &[_]Operand{
                .{
                    .name = "HL",
                    .immediate = false,
                },
                .{
                    .name = "A",
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0x33 => Op{
            .mnemonic = "INC",
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "SP",
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0x34 => Op{
            .mnemonic = "INC",
            .bytes = 1,
            .cycles = &[_]u8{12},
            .immediate = false,
            .operands = &[_]Operand{
                .{
                    .name = "HL",
                    .immediate = false,
                },
            },
            .flags = .{ .z = 'z', .n = '0', .h = 'h', .c = '-' },
        },
        0x35 => Op{
            .mnemonic = "DEC",
            .bytes = 1,
            .cycles = &[_]u8{12},
            .immediate = false,
            .operands = &[_]Operand{
                .{
                    .name = "HL",
                    .immediate = false,
                },
            },
            .flags = .{ .z = 'z', .n = '1', .h = 'h', .c = '-' },
        },
        0x36 => Op{
            .mnemonic = "LD",
            .bytes = 2,
            .cycles = &[_]u8{12},
            .immediate = false,
            .operands = &[_]Operand{
                .{
                    .name = "HL",
                    .immediate = false,
                },
                .{
                    .name = "n8",
                    .bytes = 1,
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0x37 => Op{
            .mnemonic = "SCF",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .flags = .{ .z = '-', .n = '0', .h = '0', .c = '1' },
        },
        0x38 => Op{
            .mnemonic = "JR",
            .bytes = 2,
            .cycles = &[_]u8{ 12, 8 },
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "C",
                    .immediate = true,
                },
                .{
                    .name = "e8",
                    .bytes = 1,
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0x39 => Op{
            .mnemonic = "ADD",
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "HL",
                    .immediate = true,
                },
                .{
                    .name = "SP",
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '0', .h = 'h', .c = 'c' },
        },
        0x3A => Op{
            .mnemonic = "LD",
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = false,
            .operands = &[_]Operand{
                .{
                    .name = "A",
                    .immediate = true,
                },
                .{
                    .name = "HL",
                    .immediate = false,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0x3B => Op{
            .mnemonic = "DEC",
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "SP",
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0x3C => Op{
            .mnemonic = "INC",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "A",
                    .immediate = true,
                },
            },
            .flags = .{ .z = 'z', .n = '0', .h = 'h', .c = '-' },
        },
        0x3D => Op{
            .mnemonic = "DEC",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "A",
                    .immediate = true,
                },
            },
            .flags = .{ .z = 'z', .n = '1', .h = 'h', .c = '-' },
        },
        0x3E => Op{
            .mnemonic = "LD",
            .bytes = 2,
            .cycles = &[_]u8{8},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "A",
                    .immediate = true,
                },
                .{
                    .name = "n8",
                    .bytes = 1,
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0x3F => Op{
            .mnemonic = "CCF",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .flags = .{ .z = '-', .n = '0', .h = '0', .c = 'c' },
        },
        0x40 => Op{
            .mnemonic = "LD",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "B",
                    .immediate = true,
                },
                .{
                    .name = "B",
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0x41 => Op{
            .mnemonic = "LD",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "B",
                    .immediate = true,
                },
                .{
                    .name = "C",
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0x42 => Op{
            .mnemonic = "LD",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "B",
                    .immediate = true,
                },
                .{
                    .name = "D",
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0x43 => Op{
            .mnemonic = "LD",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "B",
                    .immediate = true,
                },
                .{
                    .name = "E",
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0x44 => Op{
            .mnemonic = "LD",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "B",
                    .immediate = true,
                },
                .{
                    .name = "H",
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0x45 => Op{
            .mnemonic = "LD",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "B",
                    .immediate = true,
                },
                .{
                    .name = "L",
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0x46 => Op{
            .mnemonic = "LD",
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = false,
            .operands = &[_]Operand{
                .{
                    .name = "B",
                    .immediate = true,
                },
                .{
                    .name = "HL",
                    .immediate = false,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0x47 => Op{
            .mnemonic = "LD",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "B",
                    .immediate = true,
                },
                .{
                    .name = "A",
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0x48 => Op{
            .mnemonic = "LD",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "C",
                    .immediate = true,
                },
                .{
                    .name = "B",
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0x49 => Op{
            .mnemonic = "LD",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "C",
                    .immediate = true,
                },
                .{
                    .name = "C",
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0x4A => Op{
            .mnemonic = "LD",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "C",
                    .immediate = true,
                },
                .{
                    .name = "D",
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0x4B => Op{
            .mnemonic = "LD",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "C",
                    .immediate = true,
                },
                .{
                    .name = "E",
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0x4C => Op{
            .mnemonic = "LD",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "C",
                    .immediate = true,
                },
                .{
                    .name = "H",
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0x4D => Op{
            .mnemonic = "LD",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "C",
                    .immediate = true,
                },
                .{
                    .name = "L",
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0x4E => Op{
            .mnemonic = "LD",
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = false,
            .operands = &[_]Operand{
                .{
                    .name = "C",
                    .immediate = true,
                },
                .{
                    .name = "HL",
                    .immediate = false,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0x4F => Op{
            .mnemonic = "LD",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "C",
                    .immediate = true,
                },
                .{
                    .name = "A",
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0x50 => Op{
            .mnemonic = "LD",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "D",
                    .immediate = true,
                },
                .{
                    .name = "B",
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0x51 => Op{
            .mnemonic = "LD",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "D",
                    .immediate = true,
                },
                .{
                    .name = "C",
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0x52 => Op{
            .mnemonic = "LD",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "D",
                    .immediate = true,
                },
                .{
                    .name = "D",
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0x53 => Op{
            .mnemonic = "LD",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "D",
                    .immediate = true,
                },
                .{
                    .name = "E",
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0x54 => Op{
            .mnemonic = "LD",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "D",
                    .immediate = true,
                },
                .{
                    .name = "H",
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0x55 => Op{
            .mnemonic = "LD",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "D",
                    .immediate = true,
                },
                .{
                    .name = "L",
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0x56 => Op{
            .mnemonic = "LD",
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = false,
            .operands = &[_]Operand{
                .{
                    .name = "D",
                    .immediate = true,
                },
                .{
                    .name = "HL",
                    .immediate = false,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0x57 => Op{
            .mnemonic = "LD",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "D",
                    .immediate = true,
                },
                .{
                    .name = "A",
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0x58 => Op{
            .mnemonic = "LD",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "E",
                    .immediate = true,
                },
                .{
                    .name = "B",
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0x59 => Op{
            .mnemonic = "LD",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "E",
                    .immediate = true,
                },
                .{
                    .name = "C",
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0x5A => Op{
            .mnemonic = "LD",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "E",
                    .immediate = true,
                },
                .{
                    .name = "D",
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0x5B => Op{
            .mnemonic = "LD",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "E",
                    .immediate = true,
                },
                .{
                    .name = "E",
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0x5C => Op{
            .mnemonic = "LD",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "E",
                    .immediate = true,
                },
                .{
                    .name = "H",
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0x5D => Op{
            .mnemonic = "LD",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "E",
                    .immediate = true,
                },
                .{
                    .name = "L",
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0x5E => Op{
            .mnemonic = "LD",
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = false,
            .operands = &[_]Operand{
                .{
                    .name = "E",
                    .immediate = true,
                },
                .{
                    .name = "HL",
                    .immediate = false,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0x5F => Op{
            .mnemonic = "LD",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "E",
                    .immediate = true,
                },
                .{
                    .name = "A",
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0x60 => Op{
            .mnemonic = "LD",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "H",
                    .immediate = true,
                },
                .{
                    .name = "B",
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0x61 => Op{
            .mnemonic = "LD",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "H",
                    .immediate = true,
                },
                .{
                    .name = "C",
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0x62 => Op{
            .mnemonic = "LD",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "H",
                    .immediate = true,
                },
                .{
                    .name = "D",
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0x63 => Op{
            .mnemonic = "LD",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "H",
                    .immediate = true,
                },
                .{
                    .name = "E",
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0x64 => Op{
            .mnemonic = "LD",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "H",
                    .immediate = true,
                },
                .{
                    .name = "H",
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0x65 => Op{
            .mnemonic = "LD",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "H",
                    .immediate = true,
                },
                .{
                    .name = "L",
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0x66 => Op{
            .mnemonic = "LD",
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = false,
            .operands = &[_]Operand{
                .{
                    .name = "H",
                    .immediate = true,
                },
                .{
                    .name = "HL",
                    .immediate = false,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0x67 => Op{
            .mnemonic = "LD",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "H",
                    .immediate = true,
                },
                .{
                    .name = "A",
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0x68 => Op{
            .mnemonic = "LD",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "L",
                    .immediate = true,
                },
                .{
                    .name = "B",
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0x69 => Op{
            .mnemonic = "LD",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "L",
                    .immediate = true,
                },
                .{
                    .name = "C",
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0x6A => Op{
            .mnemonic = "LD",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "L",
                    .immediate = true,
                },
                .{
                    .name = "D",
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0x6B => Op{
            .mnemonic = "LD",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "L",
                    .immediate = true,
                },
                .{
                    .name = "E",
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0x6C => Op{
            .mnemonic = "LD",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "L",
                    .immediate = true,
                },
                .{
                    .name = "H",
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0x6D => Op{
            .mnemonic = "LD",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "L",
                    .immediate = true,
                },
                .{
                    .name = "L",
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0x6E => Op{
            .mnemonic = "LD",
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = false,
            .operands = &[_]Operand{
                .{
                    .name = "L",
                    .immediate = true,
                },
                .{
                    .name = "HL",
                    .immediate = false,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0x6F => Op{
            .mnemonic = "LD",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "L",
                    .immediate = true,
                },
                .{
                    .name = "A",
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0x70 => Op{
            .mnemonic = "LD",
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = false,
            .operands = &[_]Operand{
                .{
                    .name = "HL",
                    .immediate = false,
                },
                .{
                    .name = "B",
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0x71 => Op{
            .mnemonic = "LD",
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = false,
            .operands = &[_]Operand{
                .{
                    .name = "HL",
                    .immediate = false,
                },
                .{
                    .name = "C",
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0x72 => Op{
            .mnemonic = "LD",
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = false,
            .operands = &[_]Operand{
                .{
                    .name = "HL",
                    .immediate = false,
                },
                .{
                    .name = "D",
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0x73 => Op{
            .mnemonic = "LD",
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = false,
            .operands = &[_]Operand{
                .{
                    .name = "HL",
                    .immediate = false,
                },
                .{
                    .name = "E",
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0x74 => Op{
            .mnemonic = "LD",
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = false,
            .operands = &[_]Operand{
                .{
                    .name = "HL",
                    .immediate = false,
                },
                .{
                    .name = "H",
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0x75 => Op{
            .mnemonic = "LD",
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = false,
            .operands = &[_]Operand{
                .{
                    .name = "HL",
                    .immediate = false,
                },
                .{
                    .name = "L",
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0x76 => Op{
            .mnemonic = "HALT",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0x77 => Op{
            .mnemonic = "LD",
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = false,
            .operands = &[_]Operand{
                .{
                    .name = "HL",
                    .immediate = false,
                },
                .{
                    .name = "A",
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0x78 => Op{
            .mnemonic = "LD",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "A",
                    .immediate = true,
                },
                .{
                    .name = "B",
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0x79 => Op{
            .mnemonic = "LD",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "A",
                    .immediate = true,
                },
                .{
                    .name = "C",
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0x7A => Op{
            .mnemonic = "LD",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "A",
                    .immediate = true,
                },
                .{
                    .name = "D",
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0x7B => Op{
            .mnemonic = "LD",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "A",
                    .immediate = true,
                },
                .{
                    .name = "E",
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0x7C => Op{
            .mnemonic = "LD",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "A",
                    .immediate = true,
                },
                .{
                    .name = "H",
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0x7D => Op{
            .mnemonic = "LD",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "A",
                    .immediate = true,
                },
                .{
                    .name = "L",
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0x7E => Op{
            .mnemonic = "LD",
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = false,
            .operands = &[_]Operand{
                .{
                    .name = "A",
                    .immediate = true,
                },
                .{
                    .name = "HL",
                    .immediate = false,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0x7F => Op{
            .mnemonic = "LD",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "A",
                    .immediate = true,
                },
                .{
                    .name = "A",
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0x80 => Op{
            .mnemonic = "ADD",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "A",
                    .immediate = true,
                },
                .{
                    .name = "B",
                    .immediate = true,
                },
            },
            .flags = .{ .z = 'z', .n = '0', .h = 'h', .c = 'c' },
        },
        0x81 => Op{
            .mnemonic = "ADD",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "A",
                    .immediate = true,
                },
                .{
                    .name = "C",
                    .immediate = true,
                },
            },
            .flags = .{ .z = 'z', .n = '0', .h = 'h', .c = 'c' },
        },
        0x82 => Op{
            .mnemonic = "ADD",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "A",
                    .immediate = true,
                },
                .{
                    .name = "D",
                    .immediate = true,
                },
            },
            .flags = .{ .z = 'z', .n = '0', .h = 'h', .c = 'c' },
        },
        0x83 => Op{
            .mnemonic = "ADD",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "A",
                    .immediate = true,
                },
                .{
                    .name = "E",
                    .immediate = true,
                },
            },
            .flags = .{ .z = 'z', .n = '0', .h = 'h', .c = 'c' },
        },
        0x84 => Op{
            .mnemonic = "ADD",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "A",
                    .immediate = true,
                },
                .{
                    .name = "H",
                    .immediate = true,
                },
            },
            .flags = .{ .z = 'z', .n = '0', .h = 'h', .c = 'c' },
        },
        0x85 => Op{
            .mnemonic = "ADD",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "A",
                    .immediate = true,
                },
                .{
                    .name = "L",
                    .immediate = true,
                },
            },
            .flags = .{ .z = 'z', .n = '0', .h = 'h', .c = 'c' },
        },
        0x86 => Op{
            .mnemonic = "ADD",
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = false,
            .operands = &[_]Operand{
                .{
                    .name = "A",
                    .immediate = true,
                },
                .{
                    .name = "HL",
                    .immediate = false,
                },
            },
            .flags = .{ .z = 'z', .n = '0', .h = 'h', .c = 'c' },
        },
        0x87 => Op{
            .mnemonic = "ADD",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "A",
                    .immediate = true,
                },
                .{
                    .name = "A",
                    .immediate = true,
                },
            },
            .flags = .{ .z = 'z', .n = '0', .h = 'h', .c = 'c' },
        },
        0x88 => Op{
            .mnemonic = "ADC",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "A",
                    .immediate = true,
                },
                .{
                    .name = "B",
                    .immediate = true,
                },
            },
            .flags = .{ .z = 'z', .n = '0', .h = 'h', .c = 'c' },
        },
        0x89 => Op{
            .mnemonic = "ADC",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "A",
                    .immediate = true,
                },
                .{
                    .name = "C",
                    .immediate = true,
                },
            },
            .flags = .{ .z = 'z', .n = '0', .h = 'h', .c = 'c' },
        },
        0x8A => Op{
            .mnemonic = "ADC",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "A",
                    .immediate = true,
                },
                .{
                    .name = "D",
                    .immediate = true,
                },
            },
            .flags = .{ .z = 'z', .n = '0', .h = 'h', .c = 'c' },
        },
        0x8B => Op{
            .mnemonic = "ADC",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "A",
                    .immediate = true,
                },
                .{
                    .name = "E",
                    .immediate = true,
                },
            },
            .flags = .{ .z = 'z', .n = '0', .h = 'h', .c = 'c' },
        },
        0x8C => Op{
            .mnemonic = "ADC",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "A",
                    .immediate = true,
                },
                .{
                    .name = "H",
                    .immediate = true,
                },
            },
            .flags = .{ .z = 'z', .n = '0', .h = 'h', .c = 'c' },
        },
        0x8D => Op{
            .mnemonic = "ADC",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "A",
                    .immediate = true,
                },
                .{
                    .name = "L",
                    .immediate = true,
                },
            },
            .flags = .{ .z = 'z', .n = '0', .h = 'h', .c = 'c' },
        },
        0x8E => Op{
            .mnemonic = "ADC",
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = false,
            .operands = &[_]Operand{
                .{
                    .name = "A",
                    .immediate = true,
                },
                .{
                    .name = "HL",
                    .immediate = false,
                },
            },
            .flags = .{ .z = 'z', .n = '0', .h = 'h', .c = 'c' },
        },
        0x8F => Op{
            .mnemonic = "ADC",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "A",
                    .immediate = true,
                },
                .{
                    .name = "A",
                    .immediate = true,
                },
            },
            .flags = .{ .z = 'z', .n = '0', .h = 'h', .c = 'c' },
        },
        0x90 => Op{
            .mnemonic = "SUB",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "A",
                    .immediate = true,
                },
                .{
                    .name = "B",
                    .immediate = true,
                },
            },
            .flags = .{ .z = 'z', .n = '1', .h = 'h', .c = 'c' },
        },
        0x91 => Op{
            .mnemonic = "SUB",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "A",
                    .immediate = true,
                },
                .{
                    .name = "C",
                    .immediate = true,
                },
            },
            .flags = .{ .z = 'z', .n = '1', .h = 'h', .c = 'c' },
        },
        0x92 => Op{
            .mnemonic = "SUB",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "A",
                    .immediate = true,
                },
                .{
                    .name = "D",
                    .immediate = true,
                },
            },
            .flags = .{ .z = 'z', .n = '1', .h = 'h', .c = 'c' },
        },
        0x93 => Op{
            .mnemonic = "SUB",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "A",
                    .immediate = true,
                },
                .{
                    .name = "E",
                    .immediate = true,
                },
            },
            .flags = .{ .z = 'z', .n = '1', .h = 'h', .c = 'c' },
        },
        0x94 => Op{
            .mnemonic = "SUB",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "A",
                    .immediate = true,
                },
                .{
                    .name = "H",
                    .immediate = true,
                },
            },
            .flags = .{ .z = 'z', .n = '1', .h = 'h', .c = 'c' },
        },
        0x95 => Op{
            .mnemonic = "SUB",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "A",
                    .immediate = true,
                },
                .{
                    .name = "L",
                    .immediate = true,
                },
            },
            .flags = .{ .z = 'z', .n = '1', .h = 'h', .c = 'c' },
        },
        0x96 => Op{
            .mnemonic = "SUB",
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = false,
            .operands = &[_]Operand{
                .{
                    .name = "A",
                    .immediate = true,
                },
                .{
                    .name = "HL",
                    .immediate = false,
                },
            },
            .flags = .{ .z = 'z', .n = '1', .h = 'h', .c = 'c' },
        },
        0x97 => Op{
            .mnemonic = "SUB",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "A",
                    .immediate = true,
                },
                .{
                    .name = "A",
                    .immediate = true,
                },
            },
            .flags = .{ .z = '1', .n = '1', .h = '0', .c = '0' },
        },
        0x98 => Op{
            .mnemonic = "SBC",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "A",
                    .immediate = true,
                },
                .{
                    .name = "B",
                    .immediate = true,
                },
            },
            .flags = .{ .z = 'z', .n = '1', .h = 'h', .c = 'c' },
        },
        0x99 => Op{
            .mnemonic = "SBC",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "A",
                    .immediate = true,
                },
                .{
                    .name = "C",
                    .immediate = true,
                },
            },
            .flags = .{ .z = 'z', .n = '1', .h = 'h', .c = 'c' },
        },
        0x9A => Op{
            .mnemonic = "SBC",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "A",
                    .immediate = true,
                },
                .{
                    .name = "D",
                    .immediate = true,
                },
            },
            .flags = .{ .z = 'z', .n = '1', .h = 'h', .c = 'c' },
        },
        0x9B => Op{
            .mnemonic = "SBC",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "A",
                    .immediate = true,
                },
                .{
                    .name = "E",
                    .immediate = true,
                },
            },
            .flags = .{ .z = 'z', .n = '1', .h = 'h', .c = 'c' },
        },
        0x9C => Op{
            .mnemonic = "SBC",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "A",
                    .immediate = true,
                },
                .{
                    .name = "H",
                    .immediate = true,
                },
            },
            .flags = .{ .z = 'z', .n = '1', .h = 'h', .c = 'c' },
        },
        0x9D => Op{
            .mnemonic = "SBC",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "A",
                    .immediate = true,
                },
                .{
                    .name = "L",
                    .immediate = true,
                },
            },
            .flags = .{ .z = 'z', .n = '1', .h = 'h', .c = 'c' },
        },
        0x9E => Op{
            .mnemonic = "SBC",
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = false,
            .operands = &[_]Operand{
                .{
                    .name = "A",
                    .immediate = true,
                },
                .{
                    .name = "HL",
                    .immediate = false,
                },
            },
            .flags = .{ .z = 'z', .n = '1', .h = 'h', .c = 'c' },
        },
        0x9F => Op{
            .mnemonic = "SBC",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "A",
                    .immediate = true,
                },
                .{
                    .name = "A",
                    .immediate = true,
                },
            },
            .flags = .{ .z = 'z', .n = '1', .h = 'h', .c = '-' },
        },
        0xA0 => Op{
            .mnemonic = "AND",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "A",
                    .immediate = true,
                },
                .{
                    .name = "B",
                    .immediate = true,
                },
            },
            .flags = .{ .z = 'z', .n = '0', .h = '1', .c = '0' },
        },
        0xA1 => Op{
            .mnemonic = "AND",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "A",
                    .immediate = true,
                },
                .{
                    .name = "C",
                    .immediate = true,
                },
            },
            .flags = .{ .z = 'z', .n = '0', .h = '1', .c = '0' },
        },
        0xA2 => Op{
            .mnemonic = "AND",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "A",
                    .immediate = true,
                },
                .{
                    .name = "D",
                    .immediate = true,
                },
            },
            .flags = .{ .z = 'z', .n = '0', .h = '1', .c = '0' },
        },
        0xA3 => Op{
            .mnemonic = "AND",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "A",
                    .immediate = true,
                },
                .{
                    .name = "E",
                    .immediate = true,
                },
            },
            .flags = .{ .z = 'z', .n = '0', .h = '1', .c = '0' },
        },
        0xA4 => Op{
            .mnemonic = "AND",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "A",
                    .immediate = true,
                },
                .{
                    .name = "H",
                    .immediate = true,
                },
            },
            .flags = .{ .z = 'z', .n = '0', .h = '1', .c = '0' },
        },
        0xA5 => Op{
            .mnemonic = "AND",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "A",
                    .immediate = true,
                },
                .{
                    .name = "L",
                    .immediate = true,
                },
            },
            .flags = .{ .z = 'z', .n = '0', .h = '1', .c = '0' },
        },
        0xA6 => Op{
            .mnemonic = "AND",
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = false,
            .operands = &[_]Operand{
                .{
                    .name = "A",
                    .immediate = true,
                },
                .{
                    .name = "HL",
                    .immediate = false,
                },
            },
            .flags = .{ .z = 'z', .n = '0', .h = '1', .c = '0' },
        },
        0xA7 => Op{
            .mnemonic = "AND",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "A",
                    .immediate = true,
                },
                .{
                    .name = "A",
                    .immediate = true,
                },
            },
            .flags = .{ .z = 'z', .n = '0', .h = '1', .c = '0' },
        },
        0xA8 => Op{
            .mnemonic = "XOR",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "A",
                    .immediate = true,
                },
                .{
                    .name = "B",
                    .immediate = true,
                },
            },
            .flags = .{ .z = 'z', .n = '0', .h = '0', .c = '0' },
        },
        0xA9 => Op{
            .mnemonic = "XOR",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "A",
                    .immediate = true,
                },
                .{
                    .name = "C",
                    .immediate = true,
                },
            },
            .flags = .{ .z = 'z', .n = '0', .h = '0', .c = '0' },
        },
        0xAA => Op{
            .mnemonic = "XOR",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "A",
                    .immediate = true,
                },
                .{
                    .name = "D",
                    .immediate = true,
                },
            },
            .flags = .{ .z = 'z', .n = '0', .h = '0', .c = '0' },
        },
        0xAB => Op{
            .mnemonic = "XOR",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "A",
                    .immediate = true,
                },
                .{
                    .name = "E",
                    .immediate = true,
                },
            },
            .flags = .{ .z = 'z', .n = '0', .h = '0', .c = '0' },
        },
        0xAC => Op{
            .mnemonic = "XOR",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "A",
                    .immediate = true,
                },
                .{
                    .name = "H",
                    .immediate = true,
                },
            },
            .flags = .{ .z = 'z', .n = '0', .h = '0', .c = '0' },
        },
        0xAD => Op{
            .mnemonic = "XOR",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "A",
                    .immediate = true,
                },
                .{
                    .name = "L",
                    .immediate = true,
                },
            },
            .flags = .{ .z = 'z', .n = '0', .h = '0', .c = '0' },
        },
        0xAE => Op{
            .mnemonic = "XOR",
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = false,
            .operands = &[_]Operand{
                .{
                    .name = "A",
                    .immediate = true,
                },
                .{
                    .name = "HL",
                    .immediate = false,
                },
            },
            .flags = .{ .z = 'z', .n = '0', .h = '0', .c = '0' },
        },
        0xAF => Op{
            .mnemonic = "XOR",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "A",
                    .immediate = true,
                },
                .{
                    .name = "A",
                    .immediate = true,
                },
            },
            .flags = .{ .z = '1', .n = '0', .h = '0', .c = '0' },
        },
        0xB0 => Op{
            .mnemonic = "OR",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "A",
                    .immediate = true,
                },
                .{
                    .name = "B",
                    .immediate = true,
                },
            },
            .flags = .{ .z = 'z', .n = '0', .h = '0', .c = '0' },
        },
        0xB1 => Op{
            .mnemonic = "OR",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "A",
                    .immediate = true,
                },
                .{
                    .name = "C",
                    .immediate = true,
                },
            },
            .flags = .{ .z = 'z', .n = '0', .h = '0', .c = '0' },
        },
        0xB2 => Op{
            .mnemonic = "OR",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "A",
                    .immediate = true,
                },
                .{
                    .name = "D",
                    .immediate = true,
                },
            },
            .flags = .{ .z = 'z', .n = '0', .h = '0', .c = '0' },
        },
        0xB3 => Op{
            .mnemonic = "OR",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "A",
                    .immediate = true,
                },
                .{
                    .name = "E",
                    .immediate = true,
                },
            },
            .flags = .{ .z = 'z', .n = '0', .h = '0', .c = '0' },
        },
        0xB4 => Op{
            .mnemonic = "OR",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "A",
                    .immediate = true,
                },
                .{
                    .name = "H",
                    .immediate = true,
                },
            },
            .flags = .{ .z = 'z', .n = '0', .h = '0', .c = '0' },
        },
        0xB5 => Op{
            .mnemonic = "OR",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "A",
                    .immediate = true,
                },
                .{
                    .name = "L",
                    .immediate = true,
                },
            },
            .flags = .{ .z = 'z', .n = '0', .h = '0', .c = '0' },
        },
        0xB6 => Op{
            .mnemonic = "OR",
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = false,
            .operands = &[_]Operand{
                .{
                    .name = "A",
                    .immediate = true,
                },
                .{
                    .name = "HL",
                    .immediate = false,
                },
            },
            .flags = .{ .z = 'z', .n = '0', .h = '0', .c = '0' },
        },
        0xB7 => Op{
            .mnemonic = "OR",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "A",
                    .immediate = true,
                },
                .{
                    .name = "A",
                    .immediate = true,
                },
            },
            .flags = .{ .z = 'z', .n = '0', .h = '0', .c = '0' },
        },
        0xB8 => Op{
            .mnemonic = "CP",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "A",
                    .immediate = true,
                },
                .{
                    .name = "B",
                    .immediate = true,
                },
            },
            .flags = .{ .z = 'z', .n = '1', .h = 'h', .c = 'c' },
        },
        0xB9 => Op{
            .mnemonic = "CP",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "A",
                    .immediate = true,
                },
                .{
                    .name = "C",
                    .immediate = true,
                },
            },
            .flags = .{ .z = 'z', .n = '1', .h = 'h', .c = 'c' },
        },
        0xBA => Op{
            .mnemonic = "CP",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "A",
                    .immediate = true,
                },
                .{
                    .name = "D",
                    .immediate = true,
                },
            },
            .flags = .{ .z = 'z', .n = '1', .h = 'h', .c = 'c' },
        },
        0xBB => Op{
            .mnemonic = "CP",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "A",
                    .immediate = true,
                },
                .{
                    .name = "E",
                    .immediate = true,
                },
            },
            .flags = .{ .z = 'z', .n = '1', .h = 'h', .c = 'c' },
        },
        0xBC => Op{
            .mnemonic = "CP",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "A",
                    .immediate = true,
                },
                .{
                    .name = "H",
                    .immediate = true,
                },
            },
            .flags = .{ .z = 'z', .n = '1', .h = 'h', .c = 'c' },
        },
        0xBD => Op{
            .mnemonic = "CP",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "A",
                    .immediate = true,
                },
                .{
                    .name = "L",
                    .immediate = true,
                },
            },
            .flags = .{ .z = 'z', .n = '1', .h = 'h', .c = 'c' },
        },
        0xBE => Op{
            .mnemonic = "CP",
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = false,
            .operands = &[_]Operand{
                .{
                    .name = "A",
                    .immediate = true,
                },
                .{
                    .name = "HL",
                    .immediate = false,
                },
            },
            .flags = .{ .z = 'z', .n = '1', .h = 'h', .c = 'c' },
        },
        0xBF => Op{
            .mnemonic = "CP",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "A",
                    .immediate = true,
                },
                .{
                    .name = "A",
                    .immediate = true,
                },
            },
            .flags = .{ .z = '1', .n = '1', .h = '0', .c = '0' },
        },
        0xC0 => Op{
            .mnemonic = "RET",
            .bytes = 1,
            .cycles = &[_]u8{ 20, 8 },
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "NZ",
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0xC1 => Op{
            .mnemonic = "POP",
            .bytes = 1,
            .cycles = &[_]u8{12},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "BC",
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0xC2 => Op{
            .mnemonic = "JP",
            .bytes = 3,
            .cycles = &[_]u8{ 16, 12 },
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "NZ",
                    .immediate = true,
                },
                .{
                    .name = "a16",
                    .bytes = 2,
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0xC3 => Op{
            .mnemonic = "JP",
            .bytes = 3,
            .cycles = &[_]u8{16},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "a16",
                    .bytes = 2,
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0xC4 => Op{
            .mnemonic = "CALL",
            .bytes = 3,
            .cycles = &[_]u8{ 24, 12 },
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "NZ",
                    .immediate = true,
                },
                .{
                    .name = "a16",
                    .bytes = 2,
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0xC5 => Op{
            .mnemonic = "PUSH",
            .bytes = 1,
            .cycles = &[_]u8{16},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "BC",
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0xC6 => Op{
            .mnemonic = "ADD",
            .bytes = 2,
            .cycles = &[_]u8{8},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "A",
                    .immediate = true,
                },
                .{
                    .name = "n8",
                    .bytes = 1,
                    .immediate = true,
                },
            },
            .flags = .{ .z = 'z', .n = '0', .h = 'h', .c = 'c' },
        },
        0xC7 => Op{
            .mnemonic = "RST",
            .bytes = 1,
            .cycles = &[_]u8{16},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "$00",
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0xC8 => Op{
            .mnemonic = "RET",
            .bytes = 1,
            .cycles = &[_]u8{ 20, 8 },
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "Z",
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0xC9 => Op{
            .mnemonic = "RET",
            .bytes = 1,
            .cycles = &[_]u8{16},
            .immediate = true,
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0xCA => Op{
            .mnemonic = "JP",
            .bytes = 3,
            .cycles = &[_]u8{ 16, 12 },
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "Z",
                    .immediate = true,
                },
                .{
                    .name = "a16",
                    .bytes = 2,
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0xCB => Op{
            .mnemonic = "PREFIX",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0xCC => Op{
            .mnemonic = "CALL",
            .bytes = 3,
            .cycles = &[_]u8{ 24, 12 },
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "Z",
                    .immediate = true,
                },
                .{
                    .name = "a16",
                    .bytes = 2,
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0xCD => Op{
            .mnemonic = "CALL",
            .bytes = 3,
            .cycles = &[_]u8{24},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "a16",
                    .bytes = 2,
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0xCE => Op{
            .mnemonic = "ADC",
            .bytes = 2,
            .cycles = &[_]u8{8},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "A",
                    .immediate = true,
                },
                .{
                    .name = "n8",
                    .bytes = 1,
                    .immediate = true,
                },
            },
            .flags = .{ .z = 'z', .n = '0', .h = 'h', .c = 'c' },
        },
        0xCF => Op{
            .mnemonic = "RST",
            .bytes = 1,
            .cycles = &[_]u8{16},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "$08",
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0xD0 => Op{
            .mnemonic = "RET",
            .bytes = 1,
            .cycles = &[_]u8{ 20, 8 },
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "NC",
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0xD1 => Op{
            .mnemonic = "POP",
            .bytes = 1,
            .cycles = &[_]u8{12},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "DE",
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0xD2 => Op{
            .mnemonic = "JP",
            .bytes = 3,
            .cycles = &[_]u8{ 16, 12 },
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "NC",
                    .immediate = true,
                },
                .{
                    .name = "a16",
                    .bytes = 2,
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0xD3 => Op{
            .mnemonic = "ILLEGAL_D3",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0xD4 => Op{
            .mnemonic = "CALL",
            .bytes = 3,
            .cycles = &[_]u8{ 24, 12 },
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "NC",
                    .immediate = true,
                },
                .{
                    .name = "a16",
                    .bytes = 2,
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0xD5 => Op{
            .mnemonic = "PUSH",
            .bytes = 1,
            .cycles = &[_]u8{16},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "DE",
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0xD6 => Op{
            .mnemonic = "SUB",
            .bytes = 2,
            .cycles = &[_]u8{8},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "A",
                    .immediate = true,
                },
                .{
                    .name = "n8",
                    .bytes = 1,
                    .immediate = true,
                },
            },
            .flags = .{ .z = 'z', .n = '1', .h = 'h', .c = 'c' },
        },
        0xD7 => Op{
            .mnemonic = "RST",
            .bytes = 1,
            .cycles = &[_]u8{16},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "$10",
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0xD8 => Op{
            .mnemonic = "RET",
            .bytes = 1,
            .cycles = &[_]u8{ 20, 8 },
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "C",
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0xD9 => Op{
            .mnemonic = "RETI",
            .bytes = 1,
            .cycles = &[_]u8{16},
            .immediate = true,
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0xDA => Op{
            .mnemonic = "JP",
            .bytes = 3,
            .cycles = &[_]u8{ 16, 12 },
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "C",
                    .immediate = true,
                },
                .{
                    .name = "a16",
                    .bytes = 2,
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0xDB => Op{
            .mnemonic = "ILLEGAL_DB",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0xDC => Op{
            .mnemonic = "CALL",
            .bytes = 3,
            .cycles = &[_]u8{ 24, 12 },
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "C",
                    .immediate = true,
                },
                .{
                    .name = "a16",
                    .bytes = 2,
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0xDD => Op{
            .mnemonic = "ILLEGAL_DD",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0xDE => Op{
            .mnemonic = "SBC",
            .bytes = 2,
            .cycles = &[_]u8{8},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "A",
                    .immediate = true,
                },
                .{
                    .name = "n8",
                    .bytes = 1,
                    .immediate = true,
                },
            },
            .flags = .{ .z = 'z', .n = '1', .h = 'h', .c = 'c' },
        },
        0xDF => Op{
            .mnemonic = "RST",
            .bytes = 1,
            .cycles = &[_]u8{16},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "$18",
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0xE0 => Op{
            .mnemonic = "LDH",
            .bytes = 2,
            .cycles = &[_]u8{12},
            .immediate = false,
            .operands = &[_]Operand{
                .{
                    .name = "a8",
                    .bytes = 1,
                    .immediate = false,
                },
                .{
                    .name = "A",
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0xE1 => Op{
            .mnemonic = "POP",
            .bytes = 1,
            .cycles = &[_]u8{12},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "HL",
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0xE2 => Op{
            .mnemonic = "LD",
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = false,
            .operands = &[_]Operand{
                .{
                    .name = "C",
                    .immediate = false,
                },
                .{
                    .name = "A",
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0xE3 => Op{
            .mnemonic = "ILLEGAL_E3",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0xE4 => Op{
            .mnemonic = "ILLEGAL_E4",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0xE5 => Op{
            .mnemonic = "PUSH",
            .bytes = 1,
            .cycles = &[_]u8{16},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "HL",
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0xE6 => Op{
            .mnemonic = "AND",
            .bytes = 2,
            .cycles = &[_]u8{8},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "A",
                    .immediate = true,
                },
                .{
                    .name = "n8",
                    .bytes = 1,
                    .immediate = true,
                },
            },
            .flags = .{ .z = 'z', .n = '0', .h = '1', .c = '0' },
        },
        0xE7 => Op{
            .mnemonic = "RST",
            .bytes = 1,
            .cycles = &[_]u8{16},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "$20",
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0xE8 => Op{
            .mnemonic = "ADD",
            .bytes = 2,
            .cycles = &[_]u8{16},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "SP",
                    .immediate = true,
                },
                .{
                    .name = "e8",
                    .bytes = 1,
                    .immediate = true,
                },
            },
            .flags = .{ .z = '0', .n = '0', .h = 'h', .c = 'c' },
        },
        0xE9 => Op{
            .mnemonic = "JP",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "HL",
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0xEA => Op{
            .mnemonic = "LD",
            .bytes = 3,
            .cycles = &[_]u8{16},
            .immediate = false,
            .operands = &[_]Operand{
                .{
                    .name = "a16",
                    .bytes = 2,
                    .immediate = false,
                },
                .{
                    .name = "A",
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0xEB => Op{
            .mnemonic = "ILLEGAL_EB",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0xEC => Op{
            .mnemonic = "ILLEGAL_EC",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0xED => Op{
            .mnemonic = "ILLEGAL_ED",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0xEE => Op{
            .mnemonic = "XOR",
            .bytes = 2,
            .cycles = &[_]u8{8},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "A",
                    .immediate = true,
                },
                .{
                    .name = "n8",
                    .bytes = 1,
                    .immediate = true,
                },
            },
            .flags = .{ .z = 'z', .n = '0', .h = '0', .c = '0' },
        },
        0xEF => Op{
            .mnemonic = "RST",
            .bytes = 1,
            .cycles = &[_]u8{16},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "$28",
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0xF0 => Op{
            .mnemonic = "LDH",
            .bytes = 2,
            .cycles = &[_]u8{12},
            .immediate = false,
            .operands = &[_]Operand{
                .{
                    .name = "A",
                    .immediate = true,
                },
                .{
                    .name = "a8",
                    .bytes = 1,
                    .immediate = false,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0xF1 => Op{
            .mnemonic = "POP",
            .bytes = 1,
            .cycles = &[_]u8{12},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "AF",
                    .immediate = true,
                },
            },
            .flags = .{ .z = 'z', .n = 'n', .h = 'h', .c = 'c' },
        },
        0xF2 => Op{
            .mnemonic = "LD",
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = false,
            .operands = &[_]Operand{
                .{
                    .name = "A",
                    .immediate = true,
                },
                .{
                    .name = "C",
                    .immediate = false,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0xF3 => Op{
            .mnemonic = "DI",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0xF4 => Op{
            .mnemonic = "ILLEGAL_F4",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0xF5 => Op{
            .mnemonic = "PUSH",
            .bytes = 1,
            .cycles = &[_]u8{16},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "AF",
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0xF6 => Op{
            .mnemonic = "OR",
            .bytes = 2,
            .cycles = &[_]u8{8},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "A",
                    .immediate = true,
                },
                .{
                    .name = "n8",
                    .bytes = 1,
                    .immediate = true,
                },
            },
            .flags = .{ .z = 'z', .n = '0', .h = '0', .c = '0' },
        },
        0xF7 => Op{
            .mnemonic = "RST",
            .bytes = 1,
            .cycles = &[_]u8{16},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "$30",
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0xF8 => Op{
            .mnemonic = "LD",
            .bytes = 2,
            .cycles = &[_]u8{12},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "HL",
                    .immediate = true,
                },
                .{
                    .name = "SP",
                    .immediate = true,
                },
                .{
                    .name = "e8",
                    .bytes = 1,
                    .immediate = true,
                },
            },
            .flags = .{ .z = '0', .n = '0', .h = 'h', .c = 'c' },
        },
        0xF9 => Op{
            .mnemonic = "LD",
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "SP",
                    .immediate = true,
                },
                .{
                    .name = "HL",
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0xFA => Op{
            .mnemonic = "LD",
            .bytes = 3,
            .cycles = &[_]u8{16},
            .immediate = false,
            .operands = &[_]Operand{
                .{
                    .name = "A",
                    .immediate = true,
                },
                .{
                    .name = "a16",
                    .bytes = 2,
                    .immediate = false,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0xFB => Op{
            .mnemonic = "EI",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0xFC => Op{
            .mnemonic = "ILLEGAL_FC",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0xFD => Op{
            .mnemonic = "ILLEGAL_FD",
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
        0xFE => Op{
            .mnemonic = "CP",
            .bytes = 2,
            .cycles = &[_]u8{8},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "A",
                    .immediate = true,
                },
                .{
                    .name = "n8",
                    .bytes = 1,
                    .immediate = true,
                },
            },
            .flags = .{ .z = 'z', .n = '1', .h = 'h', .c = 'c' },
        },
        0xFF => Op{
            .mnemonic = "RST",
            .bytes = 1,
            .cycles = &[_]u8{16},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = "$38",
                    .immediate = true,
                },
            },
            .flags = .{ .z = '-', .n = '-', .h = '-', .c = '-' },
        },
    };
}

const Register = struct {
    body: u8 = 0,

    fn read(self: *Register) u8 {
        return self.body;
    }

    fn write(self: *Register, value: u8) void {
        self.body = value;
    }
};

const Registers = struct {
    a: Register,
    f: Register,
    b: Register,
    c: Register,
    d: Register,
    e: Register,
    h: Register,
    l: Register,
};

bus: *Bus,
registers: Registers,
pc: u16,
sp: u16,
clock: Clock,
fetch_data: u16,
mem_dest: u16,
curr_opcode: u8,
halted: bool,
stepping: bool,

pub fn step(self: *Cpu) !void {
    const opcode: u8 = self.bus.read(self.pc, 1)[0];
    const op = fetch_op(opcode);
    self.pc += 1;
    std.debug.print("{s}\n", .{op.mnemonic});
    if (op.bytes > 1) {
        const data = self.bus.read(self.pc, op.bytes);
        self.pc += op.bytes;
        std.debug.print("{any}\n", .{data});
    }
    _ = try std.io.getStdIn().reader().readByte();
}

pub fn init(bus: *Bus) Cpu {
    return .{
        .bus = bus,
        .registers = Registers{
            .a = Register{},
            .f = Register{},
            .b = Register{},
            .c = Register{},
            .d = Register{},
            .e = Register{},
            .h = Register{},
            .l = Register{},
        },
        .pc = 0x100,
        .sp = 0,
        .clock = Clock{},
        .fetch_data = 0,
        .mem_dest = 0,
        .curr_opcode = 0,
        .halted = false,
        .stepping = false,
    };
}
