const std = @import("std");
const Allocator = std.mem.Allocator;
const Bus = @import("Bus.zig");
const Timer = @import("Timer.zig");

const Cpu = @This();

const Flags = packed struct {
    const ZERO_FLAG_BYTE_POSITION: u8 = 7;
    const SUBTRACT_FLAG_BYTE_POSITION: u8 = 6;
    const HALF_CARRY_FLAG_BYTE_POSITION: u8 = 5;
    const CARRY_FLAG_BYTE_POSITION: u8 = 4;

    zero: bool,
    subtract: bool,
    half_carry: bool,
    carry: bool,
};

const OperandName = enum {
    @"$00",
    @"$08",
    @"$10",
    @"$18",
    @"$20",
    @"$28",
    @"$30",
    @"$38",
    A,
    AF,
    B,
    BC,
    C,
    D,
    DE,
    E,
    H,
    HL,
    L,
    NC,
    NZ,
    SP,
    Z,
    a16,
    a8,
    e8,
    n16,
    n8,
};

const Operand = struct {
    name: OperandName,
    immediate: bool,
    bytes: u8 = 0,
};

const OpMnemonic = enum {
    ADC,
    ADD,
    AND,
    CALL,
    CCF,
    CP,
    CPL,
    DAA,
    DEC,
    DI,
    EI,
    HALT,
    ILLEGAL_D3,
    ILLEGAL_DB,
    ILLEGAL_DD,
    ILLEGAL_E3,
    ILLEGAL_E4,
    ILLEGAL_EB,
    ILLEGAL_EC,
    ILLEGAL_ED,
    ILLEGAL_F4,
    ILLEGAL_FC,
    ILLEGAL_FD,
    INC,
    JP,
    JR,
    LD,
    LDH,
    NOP,
    OR,
    POP,
    PREFIX,
    PUSH,
    RET,
    RETI,
    RLA,
    RLCA,
    RRA,
    RRCA,
    RST,
    SBC,
    SCF,
    STOP,
    SUB,
    XOR,
};

const Op = struct {
    mnemonic: OpMnemonic,
    bytes: u8,
    cycles: []const u8,
    operands: []const Operand = &[_]Operand{},
    immediate: bool,
};

