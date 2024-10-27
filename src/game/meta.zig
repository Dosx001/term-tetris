const std = @import("std");
const Color = @import("board.zig").Color;
const Spin = @import("root").Spin;
const c = @cImport({
    @cInclude("ncurses.h");
});

pub const Meta = struct {
    win: ?*c.WINDOW,
    level: u16,
    lines: u16 = 0,
    score: u64 = 0,
    combo: i7 = -1,
    pub fn init(level: u16) Meta {
        const win = c.newwin(8, 12, 14, 0);
        _ = c.mvwaddstr(win, 1, 1,
            \\SCORE
            \\ 0
            \\ LEVEL
            \\
            \\ LINES
            \\ 0
        );
        _ = c.mvwprintw(win, 4, 1, "%i", level);
        _ = c.box(win, 0, 0);
        _ = c.wrefresh(win);
        return Meta{ .win = win, .level = level };
    }
    pub fn deinit(self: *Meta) void {
        _ = c.delwin(self.win);
    }
    pub fn refresh(self: *Meta, state: *[24][10]Color, spin: *Spin) bool {
        var start: usize = 24;
        var count: usize = 0;
        var row: i6 = 23;
        while (0 <= row) : (row -= 1) {
            inline for (0..10) |j| {
                if (state[@intCast(row)][j] == Color.Black) break;
            } else {
                if (start == 24) start = @intCast(row);
                count += 1;
                if (count == 4) break;
            }
        }
        if (start == 24) return false;
        self.lines += @intCast(count);
        _ = c.mvwprintw(self.win, 6, 1, "%i", self.lines);
        switch (spin.*) {
            .Full => switch (count) {
                1 => self.score += 800 * self.level,
                2 => self.score += 1200 * self.level,
                3 => self.score += 1600 * self.level,
                else => {},
            },
            .Mini => switch (count) {
                1 => self.score += 200 * self.level,
                2 => self.score += 400 * self.level,
                else => {},
            },
            else => switch (count) {
                1 => self.score += 40 * (self.level + 1),
                2 => self.score += 100 * (self.level + 1),
                3 => self.score += 300 * (self.level + 1),
                4 => self.score += 1200 * (self.level + 1),
                else => {},
            },
        }
        spin.* = .None;
        if (count != 0) {
            self.combo += 1;
            self.score += 50 * @as(u16, @intCast(self.combo)) * self.level;
        } else self.combo = -1;
        _ = c.mvwprintw(self.win, 2, 1, "%i", self.score);
        count -= 1;
        for (start - count..start + 1) |i| {
            inline for (0..10) |j| state[i][j] = Color.Black;
        }
        var i: usize = start;
        var j: i6 = @intCast(start - count - 1);
        while (0 <= j) : (j -= 1) {
            std.mem.swap([10]Color, &state[i], &state[@intCast(j)]);
            i -= 1;
        }
        if (self.level - 1 < @divTrunc(self.lines, 10)) {
            self.level += 1;
            _ = c.mvwprintw(self.win, 4, 1, "%i", self.level);
            _ = c.wrefresh(self.win);
            return true;
        }
        _ = c.wrefresh(self.win);
        return false;
    }
    pub fn updateScore(self: *Meta, value: usize) void {
        self.score += value;
        _ = c.mvwprintw(self.win, 2, 1, "%i", self.score);
        _ = c.wrefresh(self.win);
    }
    pub fn checkSpin(self: *Meta, spin: *Spin) void {
        switch (spin.*) {
            .Full => self.score += 400 * self.level,
            .Mini => self.score += 100 * self.level,
            else => {
                spin.* = .None;
                return;
            },
        }
        spin.* = .None;
        _ = c.mvwprintw(self.win, 2, 1, "%i", self.score);
        _ = c.wrefresh(self.win);
    }
};
