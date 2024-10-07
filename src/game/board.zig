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
    color: Color = Color.Black,
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
            .I => self.color = Color.Cyan,
            .J => self.color = Color.Blue,
            .L => self.color = Color.Orange,
            .O => self.color = Color.Yellow,
            .S => self.color = Color.Green,
            .T => self.color = Color.Magenta,
            .Z => self.color = Color.Red,
            else => self.color = Color.Black,
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
                    .Ghost => switch (self.color) {
                        .Cyan => c.COLOR_PAIR(5),
                        .Blue => c.COLOR_PAIR(6),
                        .Orange => c.COLOR_PAIR(2),
                        .Yellow => c.COLOR_PAIR(3),
                        .Green => c.COLOR_PAIR(4),
                        .Magenta => c.COLOR_PAIR(7),
                        .Red => c.COLOR_PAIR(1),
                        else => c.COLOR_PAIR(0),
                    },
                };
                _ = c.wattron(self.win, color);
                var cx: u8 = @intCast(x);
                var cy: u8 = @intCast(y);
                cy += 1;
                cx = 2 * cx + 1;
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
