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
            c.newwin(25, 21, 0, 12);
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
        for (0..23) |y| {
            for (0..10) |x| {
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
                const cx = 2 * @as(c_int, @intCast(x)) + 1;
                const cy = @as(c_int, @intCast(y)) + 1;
                switch (state[y][x]) {
                    .Cyan => _ = c.mvwaddstr(self.win, cy, cx, " "),
                    .Blue => _ = c.mvwaddstr(self.win, cy, cx, " "),
                    .Orange => _ = c.mvwaddstr(self.win, cy, cx, " "),
                    .Yellow => _ = c.mvwaddstr(self.win, cy, cx, " "),
                    .Green => _ = c.mvwaddstr(self.win, cy, cx, " "),
                    .Magenta => _ = c.mvwaddstr(self.win, cy, cx, " "),
                    .Red => _ = c.mvwaddstr(self.win, cy, cx, " "),
                    .Black => _ = c.mvwaddstr(self.win, cy, cx, " "),
                    .Ghost => _ = c.mvwaddstr(self.win, cy, cx, "▪"),
                }
                _ = c.wattroff(self.win, color);
            }
        }
        _ = c.wrefresh(self.win);
    }
};
