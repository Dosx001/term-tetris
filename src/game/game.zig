const std = @import("std");
const Shape = @import("bag.zig").Shape;
const Color = @import("board.zig").Color;

pub const Game = struct {
    now: i64,
    interval: i64 = 800,
    position: [4][2]usize = .{ .{ 0, 0 }, .{ 0, 0 }, .{ 0, 0 }, .{ 0, 0 } },
    pub fn init() Game {
        return .{
            .now = std.time.milliTimestamp(),
        };
    }
    pub fn update(self: *Game) bool {
        const time = std.time.milliTimestamp();
        if (self.interval <= time - self.now) {
            self.now = time;
            return true;
        }
        return false;
    }
    fn delete(self: *Game, state: *[24][10]Color) void {
        inline for (0..4) |i| state[self.position[i][0]][self.position[i][1]] = .Black;
    }
    fn ignore(self: *Game, y: usize, x: usize) bool {
        inline for (self.position) |p| if (p[0] == y and p[1] == x) return true;
        return false;
    }
    pub fn left(self: *Game, state: *[24][10]Color) void {
        for (self.position) |p| {
            if (p[1] < 1) return;
            if (ignore(self, p[0], p[1] - 1)) continue;
            if (state[p[0]][p[1] - 1] != .Black) return;
        }
        const color = state[self.position[0][0]][self.position[0][1]];
        delete(self, state);
        inline for (0..4) |i| {
            self.position[i][1] -= 1;
            state[self.position[i][0]][self.position[i][1]] = color;
        }
    }
    pub fn right(self: *Game, state: *[24][10]Color) void {
        for (self.position) |p| {
            if (8 < p[1]) return;
            if (ignore(self, p[0], p[1] + 1)) continue;
            if (state[p[0]][p[1] + 1] != .Black) return;
        }
        const color = state[self.position[0][0]][self.position[0][1]];
        delete(self, state);
        inline for (0..4) |i| {
            self.position[i][1] += 1;
            state[self.position[i][0]][self.position[i][1]] = color;
        }
    }
    pub fn down(self: *Game, state: *[24][10]Color) bool {
        for (self.position) |p| {
            if (21 < p[0]) return true;
            if (ignore(self, p[0] + 1, p[1])) continue;
            if (state[p[0] + 1][p[1]] != .Black) return true;
        }
        const color = state[self.position[0][0]][self.position[0][1]];
        delete(self, state);
        inline for (0..4) |i| {
            self.position[i][0] += 1;
            state[self.position[i][0]][self.position[i][1]] = color;
        }
        return false;
    }
    pub fn insert(self: *Game, shape: Shape, state: *[24][10]Color) void {
        switch (shape) {
            .I => {
                inline for (3..7) |i| state[0][i] = .Cyan;
                inline for (0..4) |i| self.position[i] = .{ 0, i + 3 };
            },
            .J => {
                state[0][3] = .Blue;
                inline for (3..6) |i| state[1][i] = .Blue;
                self.position[0] = .{ 0, 3 };
                inline for (1..4) |i| self.position[i] = .{ 1, i + 2 };
            },
            .L => {
                state[0][5] = .Orange;
                inline for (3..6) |i| state[1][i] = .Orange;
                self.position[0] = .{ 0, 5 };
                inline for (1..4) |i| self.position[i] = .{ 1, i + 2 };
            },
            .O => {
                inline for (4..6) |i| {
                    state[0][i] = .Yellow;
                    state[1][i] = .Yellow;
                }
                inline for (0..2) |i| {
                    self.position[i] = .{ 0, i + 4 };
                    self.position[i + 2] = .{ 1, i + 4 };
                }
            },
            .S => {
                inline for (3..5) |i| {
                    state[0][i + 1] = .Green;
                    state[1][i] = .Green;
                }
                inline for (0..2) |i| self.position[i] = .{ 0, i + 4 };
                inline for (2..4) |i| self.position[i] = .{ 1, i + 1 };
            },
            .T => {
                state[0][4] = .Magenta;
                inline for (3..6) |i| state[1][i] = .Magenta;
                self.position[0] = .{ 0, 4 };
                inline for (1..4) |i| self.position[i] = .{ 1, i + 2 };
            },
            .Z => {
                inline for (3..5) |i| {
                    state[0][i] = .Red;
                    state[1][i + 1] = .Red;
                }
                inline for (0..2) |i| self.position[i] = .{ 0, i + 3 };
                inline for (2..4) |i| self.position[i] = .{ 1, i + 2 };
            },
            .Empty => {
                state[0][0] = .Black;
            },
        }
    }
};