fn fetch_opcode(opcode: u8) Op {
    return switch (opcode) {
        0x00 => Op{
            .mnemonic = .NOP,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x01 => Op{
            .mnemonic = .LD,
            .bytes = 3,
            .cycles = &[_]u8{12},
            .immediate = true,
        },
        0x02 => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = false,
        },
        0x03 => Op{
            .mnemonic = .INC,
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = true,
        },
        0x04 => Op{
            .mnemonic = .INC,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x05 => Op{
            .mnemonic = .DEC,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x06 => Op{
            .mnemonic = .LD,
            .bytes = 2,
            .cycles = &[_]u8{8},
            .immediate = true,
        },
        0x07 => Op{
            .mnemonic = .RLCA,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x08 => Op{
            .mnemonic = .LD,
            .bytes = 3,
            .cycles = &[_]u8{20},
            .immediate = false,
        },
        0x09 => Op{
            .mnemonic = .ADD,
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = true,
        },
        0x0A => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = false,
        },
        0x0B => Op{
            .mnemonic = .DEC,
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = true,
        },
        0x0C => Op{
            .mnemonic = .INC,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x0D => Op{
            .mnemonic = .DEC,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x0E => Op{
            .mnemonic = .LD,
            .bytes = 2,
            .cycles = &[_]u8{8},
            .immediate = true,
        },
        0x0F => Op{
            .mnemonic = .RRCA,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x10 => Op{
            .mnemonic = .STOP,
            .bytes = 2,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x11 => Op{
            .mnemonic = .LD,
            .bytes = 3,
            .cycles = &[_]u8{12},
            .immediate = true,
        },
        0x12 => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = false,
        },
        0x13 => Op{
            .mnemonic = .INC,
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = true,
        },
        0x14 => Op{
            .mnemonic = .INC,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x15 => Op{
            .mnemonic = .DEC,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x16 => Op{
            .mnemonic = .LD,
            .bytes = 2,
            .cycles = &[_]u8{8},
            .immediate = true,
        },
        0x17 => Op{
            .mnemonic = .RLA,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x18 => Op{
            .mnemonic = .JR,
            .bytes = 2,
            .cycles = &[_]u8{12},
            .immediate = true,
        },
        0x19 => Op{
            .mnemonic = .ADD,
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = true,
        },
        0x1A => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = false,
        },
        0x1B => Op{
            .mnemonic = .DEC,
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = true,
        },
        0x1C => Op{
            .mnemonic = .INC,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x1D => Op{
            .mnemonic = .DEC,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x1E => Op{
            .mnemonic = .LD,
            .bytes = 2,
            .cycles = &[_]u8{8},
            .immediate = true,
        },
        0x1F => Op{
            .mnemonic = .RRA,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x20 => Op{
            .mnemonic = .JR,
            .bytes = 2,
            .cycles = &[_]u8{ 12, 8 },
            .immediate = true,
        },
        0x21 => Op{
            .mnemonic = .LD,
            .bytes = 3,
            .cycles = &[_]u8{12},
            .immediate = true,
        },
        0x22 => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = false,
        },
        0x23 => Op{
            .mnemonic = .INC,
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = true,
        },
        0x24 => Op{
            .mnemonic = .INC,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x25 => Op{
            .mnemonic = .DEC,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x26 => Op{
            .mnemonic = .LD,
            .bytes = 2,
            .cycles = &[_]u8{8},
            .immediate = true,
        },
        0x27 => Op{
            .mnemonic = .DAA,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x28 => Op{
            .mnemonic = .JR,
            .bytes = 2,
            .cycles = &[_]u8{ 12, 8 },
            .immediate = true,
        },
        0x29 => Op{
            .mnemonic = .ADD,
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = true,
        },
        0x2A => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = false,
        },
        0x2B => Op{
            .mnemonic = .DEC,
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = true,
        },
        0x2C => Op{
            .mnemonic = .INC,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x2D => Op{
            .mnemonic = .DEC,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x2E => Op{
            .mnemonic = .LD,
            .bytes = 2,
            .cycles = &[_]u8{8},
            .immediate = true,
        },
        0x2F => Op{
            .mnemonic = .CPL,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x30 => Op{
            .mnemonic = .JR,
            .bytes = 2,
            .cycles = &[_]u8{ 12, 8 },
            .immediate = true,
        },
        0x31 => Op{
            .mnemonic = .LD,
            .bytes = 3,
            .cycles = &[_]u8{12},
            .immediate = true,
        },
        0x32 => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = false,
        },
        0x33 => Op{
            .mnemonic = .INC,
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = true,
        },
        0x34 => Op{
            .mnemonic = .INC,
            .bytes = 1,
            .cycles = &[_]u8{12},
            .immediate = false,
        },
        0x35 => Op{
            .mnemonic = .DEC,
            .bytes = 1,
            .cycles = &[_]u8{12},
            .immediate = false,
        },
        0x36 => Op{
            .mnemonic = .LD,
            .bytes = 2,
            .cycles = &[_]u8{12},
            .immediate = false,
        },
        0x37 => Op{
            .mnemonic = .SCF,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x38 => Op{
            .mnemonic = .JR,
            .bytes = 2,
            .cycles = &[_]u8{ 12, 8 },
            .immediate = true,
        },
        0x39 => Op{
            .mnemonic = .ADD,
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = true,
        },
        0x3A => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = false,
        },
        0x3B => Op{
            .mnemonic = .DEC,
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = true,
        },
        0x3C => Op{
            .mnemonic = .INC,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x3D => Op{
            .mnemonic = .DEC,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x3E => Op{
            .mnemonic = .LD,
            .bytes = 2,
            .cycles = &[_]u8{8},
            .immediate = true,
        },
        0x3F => Op{
            .mnemonic = .CCF,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x40 => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x41 => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x42 => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x43 => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x44 => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x45 => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x46 => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = false,
        },
        0x47 => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x48 => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x49 => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x4A => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x4B => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x4C => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x4D => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x4E => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = false,
        },
        0x4F => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x50 => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x51 => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x52 => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x53 => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x54 => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x55 => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x56 => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = false,
        },
        0x57 => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x58 => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x59 => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x5A => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x5B => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x5C => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x5D => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x5E => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = false,
        },
        0x5F => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x60 => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x61 => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x62 => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x63 => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x64 => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x65 => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x66 => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = false,
        },
        0x67 => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x68 => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x69 => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x6A => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x6B => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x6C => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x6D => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x6E => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = false,
        },
        0x6F => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x70 => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = false,
        },
        0x71 => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = false,
        },
        0x72 => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = false,
        },
        0x73 => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = false,
        },
        0x74 => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = false,
        },
        0x75 => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = false,
        },
        0x76 => Op{
            .mnemonic = .HALT,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x77 => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = false,
        },
        0x78 => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x79 => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x7A => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x7B => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x7C => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x7D => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x7E => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = false,
        },
        0x7F => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x80 => Op{
            .mnemonic = .ADD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x81 => Op{
            .mnemonic = .ADD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x82 => Op{
            .mnemonic = .ADD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x83 => Op{
            .mnemonic = .ADD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x84 => Op{
            .mnemonic = .ADD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x85 => Op{
            .mnemonic = .ADD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x86 => Op{
            .mnemonic = .ADD,
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = false,
        },
        0x87 => Op{
            .mnemonic = .ADD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x88 => Op{
            .mnemonic = .ADC,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x89 => Op{
            .mnemonic = .ADC,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x8A => Op{
            .mnemonic = .ADC,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x8B => Op{
            .mnemonic = .ADC,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x8C => Op{
            .mnemonic = .ADC,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x8D => Op{
            .mnemonic = .ADC,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x8E => Op{
            .mnemonic = .ADC,
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = false,
        },
        0x8F => Op{
            .mnemonic = .ADC,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x90 => Op{
            .mnemonic = .SUB,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x91 => Op{
            .mnemonic = .SUB,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x92 => Op{
            .mnemonic = .SUB,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x93 => Op{
            .mnemonic = .SUB,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x94 => Op{
            .mnemonic = .SUB,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x95 => Op{
            .mnemonic = .SUB,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x96 => Op{
            .mnemonic = .SUB,
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = false,
        },
        0x97 => Op{
            .mnemonic = .SUB,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x98 => Op{
            .mnemonic = .SBC,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x99 => Op{
            .mnemonic = .SBC,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x9A => Op{
            .mnemonic = .SBC,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x9B => Op{
            .mnemonic = .SBC,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x9C => Op{
            .mnemonic = .SBC,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x9D => Op{
            .mnemonic = .SBC,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0x9E => Op{
            .mnemonic = .SBC,
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = false,
        },
        0x9F => Op{
            .mnemonic = .SBC,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0xA0 => Op{
            .mnemonic = .AND,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0xA1 => Op{
            .mnemonic = .AND,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0xA2 => Op{
            .mnemonic = .AND,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0xA3 => Op{
            .mnemonic = .AND,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0xA4 => Op{
            .mnemonic = .AND,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0xA5 => Op{
            .mnemonic = .AND,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0xA6 => Op{
            .mnemonic = .AND,
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = false,
        },
        0xA7 => Op{
            .mnemonic = .AND,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0xA8 => Op{
            .mnemonic = .XOR,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0xA9 => Op{
            .mnemonic = .XOR,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0xAA => Op{
            .mnemonic = .XOR,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0xAB => Op{
            .mnemonic = .XOR,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0xAC => Op{
            .mnemonic = .XOR,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0xAD => Op{
            .mnemonic = .XOR,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0xAE => Op{
            .mnemonic = .XOR,
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = false,
        },
        0xAF => Op{
            .mnemonic = .XOR,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0xB0 => Op{
            .mnemonic = .OR,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0xB1 => Op{
            .mnemonic = .OR,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0xB2 => Op{
            .mnemonic = .OR,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0xB3 => Op{
            .mnemonic = .OR,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0xB4 => Op{
            .mnemonic = .OR,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0xB5 => Op{
            .mnemonic = .OR,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0xB6 => Op{
            .mnemonic = .OR,
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = false,
        },
        0xB7 => Op{
            .mnemonic = .OR,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0xB8 => Op{
            .mnemonic = .CP,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0xB9 => Op{
            .mnemonic = .CP,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0xBA => Op{
            .mnemonic = .CP,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0xBB => Op{
            .mnemonic = .CP,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0xBC => Op{
            .mnemonic = .CP,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0xBD => Op{
            .mnemonic = .CP,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0xBE => Op{
            .mnemonic = .CP,
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = false,
        },
        0xBF => Op{
            .mnemonic = .CP,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0xC0 => Op{
            .mnemonic = .RET,
            .bytes = 1,
            .cycles = &[_]u8{ 20, 8 },
            .immediate = true,
        },
        0xC1 => Op{
            .mnemonic = .POP,
            .bytes = 1,
            .cycles = &[_]u8{12},
            .immediate = true,
        },
        0xC2 => Op{
            .mnemonic = .JP,
            .bytes = 3,
            .cycles = &[_]u8{ 16, 12 },
            .immediate = true,
        },
        0xC3 => Op{
            .mnemonic = .JP,
            .bytes = 3,
            .cycles = &[_]u8{16},
            .immediate = true,
        },
        0xC4 => Op{
            .mnemonic = .CALL,
            .bytes = 3,
            .cycles = &[_]u8{ 24, 12 },
            .immediate = true,
        },
        0xC5 => Op{
            .mnemonic = .PUSH,
            .bytes = 1,
            .cycles = &[_]u8{16},
            .immediate = true,
        },
        0xC6 => Op{
            .mnemonic = .ADD,
            .bytes = 2,
            .cycles = &[_]u8{8},
            .immediate = true,
        },
        0xC7 => Op{
            .mnemonic = .RST,
            .bytes = 1,
            .cycles = &[_]u8{16},
            .immediate = true,
        },
        0xC8 => Op{
            .mnemonic = .RET,
            .bytes = 1,
            .cycles = &[_]u8{ 20, 8 },
            .immediate = true,
        },
        0xC9 => Op{
            .mnemonic = .RET,
            .bytes = 1,
            .cycles = &[_]u8{16},
            .immediate = true,
        },
        0xCA => Op{
            .mnemonic = .JP,
            .bytes = 3,
            .cycles = &[_]u8{ 16, 12 },
            .immediate = true,
        },
        0xCB => Op{
            .mnemonic = .PREFIX,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0xCC => Op{
            .mnemonic = .CALL,
            .bytes = 3,
            .cycles = &[_]u8{ 24, 12 },
            .immediate = true,
        },
        0xCD => Op{
            .mnemonic = .CALL,
            .bytes = 3,
            .cycles = &[_]u8{24},
            .immediate = true,
        },
        0xCE => Op{
            .mnemonic = .ADC,
            .bytes = 2,
            .cycles = &[_]u8{8},
            .immediate = true,
        },
        0xCF => Op{
            .mnemonic = .RST,
            .bytes = 1,
            .cycles = &[_]u8{16},
            .immediate = true,
        },
        0xD0 => Op{
            .mnemonic = .RET,
            .bytes = 1,
            .cycles = &[_]u8{ 20, 8 },
            .immediate = true,
        },
        0xD1 => Op{
            .mnemonic = .POP,
            .bytes = 1,
            .cycles = &[_]u8{12},
            .immediate = true,
        },
        0xD2 => Op{
            .mnemonic = .JP,
            .bytes = 3,
            .cycles = &[_]u8{ 16, 12 },
            .immediate = true,
        },
        0xD3 => Op{
            .mnemonic = .ILLEGAL_D3,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0xD4 => Op{
            .mnemonic = .CALL,
            .bytes = 3,
            .cycles = &[_]u8{ 24, 12 },
            .immediate = true,
        },
        0xD5 => Op{
            .mnemonic = .PUSH,
            .bytes = 1,
            .cycles = &[_]u8{16},
            .immediate = true,
        },
        0xD6 => Op{
            .mnemonic = .SUB,
            .bytes = 2,
            .cycles = &[_]u8{8},
            .immediate = true,
        },
        0xD7 => Op{
            .mnemonic = .RST,
            .bytes = 1,
            .cycles = &[_]u8{16},
            .immediate = true,
        },
        0xD8 => Op{
            .mnemonic = .RET,
            .bytes = 1,
            .cycles = &[_]u8{ 20, 8 },
            .immediate = true,
        },
        0xD9 => Op{
            .mnemonic = .RETI,
            .bytes = 1,
            .cycles = &[_]u8{16},
            .immediate = true,
        },
        0xDA => Op{
            .mnemonic = .JP,
            .bytes = 3,
            .cycles = &[_]u8{ 16, 12 },
            .immediate = true,
        },
        0xDB => Op{
            .mnemonic = .ILLEGAL_DB,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0xDC => Op{
            .mnemonic = .CALL,
            .bytes = 3,
            .cycles = &[_]u8{ 24, 12 },
            .immediate = true,
        },
        0xDD => Op{
            .mnemonic = .ILLEGAL_DD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0xDE => Op{
            .mnemonic = .SBC,
            .bytes = 2,
            .cycles = &[_]u8{8},
            .immediate = true,
        },
        0xDF => Op{
            .mnemonic = .RST,
            .bytes = 1,
            .cycles = &[_]u8{16},
            .immediate = true,
        },
        0xE0 => Op{
            .mnemonic = .LDH,
            .bytes = 2,
            .cycles = &[_]u8{12},
            .immediate = false,
        },
        0xE1 => Op{
            .mnemonic = .POP,
            .bytes = 1,
            .cycles = &[_]u8{12},
            .immediate = true,
        },
        0xE2 => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = false,
        },
        0xE3 => Op{
            .mnemonic = .ILLEGAL_E3,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0xE4 => Op{
            .mnemonic = .ILLEGAL_E4,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0xE5 => Op{
            .mnemonic = .PUSH,
            .bytes = 1,
            .cycles = &[_]u8{16},
            .immediate = true,
        },
        0xE6 => Op{
            .mnemonic = .AND,
            .bytes = 2,
            .cycles = &[_]u8{8},
            .immediate = true,
        },
        0xE7 => Op{
            .mnemonic = .RST,
            .bytes = 1,
            .cycles = &[_]u8{16},
            .immediate = true,
        },
        0xE8 => Op{
            .mnemonic = .ADD,
            .bytes = 2,
            .cycles = &[_]u8{16},
            .immediate = true,
        },
        0xE9 => Op{
            .mnemonic = .JP,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0xEA => Op{
            .mnemonic = .LD,
            .bytes = 3,
            .cycles = &[_]u8{16},
            .immediate = false,
        },
        0xEB => Op{
            .mnemonic = .ILLEGAL_EB,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0xEC => Op{
            .mnemonic = .ILLEGAL_EC,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0xED => Op{
            .mnemonic = .ILLEGAL_ED,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0xEE => Op{
            .mnemonic = .XOR,
            .bytes = 2,
            .cycles = &[_]u8{8},
            .immediate = true,
        },
        0xEF => Op{
            .mnemonic = .RST,
            .bytes = 1,
            .cycles = &[_]u8{16},
            .immediate = true,
        },
        0xF0 => Op{
            .mnemonic = .LDH,
            .bytes = 2,
            .cycles = &[_]u8{12},
            .immediate = false,
        },
        0xF1 => Op{
            .mnemonic = .POP,
            .bytes = 1,
            .cycles = &[_]u8{12},
            .immediate = true,
        },
        0xF2 => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = false,
        },
        0xF3 => Op{
            .mnemonic = .DI,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0xF4 => Op{
            .mnemonic = .ILLEGAL_F4,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0xF5 => Op{
            .mnemonic = .PUSH,
            .bytes = 1,
            .cycles = &[_]u8{16},
            .immediate = true,
        },
        0xF6 => Op{
            .mnemonic = .OR,
            .bytes = 2,
            .cycles = &[_]u8{8},
            .immediate = true,
        },
        0xF7 => Op{
            .mnemonic = .RST,
            .bytes = 1,
            .cycles = &[_]u8{16},
            .immediate = true,
        },
        0xF8 => Op{
            .mnemonic = .LD,
            .bytes = 2,
            .cycles = &[_]u8{12},
            .immediate = true,
        },
        0xF9 => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = true,
        },
        0xFA => Op{
            .mnemonic = .LD,
            .bytes = 3,
            .cycles = &[_]u8{16},
            .immediate = false,
        },
        0xFB => Op{
            .mnemonic = .EI,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0xFC => Op{
            .mnemonic = .ILLEGAL_FC,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0xFD => Op{
            .mnemonic = .ILLEGAL_FD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
        },
        0xFE => Op{
            .mnemonic = .CP,
            .bytes = 2,
            .cycles = &[_]u8{8},
            .immediate = true,
        },
        0xFF => Op{
            .mnemonic = .RST,
            .bytes = 1,
            .cycles = &[_]u8{16},
            .immediate = true,
        },
    };
}

const R8Register = enum(u3) {
    b = 0,
    c = 1,
    d = 2,
    e = 3,
    h = 4,
    l = 5,
    f = 6,
    a = 7,
};

bus: *Bus,
timer: Timer,
registers: struct {
    const Self = @This();

    r8: [8]u8,

    /// Set register value
    inline fn set(self: *Self, register_name: R8Register, value: u8) void {
        self.r8[@intFromEnum(register_name)] = value;
    }

    /// Get register value
    inline fn get(self: *const Self, register_name: R8Register) u8 {
        return self.r8[@intFromEnum(register_name)];
    }

    inline fn get_bc(self: *const Self) u16 {
        return two_u8_to_u16(self.get(.b), self.get(.c));
    }

    inline fn set_bc(self: *Self, value: u16) void {
        self.set(.b, @as(u8, @intCast((value & 0xFF00) >> 8)));
        self.set(.c, @as(u8, @intCast(value & 0x00FF)));
    }

    inline fn get_de(self: *const Self) u16 {
        return two_u8_to_u16(self.get(.d), self.get(.e));
    }

    inline fn set_de(self: *Self, value: u16) void {
        self.set(.d, @as(u8, @intCast((value & 0xFF00) >> 8)));
        self.set(.e, @as(u8, @intCast(value & 0x00FF)));
    }

    inline fn get_hl(self: *const Self) u16 {
        return two_u8_to_u16(self.get(.h), self.get(.l));
    }

    inline fn set_hl(self: *Self, value: u16) void {
        self.set(.h, @as(u8, @intCast((value & 0xFF00) >> 8)));
        self.set(.l, @as(u8, @intCast(value & 0x00FF)));
    }

    inline fn get_af(self: *const Self) u16 {
        return two_u8_to_u16(self.get(.a), self.get(.f));
    }

    inline fn set_af(self: *Self, value: u16) void {
        self.set(.a, @as(u8, @intCast((value & 0xFF00) >> 8)));
        self.set(.f, @as(u8, @intCast(value & 0x00FF)));
    }

    fn get_flags(self: *const Self) Flags {
        const f_register = self.get(.f);
        const zero = ((f_register >> Flags.ZERO_FLAG_BYTE_POSITION) & 0b1) != 0;
        const subtract = ((f_register >> Flags.SUBTRACT_FLAG_BYTE_POSITION) & 0b1) != 0;
        const half_carry = ((f_register >> Flags.HALF_CARRY_FLAG_BYTE_POSITION) & 0b1) != 0;
        const carry = ((f_register >> Flags.CARRY_FLAG_BYTE_POSITION) & 0b1) != 0;

        return .{
            .zero = zero,
            .subtract = subtract,
            .half_carry = half_carry,
            .carry = carry,
        };
    }

    fn set_flags(self: *Self, flags: Flags) void {
        var result: u8 = 0;

        result |= @as(u8, (if (flags.zero) 1 else 0)) << Flags.ZERO_FLAG_BYTE_POSITION;
        result |= @as(u8, (if (flags.subtract) 1 else 0)) << Flags.SUBTRACT_FLAG_BYTE_POSITION;
        result |= @as(u8, (if (flags.half_carry) 1 else 0)) << Flags.HALF_CARRY_FLAG_BYTE_POSITION;
        result |= @as(u8, (if (flags.carry) 1 else 0)) << Flags.CARRY_FLAG_BYTE_POSITION;
        self.set(.f, result);
    }
},
cur_opcode: u8,
ime: bool,
halted: bool,
halt_bug_triggered: bool,
ei_executed: bool,
pc: u16,
sp: u16,

inline fn two_u8_to_u16(upper: u8, lower: u8) u16 {
    return (@as(u16, @intCast(upper)) << 8) | @as(u16, lower);
}

inline fn set_timer_interrupt_request_bit(self: *Cpu) void {
    const current_if = self.bus.read(0xFF0F);
    const new_if = current_if | (1 << 2);
    self.bus.write(0xFF0F, new_if);
}

inline fn call(self: *Cpu, address: u16) void {
    self.sp -%= 1;
    self.bus.write(self.sp, @intCast(self.pc >> 8));
    self.sp -%= 1;
    self.bus.write(self.sp, @intCast(self.pc & 0xFF));
    self.pc = address;
}

fn fetch_inst(self: *Cpu) void {
    const opcode: u8 = self.bus.read(self.pc);
    self.pc += 1;
    self.cur_opcode = opcode;
}

fn exec_inst(self: *Cpu) void {
    const opcode = self.cur_opcode;
    const op = fetch_opcode(self.cur_opcode);
    const operants_size = op.bytes - 1;
    var operands: [2]u8 = .{ 0, 0 };
    var condition_is_met: bool = false;
    var flags: Flags = self.registers.get_flags();

    if (operants_size > 0) {
        var i: u16 = 0;
        while (i < operants_size) : (i += 1) {
            operands[i] = self.bus.read(self.pc + i);
        }
        self.pc += operants_size;
    }

    std.log.debug(
        \\
        \\[!] Instruction
        \\0x{X:0>2} 0o{o:0>3}
        \\name {s}
        \\size {}
        \\operands u8  0x{X:0>2} {d}
        \\operands u16 0x{X:0>4} {d}
        \\
    , .{
        opcode,
        opcode,
        @tagName(op.mnemonic),
        op.bytes,
        operands,
        operands,
        two_u8_to_u16(operands[1], operands[0]),
        two_u8_to_u16(operands[1], operands[0]),
    });

    switch (op.mnemonic) {
        .CALL => {
            const address = two_u8_to_u16(operands[1], operands[0]);
            const is_conditional: bool = opcode & 7 == 4;
            if (is_conditional) {
                condition_is_met = switch (opcode) {
                    0o304 => flags.zero == false,
                    0o314 => flags.zero == true,
                    0o324 => flags.carry == false,
                    0o334 => flags.carry == true,
                    else => unreachable,
                };
                if (condition_is_met) {
                    self.call(address);
                }
            } else {
                self.call(address);
            }
        },
        .DAA => {
            const a = self.registers.get(.a);
            if (!flags.subtract) {
                var result = a;
                if (flags.half_carry or (a & 0xF) > 9) {
                    result +%= 0x06;
                }
                if (flags.carry or a > 0x99) {
                    result +%= 0x60;
                    flags.carry = true;
                }
                self.registers.set(.a, result);
            } else {
                var result = a;
                if (flags.half_carry) {
                    result -%= 0x06;
                }
                if (flags.carry) {
                    result -%= 0x60;
                }
                self.registers.set(.a, result);
            }

            flags.zero = self.registers.get(.a) == 0;
            flags.half_carry = false;
        },
        .CPL => {
            const a = ~self.registers.get(.a);
            self.registers.set(.a, a);
            flags.subtract = true;
            flags.half_carry = true;
        },
        .DI => {
            self.ime = false;
        },
        .EI => {
            self.ei_executed = true;
        },
        .JP => {
            const address: u16 = switch (opcode) {
                0o351 => self.registers.get_hl(),
                else => two_u8_to_u16(operands[1], operands[0]),
            };
            const is_conditional: bool = opcode & 7 == 2;
            if (is_conditional) {
                condition_is_met = switch (opcode) {
                    0o302 => flags.zero == false,
                    0o312 => flags.zero == true,
                    0o322 => flags.carry == false,
                    0o332 => flags.carry == true,
                    else => unreachable,
                };
                if (condition_is_met) {
                    self.pc = address;
                }
            } else {
                self.pc = address;
            }
        },
        .JR => {
            const offset: i8 = @bitCast(operands[0]);
            const address: u16 = self.pc +% @as(u16, @bitCast(@as(i16, @intCast(offset))));
            const is_conditional: bool = opcode >> 3 & 7 != 3;
            if (is_conditional) {
                condition_is_met = switch (opcode) {
                    0o040 => flags.zero == false,
                    0o050 => flags.zero == true,
                    0o060 => flags.carry == false,
                    0o070 => flags.carry == true,
                    else => unreachable,
                };
                if (condition_is_met) {
                    self.pc = address;
                }
            } else {
                self.pc = address;
            }
        },
        .RETI => {
            const low_byte = self.bus.read(self.sp);
            const high_byte = self.bus.read(self.sp +% 1);
            const return_addr = (@as(u16, high_byte) << 8) | low_byte;

            self.sp +%= 2;
            self.pc = return_addr;
            self.ime = true;
        },
        .RET => {
            const is_conditional: bool = opcode & 7 == 0;

            if (is_conditional) {
                condition_is_met = switch (opcode) {
                    0o300 => flags.zero == false,
                    0o310 => flags.zero == true,
                    0o320 => flags.carry == false,
                    0o330 => flags.carry == true,
                    else => unreachable,
                };

                if (condition_is_met) {
                    const low_byte = self.bus.read(self.sp);
                    const high_byte = self.bus.read(self.sp +% 1);
                    const return_addr = (@as(u16, high_byte) << 8) | low_byte;

                    self.sp +%= 2;
                    self.pc = return_addr;
                }
            } else {
                const low_byte = self.bus.read(self.sp);
                const high_byte = self.bus.read(self.sp +% 1);
                const return_addr = (@as(u16, high_byte) << 8) | low_byte;

                self.sp +%= 2;
                self.pc = return_addr;
            }
        },
        .PUSH => {
            const value = switch (opcode) {
                0o305 => self.registers.get_bc(),
                0o325 => self.registers.get_de(),
                0o345 => self.registers.get_hl(),
                0o365 => self.registers.get_af(),
                else => unreachable,
            };
            self.bus.write(self.sp -% 1, @intCast(value >> 8));
            self.bus.write(self.sp -% 2, @intCast(value & 0xFF));
            self.sp -%= 2;
        },
        .POP => {
            const low_byte = self.bus.read(self.sp);
            const high_byte = self.bus.read(self.sp +% 1);
            const value = (@as(u16, high_byte) << 8) | low_byte;

            switch (opcode) {
                0o301 => self.registers.set_bc(value),
                0o321 => self.registers.set_de(value),
                0o341 => self.registers.set_hl(value),
                0o361 => self.registers.set_af(value),
                else => unreachable,
            }
            self.sp +%= 2;
            if (opcode == 0o361) {
                flags.zero = (low_byte & (1 << 7)) != 0;
                flags.subtract = (low_byte & (1 << 6)) != 0;
                flags.half_carry = (low_byte & (1 << 5)) != 0;
                flags.carry = (low_byte & (1 << 4)) != 0;
            }
        },
        .LD => {
            switch (opcode) {
                0o100...0o105,
                0o107, // LD B, r8
                0o110...0o115,
                0o117, // LD C, r8
                0o120...0o125,
                0o127, // LD D, r8
                0o130...0o135,
                0o137, // LD E, r8
                0o140...0o145,
                0o147, // LD H, r8
                0o150...0o155,
                0o157, // LD L, r8
                0o170...0o175,
                0o177, // LD A, r8
                => {
                    const src: R8Register = @enumFromInt(opcode & 7);
                    const dst: R8Register = @enumFromInt(opcode >> 3 & 7);
                    self.registers.set(dst, self.registers.get(src));
                },
                0o160...0o167, // LD [HL], r8
                => {
                    const src: R8Register = @enumFromInt(opcode & 7);
                    const address = self.registers.get_hl();
                    self.bus.write(address, (self.registers.get(src)));
                },
                0o106,
                0o116,
                0o126,
                0o136,
                0o146,
                0o156,
                0o176, // LD r8, [HL]
                => {
                    const dst: R8Register = @enumFromInt(opcode >> 3 & 7);
                    self.registers.set(dst, self.bus.read(self.registers.get_hl()));
                },
                0o006,
                0o016,
                0o026,
                0o036,
                0o046,
                0o056,
                0o076, // LD r8, n8
                => {
                    const dst: R8Register = @enumFromInt(opcode >> 3 & 7);
                    const value: u8 = operands[0];
                    self.registers.set(dst, value);
                },
                0o066, // LD [HL], n8
                => {
                    const value: u8 = operands[0];
                    self.bus.write(self.bus.read(self.registers.get_hl()), value);
                },
                0o001, // LD r16, n16
                => {
                    const value: u16 = two_u8_to_u16(operands[1], operands[0]);
                    self.registers.set_bc(value);
                },
                0o021, // LD r16, n16
                => {
                    const value: u16 = two_u8_to_u16(operands[1], operands[0]);
                    self.registers.set_de(value);
                },
                0o041, // LD r16, n16
                => {
                    const value: u16 = two_u8_to_u16(operands[1], operands[0]);
                    self.registers.set_hl(value);
                },
                0o061, // LD r16, n16
                => {
                    const value: u16 = two_u8_to_u16(operands[1], operands[0]);
                    self.sp = value;
                },
                0o002 => {
                    const value: u8 = self.registers.get(.a);
                    const address: u16 = self.registers.get_bc();
                    self.bus.write(address, value);
                },
                0o012 => {
                    const value: u8 = self.bus.read(self.registers.get_bc());
                    self.registers.set(.a, value);
                },
                0o022 => {
                    const value: u8 = self.registers.get(.a);
                    const address: u16 = self.registers.get_de();
                    self.bus.write(address, value);
                },
                0o032 => {
                    const value: u8 = self.bus.read(self.registers.get_de());
                    self.registers.set(.a, value);
                },
                0o042 => {
                    const value: u8 = self.registers.get(.a);
                    const address: u16 = self.registers.get_hl();
                    self.registers.set_hl(self.registers.get_hl() + 1);
                    self.bus.write(address, value);
                },
                0o052 => {
                    const value: u8 = self.bus.read(self.registers.get_hl());
                    self.registers.set_hl(self.registers.get_hl() + 1);
                    self.registers.set(.a, value);
                },
                0o062 => {
                    const value: u8 = self.registers.get(.a);
                    const address: u16 = self.registers.get_hl();
                    self.registers.set_hl(self.registers.get_hl() - 1);
                    self.bus.write(address, value);
                },
                0o072 => {
                    const value: u8 = self.bus.read(self.registers.get_hl());
                    self.registers.set_hl(self.registers.get_hl() - 1);
                    self.registers.set(.a, value);
                },
                0o342 => {
                    const address: u16 = 0xFF00 + @as(u16, @intCast(self.registers.get(.c)));
                    self.bus.write(address, self.registers.get(.a));
                },
                0o352 => {
                    const address: u16 = two_u8_to_u16(operands[1], operands[0]);
                    self.bus.write(address, self.registers.get(.a));
                },
                0o362 => {
                    const address: u16 = 0xFF00 + @as(u16, @intCast(self.registers.get(.c)));
                    self.registers.set(.a, self.bus.read(address));
                },
                0o370 => {
                    const offset: i8 = @bitCast(operands[0]);
                    const value: u16 = self.sp +% @as(u16, @bitCast(@as(i16, offset)));
                    const unsigned_offset: u8 = @bitCast(offset);
                    self.registers.set_hl(value);
                    flags.zero = false;
                    flags.subtract = false;
                    flags.half_carry = ((self.sp & 0xF) + (unsigned_offset & 0xF)) > 0xF;
                    flags.carry = (self.sp & 0xFF) + unsigned_offset > 0xFF;
                },
                0o372 => {
                    const address: u16 = two_u8_to_u16(operands[1], operands[0]);
                    const value = self.bus.read(address);
                    self.registers.set(.a, value);
                },
                0o010 => {
                    const lower: u8 = @truncate(self.sp);
                    const upper: u8 = @truncate(self.sp >> 8);
                    const address: u16 = two_u8_to_u16(operands[1], operands[0]);
                    self.bus.write(address, lower);
                    self.bus.write(address + 1, upper);
                },
                0o371 => {
                    self.sp = self.registers.get_hl();
                },
                else => unreachable,
            }
        },
        .RST => {
            const value: u16 = (opcode >> 3 & 7) * 8;
            self.call(value);
        },
        .HALT => {
            const ie = self.bus.read(0xFFFF);
            const @"if" = self.bus.read(0xFF0F);
            const pending = ie & @"if";

            if (pending != 0) {
                if (!self.ime) {
                    self.halt_bug_triggered = true;
                }
            } else {
                self.halted = true;
            }
        },
        .INC => {
            switch (opcode) {
                0o004,
                0o014,
                0o024,
                0o034,
                0o044,
                0o054,
                0o074, // INC r8
                => {
                    const reg: u8 = (opcode >> 3 & 7);
                    const value: u8 = self.registers.get(@as(R8Register, @enumFromInt(reg)));
                    const inc = value +% 1;
                    flags.zero = inc == 0;
                    flags.subtract = false;
                    flags.half_carry = (value & 0xF) == 0xF;
                    self.registers.set(@as(R8Register, @enumFromInt(reg)), inc);
                },
                0o064,
                // INC, [HL]
                => {
                    const address = self.registers.get_hl();
                    const value: u8 = self.bus.read(address);
                    const inc = value +% 1;
                    self.bus.write(address, inc);
                    flags.zero = inc == 0;
                    flags.subtract = false;
                    flags.half_carry = (value & 0xF) == 0xF;
                },
                0o003 => self.registers.set_bc(self.registers.get_bc() +% 1),
                0o023 => self.registers.set_de(self.registers.get_de() +% 1),
                0o043 => self.registers.set_hl(self.registers.get_hl() +% 1),
                0o063 => self.sp +%= 1,
                else => unreachable,
            }
        },
        .DEC => {
            switch (opcode) {
                0o005,
                0o015,
                0o025,
                0o035,
                0o045,
                0o055,
                0o075, // DEC r8
                => {
                    const reg: u8 = (opcode >> 3 & 7);
                    const value: u8 = self.registers.get(@as(R8Register, @enumFromInt(reg)));
                    const dec = value -% 1;
                    flags.zero = dec == 0;
                    flags.subtract = true;
                    flags.half_carry = (value & 0xF) == 0;
                    self.registers.set(@as(R8Register, @enumFromInt(reg)), dec);
                },
                0o065, // DEC [HL]
                => {
                    const address = self.registers.get_hl();
                    const value: u8 = self.bus.read(address);
                    const dec = value -% 1;
                    self.bus.write(address, dec);
                    flags.zero = dec == 0;
                    flags.subtract = true;
                    flags.half_carry = (value & 0xF) == 0;
                },
                0o013 => self.registers.set_bc(self.registers.get_bc() -% 1),
                0o023 => self.registers.set_de(self.registers.get_de() -% 1),
                0o053 => self.registers.set_hl(self.registers.get_hl() -% 1),
                0o073 => self.sp -%= 1,
                else => unreachable,
            }
        },
        .LDH => {
            const address = @as(u16, @intCast(operands[0])) + 0xFF00;
            switch (opcode) {
                0o340 => {
                    self.bus.write(address, self.registers.get(.a));
                },
                0o360 => {
                    self.registers.set(.a, self.bus.read(address));
                },
                else => unreachable,
            }
        },
        .RRA => {
            const a = self.registers.get(.a);
            const old_carry = flags.carry;
            const new_carry = (a & 0x1) != 0;
            const result = (a >> 1) | (@as(u8, @intFromBool(old_carry)) << 7);
            flags.zero = false;
            flags.subtract = false;
            flags.half_carry = false;
            flags.carry = new_carry;
            self.registers.set(.a, result);
        },
        .RRCA => {
            const a = self.registers.get(.a);
            const new_carry = (a & 0x1) != 0;
            const result = (a >> 1) | (@as(u8, @intFromBool(new_carry)) << 7);
            flags.zero = false;
            flags.subtract = false;
            flags.half_carry = false;
            flags.carry = new_carry;
            self.registers.set(.a, result);
        },
        .RLA => {
            const a = self.registers.get(.a);
            const new_carry = (a & 0x80) != 0;
            const result = (a << 1) | @as(u8, @intFromBool(flags.carry));
            flags.zero = false;
            flags.subtract = false;
            flags.half_carry = false;
            flags.carry = new_carry;
            self.registers.set(.a, result);
        },
        .RLCA => {
            const a = self.registers.get(.a);
            const new_carry = (a & 0x80) != 0;
            const result = (a << 1) | @as(u8, @intFromBool(new_carry));
            flags.zero = false;
            flags.subtract = false;
            flags.half_carry = false;
            flags.carry = new_carry;

            self.registers.set(.a, result);
        },
        .PREFIX => {
            const cb_opcode = self.bus.read(self.pc);
            var result: u8 = undefined;
            self.pc += 1;

            const bit_pos = @as(u3, @intCast((cb_opcode >> 3) & 0x7));
            const reg_idx = @as(u3, @intCast(cb_opcode & 0x7));
            const value = if (reg_idx == 0x6)
                self.bus.read(self.registers.get_hl())
            else
                self.registers.get(@as(R8Register, @enumFromInt(reg_idx)));

            switch (cb_opcode >> 6) {
                0 => {
                    switch ((cb_opcode >> 3) & 0x7) {
                        0 => { // RLC
                            const new_carry = (value & 0x80) != 0;
                            const rlc = (value << 1) | @as(u8, @intFromBool(new_carry));
                            flags.zero = rlc == 0;
                            flags.subtract = false;
                            flags.half_carry = false;
                            flags.carry = new_carry;
                            result = rlc;
                        },
                        1 => { // RRC
                            const new_carry = (value & 0x1) != 0;
                            const rrc = (value >> 1) | (@as(u8, @intFromBool(new_carry)) << 7);
                            flags.zero = rrc == 0;
                            flags.subtract = false;
                            flags.half_carry = false;
                            flags.carry = new_carry;
                            result = rrc;
                        },
                        2 => { // RL
                            const new_carry = (value & 0x80) != 0;
                            const rl = (value << 1) | @as(u8, @intFromBool(flags.carry));
                            flags.zero = rl == 0;
                            flags.subtract = false;
                            flags.half_carry = false;
                            flags.carry = new_carry;
                            result = rl;
                        },
                        3 => { // RR
                            const new_carry = (value & 0x1) != 0;
                            const rr = (value >> 1) | (@as(u8, @intFromBool(flags.carry)) << 7);
                            flags.zero = rr == 0;
                            flags.subtract = false;
                            flags.half_carry = false;
                            flags.carry = new_carry;
                            result = rr;
                        },
                        4 => { // SLA
                            const sla = value << 1;
                            flags.zero = sla == 0;
                            flags.subtract = false;
                            flags.half_carry = false;
                            flags.carry = (value & 0x80) != 0;
                            result = sla;
                        },
                        5 => { // SRA
                            const sra = (value >> 1) | (value & 0x80);
                            flags.zero = sra == 0;
                            flags.subtract = false;
                            flags.half_carry = false;
                            flags.carry = (value & 0x1) != 0;
                            result = sra;
                        },
                        6 => { // SWAP
                            const swap = ((value & 0xF0) >> 4) | ((value & 0x0F) << 4);
                            flags.zero = swap == 0;
                            flags.subtract = false;
                            flags.half_carry = false;
                            flags.carry = false;
                            result = swap;
                        },
                        7 => { // SRL
                            const srl = value >> 1;
                            flags.zero = srl == 0;
                            flags.subtract = false;
                            flags.half_carry = false;
                            flags.carry = (value & 0x1) != 0;
                            result = srl;
                        },
                        else => unreachable,
                    }
                    if (reg_idx == 0x6)
                        self.bus.write(self.registers.get_hl(), result)
                    else
                        self.registers.set(@as(R8Register, @enumFromInt(reg_idx)), result);
                },
                1 => { // BIT
                    flags.zero = (value & (@as(u8, 1) << bit_pos)) == 0;
                    flags.subtract = false;
                    flags.half_carry = true;
                },
                2 => { // RES
                    const res = value & ~(@as(u8, 1) << bit_pos);
                    if (reg_idx == 0x6)
                        self.bus.write(self.registers.get_hl(), res)
                    else
                        self.registers.set(@as(R8Register, @enumFromInt(reg_idx)), res);
                },
                3 => { // SET
                    const set = value | (@as(u8, 1) << bit_pos);
                    if (reg_idx == 0x6)
                        self.bus.write(self.registers.get_hl(), set)
                    else
                        self.registers.set(@as(R8Register, @enumFromInt(reg_idx)), set);
                },
                else => unreachable,
            }
        },
        .NOP => {},
        .CCF => {
            flags.subtract = false;
            flags.half_carry = false;
            flags.carry = !flags.carry;
        },
        .SCF => {
            flags.subtract = false;
            flags.half_carry = false;
            flags.carry = true;
        },
        .ADD => {
            const lower: u8 = opcode & 7;
            const a = self.registers.get(.a);
            switch (opcode) {
                0o200...0o207, 0o306 => {
                    const operand: u8 = switch (lower) {
                        0...5,
                        7, // ADD A, r8
                        => self.registers.get(@as(R8Register, @enumFromInt(lower))),
                        6,
                        => if (opcode >> 6 & 7 == 2)
                            self.bus.read(self.registers.get_hl()) // ADD A, [HL]
                        else
                            operands[0], // ADD A, n8
                        else => unreachable,
                    };
                    const add = a +% operand;
                    self.registers.set(.a, add);
                    flags.zero = add == 0;
                    flags.subtract = false;
                    flags.half_carry = ((a & 0xF) + (operand & 0xF)) > 0xF;
                    flags.carry = (@as(u16, a) + operand) > 0xFF;
                },
                0o011, 0o031, 0o051, 0o071 => {
                    const hl = self.registers.get_hl();
                    const operand = switch (opcode) {
                        0o011 => self.registers.get_bc(),
                        0o031 => self.registers.get_de(),
                        0o051 => self.registers.get_hl(),
                        0o071 => self.sp,
                        else => unreachable,
                    };
                    const add = hl +% operand;
                    self.registers.set_hl(add);
                    flags.subtract = false;
                    flags.half_carry = ((hl & 0xFFF) + (operand & 0xFFF)) > 0xFFF;
                    flags.carry = (@as(u32, hl) + @as(u32, operand)) > 0xFFFF;
                },
                0o350 => {
                    const offset: i8 = @bitCast(operands[0]);
                    const sp: u16 = self.sp;
                    const unsigned_offset: u8 = @bitCast(offset);
                    flags.zero = false;
                    flags.subtract = false;
                    flags.half_carry = ((sp & 0xF) + (unsigned_offset & 0xF)) > 0xF;
                    flags.carry = ((sp & 0xFF) + unsigned_offset) > 0xFF;
                    self.sp +%= @as(u16, @bitCast(@as(i16, offset)));
                },
                else => unreachable,
            }
        },
        .ADC, .SUB, .SBC, .AND, .XOR, .OR, .CP => {
            const a = self.registers.get(.a);
            const lower: u8 = opcode & 7;
            const operand: u8 = switch (lower) {
                0...5,
                7, // OP A, r8
                => self.registers.get(@as(R8Register, @enumFromInt(lower))),
                6,
                => if (opcode >> 6 & 7 == 2)
                    self.bus.read(self.registers.get_hl()) // OP A, [HL]
                else
                    operands[0], // OP A, n8
                else => unreachable,
            };

            switch (op.mnemonic) {
                .ADC,
                => {
                    const adc = a +% operand +% @as(u8, @intFromBool(flags.carry));
                    self.registers.set(.a, adc);
                    flags.zero = adc == 0;
                    flags.subtract = false;
                    flags.half_carry = ((a & 0xF) +% (operand & 0xF) +% @as(u8, @intFromBool(flags.carry))) > 0xF;
                    flags.carry = (@as(u16, a) +% operand +% @as(u16, @intFromBool(flags.carry))) > 0xFF;
                },
                .SUB,
                => {
                    const sub = a -% operand;
                    self.registers.set(.a, sub);
                    flags.zero = sub == 0;
                    flags.subtract = true;
                    flags.half_carry = (a & 0xF) < (operand & 0xF);
                    flags.carry = a < operand;
                },
                .SBC,
                => {
                    const sub = @as(u16, a) -% @as(u16, operand) -% @as(u16, @intFromBool(flags.carry));
                    const result = @as(u8, @truncate(sub));
                    self.registers.set(.a, result);
                    flags.zero = result == 0;
                    flags.subtract = true;
                    flags.half_carry = ((@as(i16, @intCast(a & 0xF)) -% @as(i16, @intCast(operand & 0xF)) -% @as(i16, @intFromBool(flags.carry))) < 0);
                    flags.carry = sub > 0xFF;
                    self.registers.set(.a, result);
                },
                .AND,
                => {
                    const @"and" = a & operand;
                    self.registers.set(.a, @"and");
                    flags.zero = @"and" == 0;
                    flags.subtract = false;
                    flags.half_carry = true;
                    flags.carry = false;
                },
                .XOR,
                => {
                    const xor = a ^ operand;
                    self.registers.set(.a, xor);
                    flags.zero = xor == 0;
                    flags.subtract = false;
                    flags.half_carry = false;
                    flags.carry = false;
                },
                .OR,
                => {
                    const @"or" = a | operand;
                    self.registers.set(.a, @"or");
                    flags.zero = @"or" == 0;
                    flags.subtract = false;
                    flags.half_carry = false;
                    flags.carry = false;
                },
                .CP,
                => {
                    const cp = a -% operand;
                    flags.zero = cp == 0;
                    flags.subtract = true;
                    flags.half_carry = (a & 0xF) < (operand & 0xF);
                    flags.carry = operand > a;
                },
                else => unreachable,
            }
        },
        else => @panic("Operation not implemented"),
    }
    self.registers.set_flags(flags);

    var cycles: u8 = 0;
    if (op.cycles.len > 1) { // Conditional op
        cycles = if (condition_is_met) op.cycles[0] else op.cycles[1];
    } else {
        cycles = op.cycles[0];
    }
    self.timer.run_cycles(cycles);
    if (self.timer.is_timer_interrupt_requested()) {
        self.set_timer_interrupt_request_bit();
    }
}

/// Returns true if an interrupt has been served
inline fn interrupt_handler(self: *Cpu) bool {
    if (self.ime) {
        const ie = self.bus.read(0xFFFF);
        const @"if" = self.bus.read(0xFF0F);
        const pending = ie & @"if";

        if (pending != 0) {
            self.ime = false;
            self.halted = false;

            inline for (0..5) |int_bit| {
                if (pending & (@as(u8, 1) << int_bit) != 0) {
                    const new_if = @"if" & ~(@as(u8, 1) << int_bit);
                    self.bus.write(0xFF0F, new_if);
                    const vector = 0x0040 + (@as(u16, int_bit) << 3);
                    self.call(vector);
                    self.fetch_inst();
                    self.exec_inst();
                    return true;
                }
            }
        }
    }
    return false;
}

fn check_halt(self: *Cpu) void {
    if (self.halted) {
        const ie = self.bus.read(0xFFFF);
        const @"if" = self.bus.read(0xFF0F);
        const pending = ie & @"if";

        if (pending != 0) {
            self.halted = false;
        }
    }
}

pub fn step(self: *Cpu) !void {
    const prev_ei = self.ei_executed;
    self.ei_executed = false;

    const ie = self.bus.read(0xFFFF);
    const @"if" = self.bus.read(0xFF0F);
    const pending = ie & @"if";

    if (self.ime and pending != 0) {
        self.halted = false;
        if (self.interrupt_handler()) {
            return;
        }
    }

    if (self.halted) {
        self.timer.run_cycles(4);
        return;
    }

    self.fetch_inst();
    self.exec_inst();

    if (prev_ei) {
        self.ime = true;
    }
}

pub inline fn print(self: *Cpu) void {
    std.log.debug(
        \\[!] Registers
        \\b  = {}
        \\c  = {}
        \\d  = {}
        \\e  = {}
        \\h  = {}
        \\l  = {}
        \\a  = {}
        \\f  = {b:0>8}
        \\bc = 0x{X:0>4} 
        \\de = 0x{X:0>4} 
        \\hl = 0x{X:0>4} 
        \\af = 0x{X:0>4} 
        \\pc = 0x{X:0>4} 
        \\sp = 0x{X:0>4} 
        \\
    , .{
        self.registers.get(.b),
        self.registers.get(.c),
        self.registers.get(.d),
        self.registers.get(.e),
        self.registers.get(.h),
        self.registers.get(.l),
        self.registers.get(.a),
        self.registers.get(.f),
        self.registers.get_bc(),
        self.registers.get_de(),
        self.registers.get_hl(),
        self.registers.get_af(),
        self.pc,
        self.sp,
    });
}

pub fn log(self: *const Cpu, file: *const std.fs.File) !void {
    try file.writer().print("A:{X:0>2} F:{X:0>2} B:{X:0>2} C:{X:0>2} D:{X:0>2} E:{X:0>2} H:{X:0>2} L:{X:0>2} SP:{X:0>4} PC:{X:0>4} PCMEM:{X:0>2},{X:0>2},{X:0>2},{X:0>2}\n", .{
        self.registers.get(.a),
        self.registers.get(.f),
        self.registers.get(.b),
        self.registers.get(.c),
        self.registers.get(.d),
        self.registers.get(.e),
        self.registers.get(.h),
        self.registers.get(.l),
        self.sp,
        self.pc,
        self.bus.read(self.pc),
        self.bus.read(self.pc + 1),
        self.bus.read(self.pc + 2),
        self.bus.read(self.pc + 3),
    });
}

pub fn init(bus: *Bus) Cpu {
    const timer = Timer.init(bus);

    return .{
        .bus = bus,
        .timer = timer,
        .registers = .{
            .r8 = [_]u8{
                0x00, 0x13, 0x00, 0xD8, 0x01, 0x4D, 0xB0, 0x01,
            },
        },
        .cur_opcode = undefined,
        .ime = false,
        .halted = false,
        .halt_bug_triggered = false,
        .ei_executed = false,
        .pc = 0x0100,
        .sp = 0xFFFE,
    };
}
