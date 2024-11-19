const std = @import("std");
const Bus = @import("Bus.zig");
const build_options = @import("build_options");
const sdl = @import("sdl2");

const Ppu = @This();

const LCD_W: c_int = 160;
const LCD_H: c_int = 144;
const TILE_SIZE: usize = 8 * 8 * 2;
const PIXELS_DATA_SIZE: usize = LCD_W * LCD_H * 4;
const LCDC_ADDR: u16 = 0xFF40;
const LY_ADDR: u16 = 0xFF45;
const STAT_ADDR: u16 = 0xFF41;
const LCDC = packed struct(u8) {
    bg_enabled: bool,
    sprites_enabled: bool,
    sprite_size: bool,
    bg_tile_map: bool,
    bg_win_tileset: bool,
    win_enable: bool,
    win_tile_map: bool,
    lcd_power: bool,
};
const ScreenMode = enum(u2) {
    h_blank = 0,
    v_blank = 1,
    searching_oam_ram = 2,
    lcd_driver_data_transfer = 3,
};
const STAT = packed struct(u8) {
    screen_mode: ScreenMode,
    lyc_eq_ly: bool,
    h_blank_check_enable: bool,
    v_blank_check_enable: bool,
    oam_check_enable: bool,
    lyc_eq_ly_check_enable: bool,
    _padding: u1 = 1,
};
const TileAttributes = packed struct(u8) {
    palette_number: u3,
    vram_bank: u1,
    horizontal_flip: bool,
    vertical_flip: bool,
    bg_priority: bool,
    _padding: u1 = 0,
};
const Layers = struct {
    background: sdl.Texture,
    window: sdl.Texture,
    objects: sdl.Texture,
};
const Tile = [8][8]u2;

bus: *Bus,
window: sdl.Window,
renderer: sdl.Renderer,
layers: Layers,
pixels: [PIXELS_DATA_SIZE]u8,

inline fn read_lcd_control(self: *const Ppu) LCDC {
    return @bitCast(self.bus.read(LCDC_ADDR));
}

inline fn read_ly(self: *const Ppu) u8 {
    return self.bus.read(LY_ADDR);
}

inline fn read_stat(self: *const Ppu) STAT {
    return @bitCast(self.bus.read(STAT_ADDR));
}

fn decode_tile(self: *Ppu, tile_addr: u16) Tile {
    var tile: Tile = undefined;

    inline for (0..8) |y| {
        const byte1 = self.bus.read(tile_addr + y * 2);
        const byte2 = self.bus.read(tile_addr + y * 2 + 1);

        inline for (0..8) |x| {
            const bit1 = (byte1 >> (7 - @as(u3, @intCast(x)))) & 1;
            const bit2 = (byte2 >> (7 - @as(u3, @intCast(x)))) & 1;
            tile[y][x] = @intCast((bit2 << 1) | bit1);
        }
    }

    return tile;
}

pub fn render(self: *Ppu) !void {
    try self.renderer.clear();
    self.renderer.present();
}

pub fn init(bus: *Bus) !Ppu {
    const window_title = std.fmt.comptimePrint("zgbemu-{s}", .{
        build_options.version,
    });
    const window = try sdl.createWindow(
        window_title,
        .{ .centered = {} },
        .{ .centered = {} },
        160 * 4,
        144 * 4,
        .{ .vis = .shown, .resizable = true },
    );
    const renderer = try sdl.createRenderer(
        window,
        null,
        .{ .accelerated = true, .present_vsync = true },
    );
    try renderer.setLogicalSize(LCD_W, LCD_H);
    const layers = [_]sdl.Texture{try sdl.createTexture(
        renderer,
        .rgba8888,
        .streaming,
        LCD_W,
        LCD_H,
    )} ** 3;
    return .{
        .bus = bus,
        .window = window,
        .renderer = renderer,
        .layers = .{
            .background = layers[0],
            .window = layers[1],
            .objects = layers[2],
        },
        .pixels = [_]u8{0} ** PIXELS_DATA_SIZE,
    };
}

pub fn deinit(self: *Ppu) void {
    self.layers.background.destroy();
    self.layers.window.destroy();
    self.layers.objects.destroy();
    self.renderer.destroy();
    self.window.destroy();
}
