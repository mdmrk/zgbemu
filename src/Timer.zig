const Bus = @import("Bus.zig");
const Timer = @This();

const TAC = struct {
    clock: u2,
    enable: bool,
};

bus: *Bus,
div: u8,
tima: u8,
cycle_count: usize,
timer_interrupt_requested: bool,

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

fn tima_threshold(self: *Timer) usize {
    const tac = self.read_timer_control();
    return switch (tac.clock) {
        0b00 => 256,
        0b01 => 4,
        0b10 => 16,
        0b11 => 64,
    };
}

/// Returns true if an interrupt is requested
fn increment_tima(self: *Timer) bool {
    const overflows: bool = self.tima == 0xFF;
    const new_tima_value = self.read_timer_modulo();

    if (overflows) {
        self.tima = new_tima_value;
    } else {
        self.tima +%= 1;
    }
    return overflows;
}

pub fn is_timer_interrupt_requested(self: *Timer) bool {
    if (self.timer_interrupt_requested) {
        self.timer_interrupt_requested = false;
        return true;
    }
    return false;
}

pub fn run_cycles(self: *Timer, cycles: u8) void {
    const tac = self.read_timer_control();
    const tima_max = self.tima_threshold();
    const new_value: usize = (self.cycle_count + cycles) % tima_max;
    const increment: bool = self.cycle_count + cycles >= tima_max;

    if (!tac.enable) return;
    self.cycle_count = new_value;
    if (increment) {
        const interrupt = self.increment_tima();
        if (interrupt) {
            self.timer_interrupt_requested = true;
        }
    }
}

pub fn init(bus: *Bus) Timer {
    return .{
        .bus = bus,
        .div = 0,
        .tima = 0,
        .cycle_count = 0,
        .timer_interrupt_requested = false,
    };
}
