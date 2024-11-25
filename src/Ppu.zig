const std = @import("std");
const Bus = @import("Bus.zig");
const build_options = @import("build_options");
const sdl = @import("sdl2");

const Ppu = @This();

// Constants
const LCD_W: c_int = 160;
const LCD_H: c_int = 144;
const TILE_SIZE: usize = 8 * 8 * 2;
const PIXELS_DATA_SIZE: usize = LCD_W * LCD_H * 4;

// PPU Memory Addresses
const LCDC_ADDR: u16 = 0xFF40;
const LY_ADDR: u16 = 0xFF44;
const LYC_ADDR: u16 = 0xFF45;
const STAT_ADDR: u16 = 0xFF41;
const SCY_ADDR: u16 = 0xFF42;
const SCX_ADDR: u16 = 0xFF43;
const WY_ADDR: u16 = 0xFF4A;
const WX_ADDR: u16 = 0xFF4B;
const BGP_ADDR: u16 = 0xFF47;
const OBP0_ADDR: u16 = 0xFF48;
const OBP1_ADDR: u16 = 0xFF49;

// Timing Constants
const CLOCKS_PER_SCANLINE = 456;
const CLOCKS_OAM_SCAN = 80;
const CLOCKS_VRAM_READ = 172;
const CLOCKS_HBLANK = 204;
const SCANLINES_VISIBLE = 144;
const SCANLINES_VBLANK = 10;

// Structures
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

const BGPalette = packed struct(u8) {
    color0: u2,
    color1: u2,
    color2: u2,
    color3: u2,
};

const OBJPalette = packed struct(u8) {
    color0: u2 = 0,
    color1: u2,
    color2: u2,
    color3: u2,
};

const TileAttributes = packed struct(u8) {
    palette_number: u3,
    vram_bank: u1,
    horizontal_flip: bool,
    vertical_flip: bool,
    bg_priority: bool,
    _padding: u1 = 0,
};

const Sprite = struct {
    y_pos: u8,
    x_pos: u8,
    tile_index: u8,
    attributes: TileAttributes,
};

const COLORS = [4][4]u8{
    [_]u8{ 255, 255, 255, 255 }, // White
    [_]u8{ 192, 192, 192, 255 }, // Light gray
    [_]u8{ 96, 96, 96, 255 }, // Dark gray
    [_]u8{ 0, 0, 0, 255 }, // Black
};

const Tile = [8][8]u2;

// PPU State
bus: *Bus,
window: sdl.Window,
renderer: sdl.Renderer,
texture: sdl.Texture,
pixels: [PIXELS_DATA_SIZE]u8,
dot_clock: usize,
current_mode: ScreenMode,
frame_complete: bool,

pub fn init(bus: *Bus) !Ppu {
    const window_title = std.fmt.comptimePrint("zgbemu-{s}", .{build_options.version});

    const window = try sdl.createWindow(
        window_title,
        .{ .centered = {} },
        .{ .centered = {} },
        LCD_W * 4,
        LCD_H * 4,
        .{ .vis = .shown, .resizable = true },
    );
    errdefer window.destroy();

    const renderer = try sdl.createRenderer(window, null, .{
        .software = true,
        .present_vsync = true,
    });
    errdefer renderer.destroy();

    try renderer.setLogicalSize(LCD_W, LCD_H);
    try renderer.setColorRGBA(0, 0, 0, 255);

    const texture = try sdl.createTexture(
        renderer,
        .rgba8888,
        .streaming,
        LCD_W,
        LCD_H,
    );
    errdefer texture.destroy();

    var pixels: [PIXELS_DATA_SIZE]u8 = undefined;
    @memset(&pixels, 255);

    return .{
        .bus = bus,
        .window = window,
        .renderer = renderer,
        .texture = texture,
        .pixels = pixels,
        .dot_clock = 0,
        .current_mode = .searching_oam_ram,
        .frame_complete = false,
    };
}

pub fn deinit(self: *Ppu) void {
    self.texture.destroy();
    self.renderer.destroy();
    self.window.destroy();
}

