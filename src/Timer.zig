const Bus = @import("Bus.zig");
const Timer = @This();

const TAC = struct {
    clock: u2,
    enable: bool,
};

bus: *Bus,
div_count: usize,
tima_count: usize,

fn read_timer_control(self: *Timer) TAC {
    const tac = self.bus.read(0xFF07);
    return .{
        .clock = @truncate(tac & 0b11),
        .enable = tac >> 2 & 1 == 1,
    };
}

inline fn read_timer_modulo(self: *Timer) u8 {
    return self.bus.read(0xFF06);
}

fn read_tima_cycles(self: *Timer) usize {
    const tac = self.read_timer_control();
    return switch (tac.clock) {
        0b00 => 1024,
        0b01 => 16,
        0b10 => 64,
        0b11 => 256,
    };
}

pub fn run_cycles(self: *Timer, cycles: u8) void {
    const DIV_CYCLES: usize = 256;
    const TIMA_ADDR: u16 = 0xFF05;
    const TIMER_INTERRUPT_FLAG: u8 = 1 << 2;
    const tac = self.read_timer_control();
    const tima_cycles = self.read_tima_cycles();

    self.div_count += cycles;
    if (self.div_count >= DIV_CYCLES) {
        self.bus.inc_div();
        self.div_count -= DIV_CYCLES;
    }

    if (tac.enable) {
        self.tima_count += cycles;
        if (self.tima_count >= tima_cycles) {
            self.tima_count -= tima_cycles;
            if (self.bus.read(TIMA_ADDR) == 0xFF) {
                const @"if" = self.bus.read(0xFF0F) | TIMER_INTERRUPT_FLAG;
                self.bus.write(0xFF0F, @"if");
                self.bus.write(TIMA_ADDR, self.read_timer_modulo());
            } else {
                self.bus.write(TIMA_ADDR, self.bus.read(TIMA_ADDR) + 1);
            }
        }
    }
}

pub fn init(bus: *Bus) Timer {
    return .{
        .bus = bus,
        .div_count = 0,
        .tima_count = 0,
    };
}
