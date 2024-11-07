const std = @import("std");
const Shape = @import("bag.zig").Shape;
const c = @cImport({
    @cInclude("ncurses.h");
});

pub const Color = enum {
    Black,
    Red,
    Orange,
    Yellow,
    Green,
    Cyan,
    Blue,
    Magenta,
    Ghost,
};

pub const Board = struct {
    win: ?*c.WINDOW,
    color: c_int = 0,
    pub fn init() Board {
        const win =
            c.newwin(22, 21, 0, 12);
        _ = c.waddstr(win,
            \\  │ │ │ │ │ │ │ │ │
            \\  │ │ │ │ │ │ │ │ │
            \\  │ │ │ │ │ │ │ │ │
            \\  │ │ │ │ │ │ │ │ │
            \\  │ │ │ │ │ │ │ │ │
            \\  │ │ │ │ │ │ │ │ │
            \\  │ │ │ │ │ │ │ │ │
            \\  │ │ │ │ │ │ │ │ │
            \\  │ │ │ │ │ │ │ │ │
            \\  │ │ │ │ │ │ │ │ │
            \\  │ │ │ │ │ │ │ │ │
            \\  │ │ │ │ │ │ │ │ │
            \\  │ │ │ │ │ │ │ │ │
            \\  │ │ │ │ │ │ │ │ │
            \\  │ │ │ │ │ │ │ │ │
            \\  │ │ │ │ │ │ │ │ │
            \\  │ │ │ │ │ │ │ │ │
            \\  │ │ │ │ │ │ │ │ │
            \\  │ │ │ │ │ │ │ │ │
            \\  │ │ │ │ │ │ │ │ │
            \\  │ │ │ │ │ │ │ │ │
        );
        _ = c.box(win, 0, 0);
        _ = c.wrefresh(win);
        return Board{ .win = win };
    }
    pub fn deinit(self: *Board) void {
        _ = c.delwin(self.win);
    }
    pub fn colorGhost(self: *Board, shape: Shape) void {
        switch (shape) {
            .I => self.color = c.COLOR_PAIR(5),
            .J => self.color = c.COLOR_PAIR(6),
            .L => self.color = c.COLOR_PAIR(2),
            .O => self.color = c.COLOR_PAIR(3),
            .S => self.color = c.COLOR_PAIR(4),
            .T => self.color = c.COLOR_PAIR(7),
            .Z => self.color = c.COLOR_PAIR(1),
            else => self.color = c.COLOR_PAIR(0),
        }
    }
    pub fn draw(self: *Board, state: *[24][10]Color) void {
        inline for (4..24) |y| {
            const cy: c_int = @intCast(y - 3);
            inline for (0..10) |x| {
                const color = switch (state[y][x]) {
                    .Red => c.COLOR_PAIR(1),
                    .Orange => c.COLOR_PAIR(2),
                    .Yellow => c.COLOR_PAIR(3),
                    .Green => c.COLOR_PAIR(4),
                    .Cyan => c.COLOR_PAIR(5),
                    .Blue => c.COLOR_PAIR(6),
                    .Magenta => c.COLOR_PAIR(7),
                    .Black => c.COLOR_PAIR(0),
                    .Ghost => self.color,
                };
                _ = c.wattron(self.win, color);
                const cx: c_int = @intCast(2 * x + 1);
                _ = c.mvwaddstr(
                    self.win,
                    cy,
                    cx,
                    if (state[y][x] == .Ghost) "▪" else " ",
                );
                _ = c.wattroff(self.win, color);
            }
        }
        _ = c.wrefresh(self.win);
    }
    pub fn animate(self: *Board, state: *[24][10]Color) void {
        inline for (0..3) |_| {
            inline for (1..21) |y| {
                const cy: c_int = @intCast(y);
                inline for (0..10) |x| {
                    const cx: c_int = @intCast(2 * x + 1);
                    _ = c.mvwaddstr(self.win, cy, cx, " ");
                }
            }
            _ = c.wrefresh(self.win);
            std.time.sleep(200_000_000);
            self.draw(state);
            std.time.sleep(200_000_000);
        }
    }
};