pub fn render(self: *Ppu) !void {
    if (!self.frame_complete) return;

    // Debug: Print first few pixels to see if we have any data
    std.debug.print("First pixel RGBA: {any}\n", .{self.pixels[0..4]});
    std.debug.print("PPU Mode: {}, LCD enabled: {}\n", .{ self.current_mode, self.read_lcd_control().lcd_power });

    try self.renderer.setColorRGBA(0, 0, 0, 255);
    try self.renderer.clear();

    // For testing, let's fill the screen with a pattern
    @memset(&self.pixels, 255); // Make everything white
    for (0..PIXELS_DATA_SIZE / 4) |i| {
        const pixel_index = i * 4;
        // Create a checkered pattern
        if ((@divFloor(i, LCD_W) + @mod(i, LCD_W)) % 2 == 0) {
            self.pixels[pixel_index] = 255; // R
            self.pixels[pixel_index + 1] = 0; // G
            self.pixels[pixel_index + 2] = 0; // B
            self.pixels[pixel_index + 3] = 255; // A
        }
    }

    try self.texture.update(&self.pixels, LCD_W * 4, null);
    try self.renderer.copy(self.texture, null, null);
    self.renderer.present();

    self.frame_complete = false;
}

fn read_lcd_control(self: *Ppu) LCDC {
    return @bitCast(self.bus.read(LCDC_ADDR));
}

fn read_stat(self: *Ppu) STAT {
    return @bitCast(self.bus.read(STAT_ADDR));
}

pub fn tick(self: *Ppu) void {
    const lcdc = self.read_lcd_control();
    if (!lcdc.lcd_power) return;

    self.dot_clock += 1;
    var current_line = self.bus.read(LY_ADDR);
    var stat = self.read_stat();

    // Update LYC=LY comparison
    stat.lyc_eq_ly = current_line == self.bus.read(LYC_ADDR);
    if (stat.lyc_eq_ly and stat.lyc_eq_ly_check_enable) {
        const current_if = self.bus.read(0xFF0F);
        self.bus.write(0xFF0F, current_if | (1 << 1));
    }

    switch (self.current_mode) {
        .searching_oam_ram => {
            if (self.dot_clock >= CLOCKS_OAM_SCAN) {
                self.current_mode = .lcd_driver_data_transfer;
                self.dot_clock = 0;
            }
        },
        .lcd_driver_data_transfer => {
            if (self.dot_clock >= CLOCKS_VRAM_READ) {
                self.render_scanline(current_line);
                self.current_mode = .h_blank;
                self.dot_clock = 0;

                if (stat.h_blank_check_enable) {
                    const current_if = self.bus.read(0xFF0F);
                    self.bus.write(0xFF0F, current_if | (1 << 1));
                }
            }
        },
        .h_blank => {
            if (self.dot_clock >= CLOCKS_HBLANK) {
                current_line += 1;
                self.bus.write(LY_ADDR, current_line);
                self.dot_clock = 0;

                if (current_line >= SCANLINES_VISIBLE) {
                    self.current_mode = .v_blank;
                    const current_if = self.bus.read(0xFF0F);
                    // Set VBlank interrupt
                    self.bus.write(0xFF0F, current_if | (1 << 0));

                    if (stat.v_blank_check_enable) {
                        // Set STAT interrupt
                        self.bus.write(0xFF0F, current_if | (1 << 1));
                    }

                    self.frame_complete = true;
                } else {
                    self.current_mode = .searching_oam_ram;
                }
            }
        },
        .v_blank => {
            if (self.dot_clock >= CLOCKS_PER_SCANLINE) {
                current_line += 1;
                self.bus.write(LY_ADDR, current_line);
                self.dot_clock = 0;

                if (current_line > SCANLINES_VISIBLE + SCANLINES_VBLANK) {
                    current_line = 0;
                    self.bus.write(LY_ADDR, 0);
                    self.current_mode = .searching_oam_ram;
                }
            }
        },
    }

    // Update STAT mode
    stat.screen_mode = self.current_mode;
    self.bus.write(STAT_ADDR, @bitCast(stat));
}

fn decode_tile(self: *Ppu, tile_addr: u16) Tile {
    var tile: Tile = undefined;

    for (0..8) |i| {
        const row: u3 = @intCast(i);
        const byte1 = self.bus.read(tile_addr + row * 2);
        const byte2 = self.bus.read(tile_addr + row * 2 + 1);

        for (0..8) |j| {
            const col: u3 = @intCast(j);
            const bit1 = (byte1 >> (7 - col)) & 1;
            const bit2 = (byte2 >> (7 - col)) & 1;
            tile[row][col] = @truncate((bit2 << 1) | bit1);
        }
    }

    return tile;
}

