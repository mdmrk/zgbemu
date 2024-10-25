const std = @import("std");
const Bus = @import("Bus.zig");

const Cpu = @This();

const Clock = struct {
    m: u16 = 0,
    t: u16 = 0,
};

const Flags = struct {
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
            .operands = &[_]Operand{
                .{
                    .name = .BC,
                    .immediate = true,
                },
                .{
                    .name = .n16,
                    .bytes = 2,
                    .immediate = true,
                },
            },
        },
        0x02 => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = false,
            .operands = &[_]Operand{
                .{
                    .name = .BC,
                    .immediate = false,
                },
                .{
                    .name = .A,
                    .immediate = true,
                },
            },
        },
        0x03 => Op{
            .mnemonic = .INC,
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .BC,
                    .immediate = true,
                },
            },
        },
        0x04 => Op{
            .mnemonic = .INC,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .B,
                    .immediate = true,
                },
            },
        },
        0x05 => Op{
            .mnemonic = .DEC,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .B,
                    .immediate = true,
                },
            },
        },
        0x06 => Op{
            .mnemonic = .LD,
            .bytes = 2,
            .cycles = &[_]u8{8},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .B,
                    .immediate = true,
                },
                .{
                    .name = .n8,
                    .bytes = 1,
                    .immediate = true,
                },
            },
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
            .operands = &[_]Operand{
                .{
                    .name = .a16,
                    .bytes = 2,
                    .immediate = false,
                },
                .{
                    .name = .SP,
                    .immediate = true,
                },
            },
        },
        0x09 => Op{
            .mnemonic = .ADD,
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .HL,
                    .immediate = true,
                },
                .{
                    .name = .BC,
                    .immediate = true,
                },
            },
        },
        0x0A => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = false,
            .operands = &[_]Operand{
                .{
                    .name = .A,
                    .immediate = true,
                },
                .{
                    .name = .BC,
                    .immediate = false,
                },
            },
        },
        0x0B => Op{
            .mnemonic = .DEC,
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .BC,
                    .immediate = true,
                },
            },
        },
        0x0C => Op{
            .mnemonic = .INC,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .C,
                    .immediate = true,
                },
            },
        },
        0x0D => Op{
            .mnemonic = .DEC,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .C,
                    .immediate = true,
                },
            },
        },
        0x0E => Op{
            .mnemonic = .LD,
            .bytes = 2,
            .cycles = &[_]u8{8},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .C,
                    .immediate = true,
                },
                .{
                    .name = .n8,
                    .bytes = 1,
                    .immediate = true,
                },
            },
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
            .operands = &[_]Operand{
                .{
                    .name = .n8,
                    .bytes = 1,
                    .immediate = true,
                },
            },
        },
        0x11 => Op{
            .mnemonic = .LD,
            .bytes = 3,
            .cycles = &[_]u8{12},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .DE,
                    .immediate = true,
                },
                .{
                    .name = .n16,
                    .bytes = 2,
                    .immediate = true,
                },
            },
        },
        0x12 => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = false,
            .operands = &[_]Operand{
                .{
                    .name = .DE,
                    .immediate = false,
                },
                .{
                    .name = .A,
                    .immediate = true,
                },
            },
        },
        0x13 => Op{
            .mnemonic = .INC,
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .DE,
                    .immediate = true,
                },
            },
        },
        0x14 => Op{
            .mnemonic = .INC,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .D,
                    .immediate = true,
                },
            },
        },
        0x15 => Op{
            .mnemonic = .DEC,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .D,
                    .immediate = true,
                },
            },
        },
        0x16 => Op{
            .mnemonic = .LD,
            .bytes = 2,
            .cycles = &[_]u8{8},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .D,
                    .immediate = true,
                },
                .{
                    .name = .n8,
                    .bytes = 1,
                    .immediate = true,
                },
            },
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
            .operands = &[_]Operand{
                .{
                    .name = .e8,
                    .bytes = 1,
                    .immediate = true,
                },
            },
        },
        0x19 => Op{
            .mnemonic = .ADD,
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .HL,
                    .immediate = true,
                },
                .{
                    .name = .DE,
                    .immediate = true,
                },
            },
        },
        0x1A => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = false,
            .operands = &[_]Operand{
                .{
                    .name = .A,
                    .immediate = true,
                },
                .{
                    .name = .DE,
                    .immediate = false,
                },
            },
        },
        0x1B => Op{
            .mnemonic = .DEC,
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .DE,
                    .immediate = true,
                },
            },
        },
        0x1C => Op{
            .mnemonic = .INC,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .E,
                    .immediate = true,
                },
            },
        },
        0x1D => Op{
            .mnemonic = .DEC,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .E,
                    .immediate = true,
                },
            },
        },
        0x1E => Op{
            .mnemonic = .LD,
            .bytes = 2,
            .cycles = &[_]u8{8},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .E,
                    .immediate = true,
                },
                .{
                    .name = .n8,
                    .bytes = 1,
                    .immediate = true,
                },
            },
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
            .operands = &[_]Operand{
                .{
                    .name = .NZ,
                    .immediate = true,
                },
                .{
                    .name = .e8,
                    .bytes = 1,
                    .immediate = true,
                },
            },
        },
        0x21 => Op{
            .mnemonic = .LD,
            .bytes = 3,
            .cycles = &[_]u8{12},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .HL,
                    .immediate = true,
                },
                .{
                    .name = .n16,
                    .bytes = 2,
                    .immediate = true,
                },
            },
        },
        0x22 => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = false,
            .operands = &[_]Operand{
                .{
                    .name = .HL,
                    .immediate = false,
                },
                .{
                    .name = .A,
                    .immediate = true,
                },
            },
        },
        0x23 => Op{
            .mnemonic = .INC,
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .HL,
                    .immediate = true,
                },
            },
        },
        0x24 => Op{
            .mnemonic = .INC,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .H,
                    .immediate = true,
                },
            },
        },
        0x25 => Op{
            .mnemonic = .DEC,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .H,
                    .immediate = true,
                },
            },
        },
        0x26 => Op{
            .mnemonic = .LD,
            .bytes = 2,
            .cycles = &[_]u8{8},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .H,
                    .immediate = true,
                },
                .{
                    .name = .n8,
                    .bytes = 1,
                    .immediate = true,
                },
            },
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
            .operands = &[_]Operand{
                .{
                    .name = .Z,
                    .immediate = true,
                },
                .{
                    .name = .e8,
                    .bytes = 1,
                    .immediate = true,
                },
            },
        },
        0x29 => Op{
            .mnemonic = .ADD,
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .HL,
                    .immediate = true,
                },
                .{
                    .name = .HL,
                    .immediate = true,
                },
            },
        },
        0x2A => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = false,
            .operands = &[_]Operand{
                .{
                    .name = .A,
                    .immediate = true,
                },
                .{
                    .name = .HL,
                    .immediate = false,
                },
            },
        },
        0x2B => Op{
            .mnemonic = .DEC,
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .HL,
                    .immediate = true,
                },
            },
        },
        0x2C => Op{
            .mnemonic = .INC,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .L,
                    .immediate = true,
                },
            },
        },
        0x2D => Op{
            .mnemonic = .DEC,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .L,
                    .immediate = true,
                },
            },
        },
        0x2E => Op{
            .mnemonic = .LD,
            .bytes = 2,
            .cycles = &[_]u8{8},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .L,
                    .immediate = true,
                },
                .{
                    .name = .n8,
                    .bytes = 1,
                    .immediate = true,
                },
            },
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
            .operands = &[_]Operand{
                .{
                    .name = .NC,
                    .immediate = true,
                },
                .{
                    .name = .e8,
                    .bytes = 1,
                    .immediate = true,
                },
            },
        },
        0x31 => Op{
            .mnemonic = .LD,
            .bytes = 3,
            .cycles = &[_]u8{12},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .SP,
                    .immediate = true,
                },
                .{
                    .name = .n16,
                    .bytes = 2,
                    .immediate = true,
                },
            },
        },
        0x32 => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = false,
            .operands = &[_]Operand{
                .{
                    .name = .HL,
                    .immediate = false,
                },
                .{
                    .name = .A,
                    .immediate = true,
                },
            },
        },
        0x33 => Op{
            .mnemonic = .INC,
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .SP,
                    .immediate = true,
                },
            },
        },
        0x34 => Op{
            .mnemonic = .INC,
            .bytes = 1,
            .cycles = &[_]u8{12},
            .immediate = false,
            .operands = &[_]Operand{
                .{
                    .name = .HL,
                    .immediate = false,
                },
            },
        },
        0x35 => Op{
            .mnemonic = .DEC,
            .bytes = 1,
            .cycles = &[_]u8{12},
            .immediate = false,
            .operands = &[_]Operand{
                .{
                    .name = .HL,
                    .immediate = false,
                },
            },
        },
        0x36 => Op{
            .mnemonic = .LD,
            .bytes = 2,
            .cycles = &[_]u8{12},
            .immediate = false,
            .operands = &[_]Operand{
                .{
                    .name = .HL,
                    .immediate = false,
                },
                .{
                    .name = .n8,
                    .bytes = 1,
                    .immediate = true,
                },
            },
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
            .operands = &[_]Operand{
                .{
                    .name = .C,
                    .immediate = true,
                },
                .{
                    .name = .e8,
                    .bytes = 1,
                    .immediate = true,
                },
            },
        },
        0x39 => Op{
            .mnemonic = .ADD,
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .HL,
                    .immediate = true,
                },
                .{
                    .name = .SP,
                    .immediate = true,
                },
            },
        },
        0x3A => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = false,
            .operands = &[_]Operand{
                .{
                    .name = .A,
                    .immediate = true,
                },
                .{
                    .name = .HL,
                    .immediate = false,
                },
            },
        },
        0x3B => Op{
            .mnemonic = .DEC,
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .SP,
                    .immediate = true,
                },
            },
        },
        0x3C => Op{
            .mnemonic = .INC,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .A,
                    .immediate = true,
                },
            },
        },
        0x3D => Op{
            .mnemonic = .DEC,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .A,
                    .immediate = true,
                },
            },
        },
        0x3E => Op{
            .mnemonic = .LD,
            .bytes = 2,
            .cycles = &[_]u8{8},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .A,
                    .immediate = true,
                },
                .{
                    .name = .n8,
                    .bytes = 1,
                    .immediate = true,
                },
            },
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
            .operands = &[_]Operand{
                .{
                    .name = .B,
                    .immediate = true,
                },
                .{
                    .name = .B,
                    .immediate = true,
                },
            },
        },
        0x41 => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .B,
                    .immediate = true,
                },
                .{
                    .name = .C,
                    .immediate = true,
                },
            },
        },
        0x42 => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .B,
                    .immediate = true,
                },
                .{
                    .name = .D,
                    .immediate = true,
                },
            },
        },
        0x43 => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .B,
                    .immediate = true,
                },
                .{
                    .name = .E,
                    .immediate = true,
                },
            },
        },
        0x44 => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .B,
                    .immediate = true,
                },
                .{
                    .name = .H,
                    .immediate = true,
                },
            },
        },
        0x45 => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .B,
                    .immediate = true,
                },
                .{
                    .name = .L,
                    .immediate = true,
                },
            },
        },
        0x46 => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = false,
            .operands = &[_]Operand{
                .{
                    .name = .B,
                    .immediate = true,
                },
                .{
                    .name = .HL,
                    .immediate = false,
                },
            },
        },
        0x47 => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .B,
                    .immediate = true,
                },
                .{
                    .name = .A,
                    .immediate = true,
                },
            },
        },
        0x48 => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .C,
                    .immediate = true,
                },
                .{
                    .name = .B,
                    .immediate = true,
                },
            },
        },
        0x49 => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .C,
                    .immediate = true,
                },
                .{
                    .name = .C,
                    .immediate = true,
                },
            },
        },
        0x4A => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .C,
                    .immediate = true,
                },
                .{
                    .name = .D,
                    .immediate = true,
                },
            },
        },
        0x4B => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .C,
                    .immediate = true,
                },
                .{
                    .name = .E,
                    .immediate = true,
                },
            },
        },
        0x4C => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .C,
                    .immediate = true,
                },
                .{
                    .name = .H,
                    .immediate = true,
                },
            },
        },
        0x4D => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .C,
                    .immediate = true,
                },
                .{
                    .name = .L,
                    .immediate = true,
                },
            },
        },
        0x4E => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = false,
            .operands = &[_]Operand{
                .{
                    .name = .C,
                    .immediate = true,
                },
                .{
                    .name = .HL,
                    .immediate = false,
                },
            },
        },
        0x4F => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .C,
                    .immediate = true,
                },
                .{
                    .name = .A,
                    .immediate = true,
                },
            },
        },
        0x50 => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .D,
                    .immediate = true,
                },
                .{
                    .name = .B,
                    .immediate = true,
                },
            },
        },
        0x51 => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .D,
                    .immediate = true,
                },
                .{
                    .name = .C,
                    .immediate = true,
                },
            },
        },
        0x52 => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .D,
                    .immediate = true,
                },
                .{
                    .name = .D,
                    .immediate = true,
                },
            },
        },
        0x53 => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .D,
                    .immediate = true,
                },
                .{
                    .name = .E,
                    .immediate = true,
                },
            },
        },
        0x54 => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .D,
                    .immediate = true,
                },
                .{
                    .name = .H,
                    .immediate = true,
                },
            },
        },
        0x55 => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .D,
                    .immediate = true,
                },
                .{
                    .name = .L,
                    .immediate = true,
                },
            },
        },
        0x56 => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = false,
            .operands = &[_]Operand{
                .{
                    .name = .D,
                    .immediate = true,
                },
                .{
                    .name = .HL,
                    .immediate = false,
                },
            },
        },
        0x57 => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .D,
                    .immediate = true,
                },
                .{
                    .name = .A,
                    .immediate = true,
                },
            },
        },
        0x58 => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .E,
                    .immediate = true,
                },
                .{
                    .name = .B,
                    .immediate = true,
                },
            },
        },
        0x59 => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .E,
                    .immediate = true,
                },
                .{
                    .name = .C,
                    .immediate = true,
                },
            },
        },
        0x5A => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .E,
                    .immediate = true,
                },
                .{
                    .name = .D,
                    .immediate = true,
                },
            },
        },
        0x5B => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .E,
                    .immediate = true,
                },
                .{
                    .name = .E,
                    .immediate = true,
                },
            },
        },
        0x5C => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .E,
                    .immediate = true,
                },
                .{
                    .name = .H,
                    .immediate = true,
                },
            },
        },
        0x5D => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .E,
                    .immediate = true,
                },
                .{
                    .name = .L,
                    .immediate = true,
                },
            },
        },
        0x5E => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = false,
            .operands = &[_]Operand{
                .{
                    .name = .E,
                    .immediate = true,
                },
                .{
                    .name = .HL,
                    .immediate = false,
                },
            },
        },
        0x5F => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .E,
                    .immediate = true,
                },
                .{
                    .name = .A,
                    .immediate = true,
                },
            },
        },
        0x60 => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .H,
                    .immediate = true,
                },
                .{
                    .name = .B,
                    .immediate = true,
                },
            },
        },
        0x61 => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .H,
                    .immediate = true,
                },
                .{
                    .name = .C,
                    .immediate = true,
                },
            },
        },
        0x62 => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .H,
                    .immediate = true,
                },
                .{
                    .name = .D,
                    .immediate = true,
                },
            },
        },
        0x63 => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .H,
                    .immediate = true,
                },
                .{
                    .name = .E,
                    .immediate = true,
                },
            },
        },
        0x64 => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .H,
                    .immediate = true,
                },
                .{
                    .name = .H,
                    .immediate = true,
                },
            },
        },
        0x65 => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .H,
                    .immediate = true,
                },
                .{
                    .name = .L,
                    .immediate = true,
                },
            },
        },
        0x66 => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = false,
            .operands = &[_]Operand{
                .{
                    .name = .H,
                    .immediate = true,
                },
                .{
                    .name = .HL,
                    .immediate = false,
                },
            },
        },
        0x67 => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .H,
                    .immediate = true,
                },
                .{
                    .name = .A,
                    .immediate = true,
                },
            },
        },
        0x68 => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .L,
                    .immediate = true,
                },
                .{
                    .name = .B,
                    .immediate = true,
                },
            },
        },
        0x69 => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .L,
                    .immediate = true,
                },
                .{
                    .name = .C,
                    .immediate = true,
                },
            },
        },
        0x6A => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .L,
                    .immediate = true,
                },
                .{
                    .name = .D,
                    .immediate = true,
                },
            },
        },
        0x6B => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .L,
                    .immediate = true,
                },
                .{
                    .name = .E,
                    .immediate = true,
                },
            },
        },
        0x6C => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .L,
                    .immediate = true,
                },
                .{
                    .name = .H,
                    .immediate = true,
                },
            },
        },
        0x6D => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .L,
                    .immediate = true,
                },
                .{
                    .name = .L,
                    .immediate = true,
                },
            },
        },
        0x6E => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = false,
            .operands = &[_]Operand{
                .{
                    .name = .L,
                    .immediate = true,
                },
                .{
                    .name = .HL,
                    .immediate = false,
                },
            },
        },
        0x6F => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .L,
                    .immediate = true,
                },
                .{
                    .name = .A,
                    .immediate = true,
                },
            },
        },
        0x70 => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = false,
            .operands = &[_]Operand{
                .{
                    .name = .HL,
                    .immediate = false,
                },
                .{
                    .name = .B,
                    .immediate = true,
                },
            },
        },
        0x71 => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = false,
            .operands = &[_]Operand{
                .{
                    .name = .HL,
                    .immediate = false,
                },
                .{
                    .name = .C,
                    .immediate = true,
                },
            },
        },
        0x72 => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = false,
            .operands = &[_]Operand{
                .{
                    .name = .HL,
                    .immediate = false,
                },
                .{
                    .name = .D,
                    .immediate = true,
                },
            },
        },
        0x73 => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = false,
            .operands = &[_]Operand{
                .{
                    .name = .HL,
                    .immediate = false,
                },
                .{
                    .name = .E,
                    .immediate = true,
                },
            },
        },
        0x74 => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = false,
            .operands = &[_]Operand{
                .{
                    .name = .HL,
                    .immediate = false,
                },
                .{
                    .name = .H,
                    .immediate = true,
                },
            },
        },
        0x75 => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = false,
            .operands = &[_]Operand{
                .{
                    .name = .HL,
                    .immediate = false,
                },
                .{
                    .name = .L,
                    .immediate = true,
                },
            },
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
            .operands = &[_]Operand{
                .{
                    .name = .HL,
                    .immediate = false,
                },
                .{
                    .name = .A,
                    .immediate = true,
                },
            },
        },
        0x78 => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .A,
                    .immediate = true,
                },
                .{
                    .name = .B,
                    .immediate = true,
                },
            },
        },
        0x79 => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .A,
                    .immediate = true,
                },
                .{
                    .name = .C,
                    .immediate = true,
                },
            },
        },
        0x7A => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .A,
                    .immediate = true,
                },
                .{
                    .name = .D,
                    .immediate = true,
                },
            },
        },
        0x7B => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .A,
                    .immediate = true,
                },
                .{
                    .name = .E,
                    .immediate = true,
                },
            },
        },
        0x7C => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .A,
                    .immediate = true,
                },
                .{
                    .name = .H,
                    .immediate = true,
                },
            },
        },
        0x7D => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .A,
                    .immediate = true,
                },
                .{
                    .name = .L,
                    .immediate = true,
                },
            },
        },
        0x7E => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = false,
            .operands = &[_]Operand{
                .{
                    .name = .A,
                    .immediate = true,
                },
                .{
                    .name = .HL,
                    .immediate = false,
                },
            },
        },
        0x7F => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .A,
                    .immediate = true,
                },
                .{
                    .name = .A,
                    .immediate = true,
                },
            },
        },
        0x80 => Op{
            .mnemonic = .ADD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .A,
                    .immediate = true,
                },
                .{
                    .name = .B,
                    .immediate = true,
                },
            },
        },
        0x81 => Op{
            .mnemonic = .ADD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .A,
                    .immediate = true,
                },
                .{
                    .name = .C,
                    .immediate = true,
                },
            },
        },
        0x82 => Op{
            .mnemonic = .ADD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .A,
                    .immediate = true,
                },
                .{
                    .name = .D,
                    .immediate = true,
                },
            },
        },
        0x83 => Op{
            .mnemonic = .ADD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .A,
                    .immediate = true,
                },
                .{
                    .name = .E,
                    .immediate = true,
                },
            },
        },
        0x84 => Op{
            .mnemonic = .ADD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .A,
                    .immediate = true,
                },
                .{
                    .name = .H,
                    .immediate = true,
                },
            },
        },
        0x85 => Op{
            .mnemonic = .ADD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .A,
                    .immediate = true,
                },
                .{
                    .name = .L,
                    .immediate = true,
                },
            },
        },
        0x86 => Op{
            .mnemonic = .ADD,
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = false,
            .operands = &[_]Operand{
                .{
                    .name = .A,
                    .immediate = true,
                },
                .{
                    .name = .HL,
                    .immediate = false,
                },
            },
        },
        0x87 => Op{
            .mnemonic = .ADD,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .A,
                    .immediate = true,
                },
                .{
                    .name = .A,
                    .immediate = true,
                },
            },
        },
        0x88 => Op{
            .mnemonic = .ADC,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .A,
                    .immediate = true,
                },
                .{
                    .name = .B,
                    .immediate = true,
                },
            },
        },
        0x89 => Op{
            .mnemonic = .ADC,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .A,
                    .immediate = true,
                },
                .{
                    .name = .C,
                    .immediate = true,
                },
            },
        },
        0x8A => Op{
            .mnemonic = .ADC,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .A,
                    .immediate = true,
                },
                .{
                    .name = .D,
                    .immediate = true,
                },
            },
        },
        0x8B => Op{
            .mnemonic = .ADC,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .A,
                    .immediate = true,
                },
                .{
                    .name = .E,
                    .immediate = true,
                },
            },
        },
        0x8C => Op{
            .mnemonic = .ADC,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .A,
                    .immediate = true,
                },
                .{
                    .name = .H,
                    .immediate = true,
                },
            },
        },
        0x8D => Op{
            .mnemonic = .ADC,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .A,
                    .immediate = true,
                },
                .{
                    .name = .L,
                    .immediate = true,
                },
            },
        },
        0x8E => Op{
            .mnemonic = .ADC,
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = false,
            .operands = &[_]Operand{
                .{
                    .name = .A,
                    .immediate = true,
                },
                .{
                    .name = .HL,
                    .immediate = false,
                },
            },
        },
        0x8F => Op{
            .mnemonic = .ADC,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .A,
                    .immediate = true,
                },
                .{
                    .name = .A,
                    .immediate = true,
                },
            },
        },
        0x90 => Op{
            .mnemonic = .SUB,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .A,
                    .immediate = true,
                },
                .{
                    .name = .B,
                    .immediate = true,
                },
            },
        },
        0x91 => Op{
            .mnemonic = .SUB,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .A,
                    .immediate = true,
                },
                .{
                    .name = .C,
                    .immediate = true,
                },
            },
        },
        0x92 => Op{
            .mnemonic = .SUB,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .A,
                    .immediate = true,
                },
                .{
                    .name = .D,
                    .immediate = true,
                },
            },
        },
        0x93 => Op{
            .mnemonic = .SUB,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .A,
                    .immediate = true,
                },
                .{
                    .name = .E,
                    .immediate = true,
                },
            },
        },
        0x94 => Op{
            .mnemonic = .SUB,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .A,
                    .immediate = true,
                },
                .{
                    .name = .H,
                    .immediate = true,
                },
            },
        },
        0x95 => Op{
            .mnemonic = .SUB,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .A,
                    .immediate = true,
                },
                .{
                    .name = .L,
                    .immediate = true,
                },
            },
        },
        0x96 => Op{
            .mnemonic = .SUB,
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = false,
            .operands = &[_]Operand{
                .{
                    .name = .A,
                    .immediate = true,
                },
                .{
                    .name = .HL,
                    .immediate = false,
                },
            },
        },
        0x97 => Op{
            .mnemonic = .SUB,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .A,
                    .immediate = true,
                },
                .{
                    .name = .A,
                    .immediate = true,
                },
            },
        },
        0x98 => Op{
            .mnemonic = .SBC,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .A,
                    .immediate = true,
                },
                .{
                    .name = .B,
                    .immediate = true,
                },
            },
        },
        0x99 => Op{
            .mnemonic = .SBC,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .A,
                    .immediate = true,
                },
                .{
                    .name = .C,
                    .immediate = true,
                },
            },
        },
        0x9A => Op{
            .mnemonic = .SBC,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .A,
                    .immediate = true,
                },
                .{
                    .name = .D,
                    .immediate = true,
                },
            },
        },
        0x9B => Op{
            .mnemonic = .SBC,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .A,
                    .immediate = true,
                },
                .{
                    .name = .E,
                    .immediate = true,
                },
            },
        },
        0x9C => Op{
            .mnemonic = .SBC,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .A,
                    .immediate = true,
                },
                .{
                    .name = .H,
                    .immediate = true,
                },
            },
        },
        0x9D => Op{
            .mnemonic = .SBC,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .A,
                    .immediate = true,
                },
                .{
                    .name = .L,
                    .immediate = true,
                },
            },
        },
        0x9E => Op{
            .mnemonic = .SBC,
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = false,
            .operands = &[_]Operand{
                .{
                    .name = .A,
                    .immediate = true,
                },
                .{
                    .name = .HL,
                    .immediate = false,
                },
            },
        },
        0x9F => Op{
            .mnemonic = .SBC,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .A,
                    .immediate = true,
                },
                .{
                    .name = .A,
                    .immediate = true,
                },
            },
        },
        0xA0 => Op{
            .mnemonic = .AND,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .A,
                    .immediate = true,
                },
                .{
                    .name = .B,
                    .immediate = true,
                },
            },
        },
        0xA1 => Op{
            .mnemonic = .AND,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .A,
                    .immediate = true,
                },
                .{
                    .name = .C,
                    .immediate = true,
                },
            },
        },
        0xA2 => Op{
            .mnemonic = .AND,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .A,
                    .immediate = true,
                },
                .{
                    .name = .D,
                    .immediate = true,
                },
            },
        },
        0xA3 => Op{
            .mnemonic = .AND,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .A,
                    .immediate = true,
                },
                .{
                    .name = .E,
                    .immediate = true,
                },
            },
        },
        0xA4 => Op{
            .mnemonic = .AND,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .A,
                    .immediate = true,
                },
                .{
                    .name = .H,
                    .immediate = true,
                },
            },
        },
        0xA5 => Op{
            .mnemonic = .AND,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .A,
                    .immediate = true,
                },
                .{
                    .name = .L,
                    .immediate = true,
                },
            },
        },
        0xA6 => Op{
            .mnemonic = .AND,
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = false,
            .operands = &[_]Operand{
                .{
                    .name = .A,
                    .immediate = true,
                },
                .{
                    .name = .HL,
                    .immediate = false,
                },
            },
        },
        0xA7 => Op{
            .mnemonic = .AND,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .A,
                    .immediate = true,
                },
                .{
                    .name = .A,
                    .immediate = true,
                },
            },
        },
        0xA8 => Op{
            .mnemonic = .XOR,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .A,
                    .immediate = true,
                },
                .{
                    .name = .B,
                    .immediate = true,
                },
            },
        },
        0xA9 => Op{
            .mnemonic = .XOR,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .A,
                    .immediate = true,
                },
                .{
                    .name = .C,
                    .immediate = true,
                },
            },
        },
        0xAA => Op{
            .mnemonic = .XOR,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .A,
                    .immediate = true,
                },
                .{
                    .name = .D,
                    .immediate = true,
                },
            },
        },
        0xAB => Op{
            .mnemonic = .XOR,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .A,
                    .immediate = true,
                },
                .{
                    .name = .E,
                    .immediate = true,
                },
            },
        },
        0xAC => Op{
            .mnemonic = .XOR,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .A,
                    .immediate = true,
                },
                .{
                    .name = .H,
                    .immediate = true,
                },
            },
        },
        0xAD => Op{
            .mnemonic = .XOR,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .A,
                    .immediate = true,
                },
                .{
                    .name = .L,
                    .immediate = true,
                },
            },
        },
        0xAE => Op{
            .mnemonic = .XOR,
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = false,
            .operands = &[_]Operand{
                .{
                    .name = .A,
                    .immediate = true,
                },
                .{
                    .name = .HL,
                    .immediate = false,
                },
            },
        },
        0xAF => Op{
            .mnemonic = .XOR,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .A,
                    .immediate = true,
                },
                .{
                    .name = .A,
                    .immediate = true,
                },
            },
        },
        0xB0 => Op{
            .mnemonic = .OR,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .A,
                    .immediate = true,
                },
                .{
                    .name = .B,
                    .immediate = true,
                },
            },
        },
        0xB1 => Op{
            .mnemonic = .OR,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .A,
                    .immediate = true,
                },
                .{
                    .name = .C,
                    .immediate = true,
                },
            },
        },
        0xB2 => Op{
            .mnemonic = .OR,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .A,
                    .immediate = true,
                },
                .{
                    .name = .D,
                    .immediate = true,
                },
            },
        },
        0xB3 => Op{
            .mnemonic = .OR,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .A,
                    .immediate = true,
                },
                .{
                    .name = .E,
                    .immediate = true,
                },
            },
        },
        0xB4 => Op{
            .mnemonic = .OR,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .A,
                    .immediate = true,
                },
                .{
                    .name = .H,
                    .immediate = true,
                },
            },
        },
        0xB5 => Op{
            .mnemonic = .OR,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .A,
                    .immediate = true,
                },
                .{
                    .name = .L,
                    .immediate = true,
                },
            },
        },
        0xB6 => Op{
            .mnemonic = .OR,
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = false,
            .operands = &[_]Operand{
                .{
                    .name = .A,
                    .immediate = true,
                },
                .{
                    .name = .HL,
                    .immediate = false,
                },
            },
        },
        0xB7 => Op{
            .mnemonic = .OR,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .A,
                    .immediate = true,
                },
                .{
                    .name = .A,
                    .immediate = true,
                },
            },
        },
        0xB8 => Op{
            .mnemonic = .CP,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .A,
                    .immediate = true,
                },
                .{
                    .name = .B,
                    .immediate = true,
                },
            },
        },
        0xB9 => Op{
            .mnemonic = .CP,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .A,
                    .immediate = true,
                },
                .{
                    .name = .C,
                    .immediate = true,
                },
            },
        },
        0xBA => Op{
            .mnemonic = .CP,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .A,
                    .immediate = true,
                },
                .{
                    .name = .D,
                    .immediate = true,
                },
            },
        },
        0xBB => Op{
            .mnemonic = .CP,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .A,
                    .immediate = true,
                },
                .{
                    .name = .E,
                    .immediate = true,
                },
            },
        },
        0xBC => Op{
            .mnemonic = .CP,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .A,
                    .immediate = true,
                },
                .{
                    .name = .H,
                    .immediate = true,
                },
            },
        },
        0xBD => Op{
            .mnemonic = .CP,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .A,
                    .immediate = true,
                },
                .{
                    .name = .L,
                    .immediate = true,
                },
            },
        },
        0xBE => Op{
            .mnemonic = .CP,
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = false,
            .operands = &[_]Operand{
                .{
                    .name = .A,
                    .immediate = true,
                },
                .{
                    .name = .HL,
                    .immediate = false,
                },
            },
        },
        0xBF => Op{
            .mnemonic = .CP,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .A,
                    .immediate = true,
                },
                .{
                    .name = .A,
                    .immediate = true,
                },
            },
        },
        0xC0 => Op{
            .mnemonic = .RET,
            .bytes = 1,
            .cycles = &[_]u8{ 20, 8 },
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .NZ,
                    .immediate = true,
                },
            },
        },
        0xC1 => Op{
            .mnemonic = .POP,
            .bytes = 1,
            .cycles = &[_]u8{12},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .BC,
                    .immediate = true,
                },
            },
        },
        0xC2 => Op{
            .mnemonic = .JP,
            .bytes = 3,
            .cycles = &[_]u8{ 16, 12 },
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .NZ,
                    .immediate = true,
                },
                .{
                    .name = .a16,
                    .bytes = 2,
                    .immediate = true,
                },
            },
        },
        0xC3 => Op{
            .mnemonic = .JP,
            .bytes = 3,
            .cycles = &[_]u8{16},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .a16,
                    .bytes = 2,
                    .immediate = true,
                },
            },
        },
        0xC4 => Op{
            .mnemonic = .CALL,
            .bytes = 3,
            .cycles = &[_]u8{ 24, 12 },
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .NZ,
                    .immediate = true,
                },
                .{
                    .name = .a16,
                    .bytes = 2,
                    .immediate = true,
                },
            },
        },
        0xC5 => Op{
            .mnemonic = .PUSH,
            .bytes = 1,
            .cycles = &[_]u8{16},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .BC,
                    .immediate = true,
                },
            },
        },
        0xC6 => Op{
            .mnemonic = .ADD,
            .bytes = 2,
            .cycles = &[_]u8{8},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .A,
                    .immediate = true,
                },
                .{
                    .name = .n8,
                    .bytes = 1,
                    .immediate = true,
                },
            },
        },
        0xC7 => Op{
            .mnemonic = .RST,
            .bytes = 1,
            .cycles = &[_]u8{16},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .@"$00",
                    .immediate = true,
                },
            },
        },
        0xC8 => Op{
            .mnemonic = .RET,
            .bytes = 1,
            .cycles = &[_]u8{ 20, 8 },
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .Z,
                    .immediate = true,
                },
            },
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
            .operands = &[_]Operand{
                .{
                    .name = .Z,
                    .immediate = true,
                },
                .{
                    .name = .a16,
                    .bytes = 2,
                    .immediate = true,
                },
            },
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
            .operands = &[_]Operand{
                .{
                    .name = .Z,
                    .immediate = true,
                },
                .{
                    .name = .a16,
                    .bytes = 2,
                    .immediate = true,
                },
            },
        },
        0xCD => Op{
            .mnemonic = .CALL,
            .bytes = 3,
            .cycles = &[_]u8{24},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .a16,
                    .bytes = 2,
                    .immediate = true,
                },
            },
        },
        0xCE => Op{
            .mnemonic = .ADC,
            .bytes = 2,
            .cycles = &[_]u8{8},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .A,
                    .immediate = true,
                },
                .{
                    .name = .n8,
                    .bytes = 1,
                    .immediate = true,
                },
            },
        },
        0xCF => Op{
            .mnemonic = .RST,
            .bytes = 1,
            .cycles = &[_]u8{16},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .@"$08",
                    .immediate = true,
                },
            },
        },
        0xD0 => Op{
            .mnemonic = .RET,
            .bytes = 1,
            .cycles = &[_]u8{ 20, 8 },
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .NC,
                    .immediate = true,
                },
            },
        },
        0xD1 => Op{
            .mnemonic = .POP,
            .bytes = 1,
            .cycles = &[_]u8{12},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .DE,
                    .immediate = true,
                },
            },
        },
        0xD2 => Op{
            .mnemonic = .JP,
            .bytes = 3,
            .cycles = &[_]u8{ 16, 12 },
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .NC,
                    .immediate = true,
                },
                .{
                    .name = .a16,
                    .bytes = 2,
                    .immediate = true,
                },
            },
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
            .operands = &[_]Operand{
                .{
                    .name = .NC,
                    .immediate = true,
                },
                .{
                    .name = .a16,
                    .bytes = 2,
                    .immediate = true,
                },
            },
        },
        0xD5 => Op{
            .mnemonic = .PUSH,
            .bytes = 1,
            .cycles = &[_]u8{16},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .DE,
                    .immediate = true,
                },
            },
        },
        0xD6 => Op{
            .mnemonic = .SUB,
            .bytes = 2,
            .cycles = &[_]u8{8},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .A,
                    .immediate = true,
                },
                .{
                    .name = .n8,
                    .bytes = 1,
                    .immediate = true,
                },
            },
        },
        0xD7 => Op{
            .mnemonic = .RST,
            .bytes = 1,
            .cycles = &[_]u8{16},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .@"$10",
                    .immediate = true,
                },
            },
        },
        0xD8 => Op{
            .mnemonic = .RET,
            .bytes = 1,
            .cycles = &[_]u8{ 20, 8 },
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .C,
                    .immediate = true,
                },
            },
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
            .operands = &[_]Operand{
                .{
                    .name = .C,
                    .immediate = true,
                },
                .{
                    .name = .a16,
                    .bytes = 2,
                    .immediate = true,
                },
            },
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
            .operands = &[_]Operand{
                .{
                    .name = .C,
                    .immediate = true,
                },
                .{
                    .name = .a16,
                    .bytes = 2,
                    .immediate = true,
                },
            },
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
            .operands = &[_]Operand{
                .{
                    .name = .A,
                    .immediate = true,
                },
                .{
                    .name = .n8,
                    .bytes = 1,
                    .immediate = true,
                },
            },
        },
        0xDF => Op{
            .mnemonic = .RST,
            .bytes = 1,
            .cycles = &[_]u8{16},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .@"$18",
                    .immediate = true,
                },
            },
        },
        0xE0 => Op{
            .mnemonic = .LDH,
            .bytes = 2,
            .cycles = &[_]u8{12},
            .immediate = false,
            .operands = &[_]Operand{
                .{
                    .name = .a8,
                    .bytes = 1,
                    .immediate = false,
                },
                .{
                    .name = .A,
                    .immediate = true,
                },
            },
        },
        0xE1 => Op{
            .mnemonic = .POP,
            .bytes = 1,
            .cycles = &[_]u8{12},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .HL,
                    .immediate = true,
                },
            },
        },
        0xE2 => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = false,
            .operands = &[_]Operand{
                .{
                    .name = .C,
                    .immediate = false,
                },
                .{
                    .name = .A,
                    .immediate = true,
                },
            },
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
            .operands = &[_]Operand{
                .{
                    .name = .HL,
                    .immediate = true,
                },
            },
        },
        0xE6 => Op{
            .mnemonic = .AND,
            .bytes = 2,
            .cycles = &[_]u8{8},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .A,
                    .immediate = true,
                },
                .{
                    .name = .n8,
                    .bytes = 1,
                    .immediate = true,
                },
            },
        },
        0xE7 => Op{
            .mnemonic = .RST,
            .bytes = 1,
            .cycles = &[_]u8{16},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .@"$20",
                    .immediate = true,
                },
            },
        },
        0xE8 => Op{
            .mnemonic = .ADD,
            .bytes = 2,
            .cycles = &[_]u8{16},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .SP,
                    .immediate = true,
                },
                .{
                    .name = .e8,
                    .bytes = 1,
                    .immediate = true,
                },
            },
        },
        0xE9 => Op{
            .mnemonic = .JP,
            .bytes = 1,
            .cycles = &[_]u8{4},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .HL,
                    .immediate = true,
                },
            },
        },
        0xEA => Op{
            .mnemonic = .LD,
            .bytes = 3,
            .cycles = &[_]u8{16},
            .immediate = false,
            .operands = &[_]Operand{
                .{
                    .name = .a16,
                    .bytes = 2,
                    .immediate = false,
                },
                .{
                    .name = .A,
                    .immediate = true,
                },
            },
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
            .operands = &[_]Operand{
                .{
                    .name = .A,
                    .immediate = true,
                },
                .{
                    .name = .n8,
                    .bytes = 1,
                    .immediate = true,
                },
            },
        },
        0xEF => Op{
            .mnemonic = .RST,
            .bytes = 1,
            .cycles = &[_]u8{16},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .@"$28",
                    .immediate = true,
                },
            },
        },
        0xF0 => Op{
            .mnemonic = .LDH,
            .bytes = 2,
            .cycles = &[_]u8{12},
            .immediate = false,
            .operands = &[_]Operand{
                .{
                    .name = .A,
                    .immediate = true,
                },
                .{
                    .name = .a8,
                    .bytes = 1,
                    .immediate = false,
                },
            },
        },
        0xF1 => Op{
            .mnemonic = .POP,
            .bytes = 1,
            .cycles = &[_]u8{12},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .AF,
                    .immediate = true,
                },
            },
        },
        0xF2 => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = false,
            .operands = &[_]Operand{
                .{
                    .name = .A,
                    .immediate = true,
                },
                .{
                    .name = .C,
                    .immediate = false,
                },
            },
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
            .operands = &[_]Operand{
                .{
                    .name = .AF,
                    .immediate = true,
                },
            },
        },
        0xF6 => Op{
            .mnemonic = .OR,
            .bytes = 2,
            .cycles = &[_]u8{8},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .A,
                    .immediate = true,
                },
                .{
                    .name = .n8,
                    .bytes = 1,
                    .immediate = true,
                },
            },
        },
        0xF7 => Op{
            .mnemonic = .RST,
            .bytes = 1,
            .cycles = &[_]u8{16},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .@"$30",
                    .immediate = true,
                },
            },
        },
        0xF8 => Op{
            .mnemonic = .LD,
            .bytes = 2,
            .cycles = &[_]u8{12},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .HL,
                    .immediate = true,
                },
                .{
                    .name = .SP,
                    .immediate = true,
                },
                .{
                    .name = .e8,
                    .bytes = 1,
                    .immediate = true,
                },
            },
        },
        0xF9 => Op{
            .mnemonic = .LD,
            .bytes = 1,
            .cycles = &[_]u8{8},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .SP,
                    .immediate = true,
                },
                .{
                    .name = .HL,
                    .immediate = true,
                },
            },
        },
        0xFA => Op{
            .mnemonic = .LD,
            .bytes = 3,
            .cycles = &[_]u8{16},
            .immediate = false,
            .operands = &[_]Operand{
                .{
                    .name = .A,
                    .immediate = true,
                },
                .{
                    .name = .a16,
                    .bytes = 2,
                    .immediate = false,
                },
            },
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
            .operands = &[_]Operand{
                .{
                    .name = .A,
                    .immediate = true,
                },
                .{
                    .name = .n8,
                    .bytes = 1,
                    .immediate = true,
                },
            },
        },
        0xFF => Op{
            .mnemonic = .RST,
            .bytes = 1,
            .cycles = &[_]u8{16},
            .immediate = true,
            .operands = &[_]Operand{
                .{
                    .name = .@"$38",
                    .immediate = true,
                },
            },
        },
    };
}

