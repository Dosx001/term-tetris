const std = @import("std");
const Color = @import("board.zig").Color;
const c = @cImport({
    @cInclude("ncurses.h");
});

const levels = [29]u16{
    10,
    30,
    60,
    100,
    150,
    210,
    280,
    360,
    450,
    550,
    650,
    750,
    850,
    950,
    1050,
    1150,
    1260,
    1380,
    1510,
    1650,
    1800,
    1960,
    2130,
    2310,
    2500,
    2700,
    2900,
    3100,
    3300,
};

pub const Meta = struct {
    win: ?*c.WINDOW,
    lines: usize = 0,
    level: usize = 0,
    pub fn init() Meta {
        const win = c.newwin(8, 12, 17, 0);
        _ = c.mvwaddstr(win, 1, 1,
            \\SCORE
            \\ 0
            \\ LEVEL
            \\ 0
            \\ LINES
            \\ 0
        );
        _ = c.box(win, 0, 0);
        _ = c.wrefresh(win);
        return Meta{ .win = win };
    }
    pub fn deinit(self: *Meta) void {
        _ = c.delwin(self.win);
    }
    pub fn clear(self: *Meta, state: *[24][10]Color) void {
        var start: usize = 24;
        var count: usize = 0;
        var row: i8 = 23;
        while (0 <= row) : (row -= 1) {
            inline for (0..10) |j| {
                if (state[@intCast(row)][j] == Color.Black) break;
            } else {
                if (start == 24) start = @intCast(row);
                count += 1;
                if (count == 4) break;
            }
        }
        if (start == 24) return;
        self.lines += count;
        count -= 1;
        for (start - count..start + 1) |i| {
            inline for (0..10) |j| state[i][j] = Color.Black;
        }
        var i: usize = start;
        var j: i8 = @intCast(start - count - 1);
        while (0 <= j) : (j -= 1) {
            std.mem.swap([10]Color, &state[i], &state[@intCast(j)]);
            i -= 1;
        }
        if (self.level != 30 and levels[self.level] <= self.lines) {
            self.level += 1;
            _ = c.mvwprintw(self.win, 4, 1, "%i", self.level);
        }
        _ = c.mvwprintw(self.win, 6, 1, "%i", self.lines);
        _ = c.wrefresh(self.win);
    }
};