fn get_sprites_on_line(self: *Ppu, line: u8, sprite_height: u8) []Sprite {
    var sprites: [10]Sprite = undefined;
    var sprite_count: usize = 0;

    var oam_addr: u16 = 0xFE00;
    while (oam_addr < 0xFEA0 and sprite_count < 10) : (oam_addr += 4) {
        const y_pos = self.bus.read(oam_addr) -% 16;
        if (line < y_pos or line >= y_pos + sprite_height) continue;

        const x_pos = self.bus.read(oam_addr + 1) -% 8;
        if (x_pos >= LCD_W) continue;

        sprites[sprite_count] = .{
            .y_pos = y_pos,
            .x_pos = x_pos,
            .tile_index = self.bus.read(oam_addr + 2),
            .attributes = @bitCast(self.bus.read(oam_addr + 3)),
        };
        sprite_count += 1;
    }

    return sprites[0..sprite_count];
}

fn render_scanline(self: *Ppu, line: u8) void {
    const lcdc = self.read_lcd_control();
    std.debug.print("Rendering scanline {}, LCD Power: {}\n", .{ line, lcdc.lcd_power });

    if (!lcdc.lcd_power) return;

    const line_offset = @as(usize, @intCast(line)) * LCD_W * 4;

    // Debug: Fill each scanline with a different color
    for (0..LCD_W) |x| {
        const pixel_offset = line_offset + x * 4;
        self.pixels[pixel_offset] = @as(u8, @intCast(line)); // R
        self.pixels[pixel_offset + 1] = 255; // G
        self.pixels[pixel_offset + 2] = 0; // B
        self.pixels[pixel_offset + 3] = 255; // A
    }

    if (lcdc.bg_enabled) {
        std.debug.print("Background enabled, rendering at line {}\n", .{line});
        self.render_background_line(line);
    }

    if (lcdc.sprites_enabled) {
        std.debug.print("Sprites enabled, rendering at line {}\n", .{line});
        const sprite_height: u8 = if (lcdc.sprite_size) 16 else 8;
        const sprites = self.get_sprites_on_line(line, sprite_height);
        self.render_sprites_line(line, sprites);
    }
}

fn render_background_line(self: *Ppu, line: u8) void {
    const lcdc = self.read_lcd_control();
    const bg_palette: BGPalette = @bitCast(self.bus.read(BGP_ADDR));

    std.debug.print("Background palette: {any}\n", .{bg_palette});

    const map_base: u16 = if (lcdc.bg_tile_map) 0x9C00 else 0x9800;
    const tile_base: u16 = if (lcdc.bg_win_tileset) 0x8000 else 0x8800;

    const scx = self.bus.read(SCX_ADDR);
    const scy = self.bus.read(SCY_ADDR);

    const y_pos = (line +% scy);
    const tile_row = @divFloor(y_pos, 8);
    const pixel_row = @mod(y_pos, 8);

    const line_offset = @as(usize, @intCast(line)) * LCD_W * 4;

    for (0..LCD_W) |x| {
        const x_pos = @as(u8, @intCast(x)) +% scx;
        const tile_col = @divFloor(x_pos, 8);
        const pixel_col = @mod(x_pos, 8);

        const map_addr: u16 = map_base + tile_row * 32 + tile_col;
        const tile_index = self.bus.read(map_addr);

        const tile_addr = if (lcdc.bg_win_tileset)
            tile_base + @as(u16, tile_index) * 16
        else
            tile_base + @as(u16, @bitCast(@as(i16, @intCast(@as(i8, @bitCast(tile_index)))) * 16));

        const tile = self.decode_tile(tile_addr);
        const color_id = tile[pixel_row][pixel_col];

        const color = switch (color_id) {
            0 => COLORS[bg_palette.color0],
            1 => COLORS[bg_palette.color1],
            2 => COLORS[bg_palette.color2],
            3 => COLORS[bg_palette.color3],
        };

        const pixel_offset = line_offset + x * 4;
        @memcpy(self.pixels[pixel_offset .. pixel_offset + 4], &color);
    }
}

fn render_window_line(self: *Ppu, line: u8) void {
    const lcdc = self.read_lcd_control();
    const win_y = self.bus.read(WY_ADDR);

    if (line < win_y) return;

    const win_x = self.bus.read(WX_ADDR) -% 7;
    if (win_x >= LCD_W) return;

    const bg_palette: BGPalette = @bitCast(self.bus.read(BGP_ADDR));
    const map_base: u16 = if (lcdc.win_tile_map) 0x9C00 else 0x9800;
    const tile_base: u16 = if (lcdc.bg_win_tileset) 0x8000 else 0x8800;

    const win_line = line - win_y;
    const tile_row = @divFloor(win_line, 8);
    const pixel_row = @mod(win_line, 8);

    const line_offset = @as(usize, @intCast(line)) * LCD_W * 4;

    var x: u16 = win_x;
    while (x < LCD_W) : (x += 1) {
        const win_x_pos = x - win_x;
        const tile_col = @divFloor(win_x_pos, 8);
        const pixel_col = @mod(win_x_pos, 8);

        const map_addr: u16 = map_base + tile_row * 32 + tile_col;
        const tile_index = self.bus.read(map_addr);

        const tile_addr = if (lcdc.bg_win_tileset)
            tile_base + @as(u16, tile_index) * 16
        else
            tile_base + @as(u16, @bitCast(@as(i16, @intCast(@as(i8, @bitCast(tile_index)))) * 16));

        const tile = self.decode_tile(tile_addr);
        const color_id = tile[pixel_row][pixel_col];

        const color = switch (color_id) {
            0 => COLORS[bg_palette.color0],
            1 => COLORS[bg_palette.color1],
            2 => COLORS[bg_palette.color2],
            3 => COLORS[bg_palette.color3],
        };

        const pixel_offset = line_offset + x * 4;
        @memcpy(self.pixels[pixel_offset .. pixel_offset + 4], &color);
    }
}