const R = enum(u3) {
    // Register order
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
registers: struct {
    const Self = @This();

    r8: [8]u8,

    /// Set register value
    inline fn set(self: *Self, register_name: R, value: u8) void {
        self.r8[@intFromEnum(register_name)] = value;
    }

    inline fn get(self: *Self, register_name: R) u8 {
        return self.r8[@intFromEnum(register_name)];
    }

    fn get_bc(self: *Self) u16 {
        return @as(u16, self.get(R.b)) << 8 | @as(u16, self.get(R.c));
    }

    fn set_bc(self: *Self, value: u16) void {
        self.set(R.b, @as(u8, (value & 0xFF00) >> 8));
        self.set(R.c, @as(u8, value & 0x00FF));
    }

    fn get_de(self: *Self) u16 {
        return @as(u16, self.get(R.d)) << 8 | @as(u16, self.get(R.e));
    }

    fn set_de(self: *Self, value: u16) void {
        self.set(R.d, @as(u8, (value & 0xFF00) >> 8));
        self.set(R.e, @as(u8, value & 0x00FF));
    }

    fn get_hl(self: *Self) u16 {
        return @as(u16, self.get(R.h)) << 8 | @as(u16, self.get(R.l));
    }

    fn set_hl(self: *Self, value: u16) void {
        self.set(R.h, @as(u8, (value & 0xFF00) >> 8));
        self.set(R.l, @as(u8, value & 0x00FF));
    }

    fn get_af(self: *Self) u16 {
        return @as(u16, self.get(R.a)) << 8 | @as(u16, self.get(R.f));
    }

    fn set_af(self: *Self, value: u16) void {
        self.set(R.a, @as(u8, (value & 0xFF00) >> 8));
        self.set(R.f, @as(u8, value & 0x00FF));
    }

    fn get_flags(self: *Self) Flags {
        const f_register = self.r8[@intFromEnum(R.f)];
        const zero = ((f_register >> Flags.ZERO_FLAG_BYTE_POSITION) & 0b1) != 0;
        const subtract = ((f_register >> Flags.SUBTRACT_FLAG_BYTE_POSITION) & 0b1) != 0;
        const half_carry = ((f_register >> Flags.HALF_CARRY_FLAG_BYTE_POSITION) & 0b1) != 0;
        const carry = ((f_register >> Flags.CARRY_FLAG_BYTE_POSITION) & 0b1) != 0;

        return .{
            zero,
            subtract,
            half_carry,
            carry,
        };
    }

    fn set_flags(self: *Self, flags: Flags) void {
        var result: u8 = 0;

        result |= (if (flags.zero) 1 else 0) << Flags.ZERO_FLAG_BYTE_POSITION;
        result |= (if (flags.subtract) 1 else 0) << Flags.SUBTRACT_FLAG_BYTE_POSITION;
        result |= (if (flags.half_carry) 1 else 0) << Flags.HALF_CARRY_FLAG_BYTE_POSITION;
        result |= (if (flags.carry) 1 else 0) << Flags.CARRY_FLAG_BYTE_POSITION;
        self.set(R.f, result);
    }
},
pc: u16,
sp: u16,
clock: Clock,
cur_opcode: u8,
halted: bool,
stepping: bool,

fn fetch_inst(self: *Cpu) void {
    const opcode: u8 = self.bus.read_byte(self.pc);
    self.pc += 1;
    self.cur_opcode = opcode;
}

fn exec_inst(self: *Cpu) void {
    const opcode = self.cur_opcode;
    const op = fetch_opcode(self.cur_opcode);

    std.log.debug(
        \\
        \\Instruction
        \\0x{X:0>2} 0o{o:0>3}
        \\name {s}
        \\size {}
        \\
    , .{
        opcode,
        opcode,
        @tagName(op.mnemonic),
        op.bytes,
    });

    switch (op.mnemonic) {
        .NOP => {},
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
                    const dst: R = @enumFromInt(opcode >> 3 & 7);
                    const src: R = @enumFromInt(opcode & 7);
                    self.registers.set(dst, self.registers.get(src));
                },
                else => unreachable,
            }
        },
        else => @panic("Operation not implemented"),
    }
}

pub fn step(self: *Cpu) !void {
    self.fetch_inst();
    self.exec_inst();
}

pub inline fn print(self: *Cpu) void {
    std.log.debug(
        \\
        \\Registers
        \\b  = {}
        \\c  = {}
        \\d  = {}
        \\e  = {}
        \\h  = {}
        \\l  = {}
        \\a  = {}
        \\f  = {}
        \\bc = {} 
        \\de = {} 
        \\hl = {} 
        \\af = {} 
        \\pc = 0x{X:0>4} 
        \\sp = 0x{X:0>4} 
    , .{
        self.registers.get(R.b),
        self.registers.get(R.c),
        self.registers.get(R.d),
        self.registers.get(R.e),
        self.registers.get(R.h),
        self.registers.get(R.l),
        self.registers.get(R.a),
        self.registers.get(R.f),
        self.registers.get_bc(),
        self.registers.get_de(),
        self.registers.get_hl(),
        self.registers.get_af(),
        self.pc,
        0,
    });
}

pub fn init(bus: *Bus) Cpu {
    return .{
        .bus = bus,
        .registers = .{
            .r8 = [_]u8{0} ** 8,
        },
        .clock = Clock{},
        .cur_opcode = undefined,
        .halted = false,
        .stepping = false,
        .pc = 0x100,
        .sp = 0,
    };
}