fn render_sprites_line(self: *Ppu, line: u8, sprites: []const Sprite) void {
    const lcdc = self.read_lcd_control();
    const obp0: OBJPalette = @bitCast(self.bus.read(OBP0_ADDR));
    const obp1: OBJPalette = @bitCast(self.bus.read(OBP1_ADDR));

    const sprite_height: u8 = if (lcdc.sprite_size) 16 else 8;
    const line_offset = @as(usize, @intCast(line)) * LCD_W * 4;

    // Process sprites in reverse order for proper layering
    var i: usize = sprites.len;
    while (i > 0) {
        i -= 1;
        const sprite = sprites[i];

        // Calculate which row of the sprite we're drawing
        var sprite_row = line -% sprite.y_pos;
        if (sprite.attributes.vertical_flip) {
            sprite_row = sprite_height - 1 - sprite_row;
        }

        // For 8x16 sprites, we need to handle the tile index specially
        const tile_index = if (sprite_height == 16)
            sprite.tile_index & 0xFE // Ignore lowest bit for 8x16 sprites
        else
            sprite.tile_index;

        // Calculate the tile address
        const tile_addr = 0x8000 + @as(u16, tile_index) * 16 + @as(u16, @intCast(sprite_row)) * 2;
        const tile = self.decode_tile(tile_addr);

        // Get the palette
        const palette = if (sprite.attributes.palette_number == 0) obp0 else obp1;

        // Draw the sprite pixels for this line
        var x: u8 = 0;
        while (x < 8) : (x += 1) {
            const screen_x = sprite.x_pos +% x;
            if (screen_x >= LCD_W) continue;

            var pixel_col = x;
            if (sprite.attributes.horizontal_flip) {
                pixel_col = 7 - x;
            }

            const color_id = tile[sprite_row % 8][pixel_col];
            if (color_id == 0) continue; // Transparent pixel

            const color = switch (color_id) {
                0 => continue, // Transparent
                1 => COLORS[palette.color1],
                2 => COLORS[palette.color2],
                3 => COLORS[palette.color3],
            };

            // Check if we should skip drawing due to background priority
            if (sprite.attributes.bg_priority) {
                const bg_pixel_offset = line_offset + @as(usize, screen_x) * 4;
                const bg_color = self.pixels[bg_pixel_offset];
                if (bg_color != COLORS[0][0]) continue; // Skip if background pixel is not white
            }

            const pixel_offset = line_offset + @as(usize, screen_x) * 4;
            @memcpy(self.pixels[pixel_offset .. pixel_offset + 4], &color);
        }
    }
}

// Debug helper function to dump VRAM tiles
pub fn dump_tiles(self: *Ppu) void {
    std.debug.print("\nDumping tiles from VRAM...\n", .{});

    var tile_index: usize = 0;
    while (tile_index < 384) : (tile_index += 1) {
        const tile_addr = 0x8000 + tile_index * 16;
        const tile = self.decode_tile(@intCast(tile_addr));

        std.debug.print("\nTile {}: \n", .{tile_index});
        for (tile) |row| {
            for (row) |pixel| {
                const char: u8 = switch (pixel) {
                    0 => '.',
                    1 => '+',
                    2 => '*',
                    3 => '#',
                };
                std.debug.print("{c}", .{char});
            }
            std.debug.print("\n", .{});
        }
    }
}

// Helper function to check if LCD is enabled
pub fn is_lcd_enabled(self: *Ppu) bool {
    const lcdc = self.read_lcd_control();
    return lcdc.lcd_power;
}

// Helper function to get current screen mode
pub fn get_mode(self: *Ppu) ScreenMode {
    return self.current_mode;
}
