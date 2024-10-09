const std = @import("std");
const Shape = @import("bag.zig").Shape;
const Color = @import("board.zig").Color;
const c = @cImport({
    @cInclude("ncurses.h");
});

const Matrix = union(enum) {
    M4x4: [4][4]usize,
    M3x3: [3][3]usize,
    M2x2: [2][2]usize,
};

const mShape = .{
    .{
        .{ 0, 0, 0, 0 },
        .{ 1, 1, 1, 1 },
        .{ 0, 0, 0, 0 },
        .{ 0, 0, 0, 0 },
    },
    .{
        .{ 1, 0, 0 },
        .{ 1, 1, 1 },
        .{ 0, 0, 0 },
    },
    .{
        .{ 0, 0, 1 },
        .{ 1, 1, 1 },
        .{ 0, 0, 0 },
    },
    .{
        .{ 1, 1 },
        .{ 1, 1 },
    },
    .{
        .{ 0, 1, 1 },
        .{ 1, 1, 0 },
        .{ 0, 0, 0 },
    },
    .{
        .{ 0, 1, 0 },
        .{ 1, 1, 1 },
        .{ 0, 0, 0 },
    },
    .{
        .{ 1, 1, 0 },
        .{ 0, 1, 1 },
        .{ 0, 0, 0 },
    },
};

pub const Logic = struct {
    now: i64,
    interval: i64 = 1000,
    ghost: [4][2]usize = .{ .{ 0, 0 }, .{ 0, 0 }, .{ 0, 0 }, .{ 0, 0 } },
    position: [4][2]usize = .{ .{ 0, 0 }, .{ 0, 0 }, .{ 0, 0 }, .{ 0, 0 } },
    orientation: Matrix = undefined,
    col: usize = 0,
    row: usize = 0,
    pub fn init() Logic {
        return .{
            .now = std.time.milliTimestamp(),
        };
    }
    pub fn update(self: *Logic) bool {
        const time = std.time.milliTimestamp();
        const diff: i64 = time - self.now;
        if (self.interval <= diff) {
            self.now = time;
            return true;
        }
        std.time.sleep(@intCast(diff * 1000));
        return false;
    }
    pub fn delete(self: *Logic, state: *[24][10]Color) void {
        inline for (0..4) |i| state[self.position[i][0]][self.position[i][1]] = .Black;
    }
    pub fn deleteGhost(self: *Logic, state: *[24][10]Color) void {
        inline for (self.ghost) |p| {
            if (state[p[0]][p[1]] == .Ghost)
                state[p[0]][p[1]] = .Black;
        }
    }
    fn ignore(self: *Logic, state: *[24][10]Color, y: usize, x: usize) bool {
        if (state[y][x] == .Ghost) return true;
        inline for (self.position) |p| if (p[0] == y and p[1] == x) return true;
        return false;
    }
    pub fn left(self: *Logic, state: *[24][10]Color) void {
        for (self.position) |p| {
            if (p[1] < 1) return;
            if (self.ignore(state, p[0], p[1] - 1)) continue;
            if (state[p[0]][p[1] - 1] != .Black) return;
        }
        if (self.col != 0)
            self.col -= 1;
        const color = state[self.position[0][0]][self.position[0][1]];
        self.delete(state);
        inline for (0..4) |i| {
            self.position[i][1] -= 1;
            state[self.position[i][0]][self.position[i][1]] = color;
        }
        self.updateGhost(state);
    }
    pub fn right(self: *Logic, state: *[24][10]Color) void {
        for (self.position) |p| {
            if (8 < p[1]) return;
            if (self.ignore(state, p[0], p[1] + 1)) continue;
            if (state[p[0]][p[1] + 1] != .Black) return;
        }
        switch (self.orientation) {
            .M4x4 => {
                if (self.col != 6)
                    self.col += 1;
            },
            .M3x3 => {
                if (self.col != 7)
                    self.col += 1;
            },
            .M2x2 => {},
        }
        const color = state[self.position[0][0]][self.position[0][1]];
        self.delete(state);
        inline for (0..4) |i| {
            self.position[i][1] += 1;
            state[self.position[i][0]][self.position[i][1]] = color;
        }
        self.updateGhost(state);
    }
    pub fn down(self: *Logic, state: *[24][10]Color) bool {
        for (self.position) |p| {
            if (22 == p[0]) return true;
            if (self.ignore(state, p[0] + 1, p[1])) continue;
            if (state[p[0] + 1][p[1]] != .Black) return true;
        }
        switch (self.orientation) {
            .M4x4 => {
                if (self.row != 19) self.row += 1;
            },
            .M3x3 => {
                if (self.row != 20) self.row += 1;
            },
            .M2x2 => {},
        }
        const color = state[self.position[0][0]][self.position[0][1]];
        self.delete(state);
        inline for (0..4) |i| {
            self.position[i][0] += 1;
            state[self.position[i][0]][self.position[i][1]] = color;
        }
        return false;
    }
    pub fn harddrop(self: *Logic, state: *[24][10]Color) usize {
        var count: usize = 0;
        while (!self.down(state)) count += 1;
        return count * 2;
    }
    fn updateGhost(self: *Logic, state: *[24][10]Color) void {
        self.deleteGhost(state);
        std.mem.copyForwards([2]usize, &self.ghost, &self.position);
        self.ghostDown(state);
    }
    fn ghostDown(self: *Logic, state: *[24][10]Color) void {
        var check = true;
        while (check) {
            for (self.ghost) |p| {
                if (21 < p[0]) {
                    check = false;
                    break;
                }
                if (self.ignore(state, p[0] + 1, p[1])) continue;
                if (state[p[0] + 1][p[1]] != .Black) {
                    check = false;
                    break;
                }
            }
            if (check) {
                inline for (0..4) |i| self.ghost[i][0] += 1;
            }
        }
        for (self.ghost) |p| {
            if (state[p[0]][p[1]] == .Black)
                state[p[0]][p[1]] = .Ghost;
        }
    }
    pub fn rotate(self: *Logic, state: *[24][10]Color, clockwise: bool) void {
        var position: [4][2]usize = undefined;
        switch (self.orientation) {
            .M4x4 => |m| {
                var tmp: [4][4]usize = undefined;
                inline for (0..4) |i| {
                    inline for (0..4) |j| {
                        if (clockwise) {
                            tmp[j][3 - i] = m[i][j];
                        } else tmp[3 - j][i] = m[i][j];
                    }
                }
                var idx: usize = 0;
                inline for (tmp, 0..) |row, i| {
                    for (row, 0..) |num, j| {
                        if (num == 0) continue;
                        position[idx][0] = i + self.row;
                        position[idx][1] = j + self.col;
                        idx += 1;
                    }
                }
                for (position) |p| {
                    if (self.ignore(state, p[0], p[1])) continue;
                    if (state[p[0]][p[1]] != .Black) return;
                }
                self.orientation = Matrix{ .M4x4 = tmp };
            },
            .M3x3 => |m| {
                var tmp: [3][3]usize = undefined;
                inline for (0..3) |i| {
                    inline for (0..3) |j| {
                        if (clockwise) {
                            tmp[j][2 - i] = m[i][j];
                        } else tmp[2 - j][i] = m[i][j];
                    }
                }
                var idx: usize = 0;
                inline for (tmp, 0..) |row, i| {
                    for (row, 0..) |num, j| {
                        if (num == 0) continue;
                        position[idx][0] = i + self.row;
                        position[idx][1] = j + self.col;
                        idx += 1;
                    }
                }
                for (position) |p| {
                    if (self.ignore(state, p[0], p[1])) continue;
                    if (state[p[0]][p[1]] != .Black) return;
                }
                self.orientation = Matrix{ .M3x3 = tmp };
            },
            .M2x2 => return,
        }
        const color = state[self.position[0][0]][self.position[0][1]];
        self.delete(state);
        inline for (0..4) |i| {
            self.position[i][0] = position[i][0];
            self.position[i][1] = position[i][1];
            state[self.position[i][0]][self.position[i][1]] = color;
        }
        self.updateGhost(state);
    }
    pub fn insert(self: *Logic, shape: Shape, state: *[24][10]Color) void {
        self.row = 0;
        self.col = if (shape == .O) 4 else 3;
        switch (shape) {
            .I => {
                self.orientation = .{ .M4x4 = mShape[0] };
                inline for (3..7) |i| state[0][i] = .Cyan;
                inline for (0..4) |i| self.position[i] = .{ 0, i + 3 };
            },
            .J => {
                self.orientation = .{ .M3x3 = mShape[1] };
                state[0][3] = .Blue;
                inline for (3..6) |i| state[1][i] = .Blue;
                self.position[0] = .{ 0, 3 };
                inline for (1..4) |i| self.position[i] = .{ 1, i + 2 };
            },
            .L => {
                self.orientation = .{ .M3x3 = mShape[2] };
                state[0][5] = .Orange;
                inline for (3..6) |i| state[1][i] = .Orange;
                self.position[0] = .{ 0, 5 };
                inline for (1..4) |i| self.position[i] = .{ 1, i + 2 };
            },
            .O => {
                self.orientation = .{ .M2x2 = mShape[3] };
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
                self.orientation = .{ .M3x3 = mShape[4] };
                inline for (3..5) |i| {
                    state[0][i + 1] = .Green;
                    state[1][i] = .Green;
                }
                inline for (0..2) |i| self.position[i] = .{ 0, i + 4 };
                inline for (2..4) |i| self.position[i] = .{ 1, i + 1 };
            },
            .T => {
                self.orientation = .{ .M3x3 = mShape[5] };
                state[0][4] = .Magenta;
                inline for (3..6) |i| state[1][i] = .Magenta;
                self.position[0] = .{ 0, 4 };
                inline for (1..4) |i| self.position[i] = .{ 1, i + 2 };
            },
            .Z => {
                self.orientation = .{ .M3x3 = mShape[6] };
                inline for (3..5) |i| {
                    state[0][i] = .Red;
                    state[1][i + 1] = .Red;
                }
                inline for (0..2) |i| self.position[i] = .{ 0, i + 3 };
                inline for (2..4) |i| self.position[i] = .{ 1, i + 2 };
            },
            .Empty => {},
        }
        self.ghost = self.position;
        self.ghostDown(state);
    }
    pub fn updateInterval(self: *Logic, level: usize) void {
        if (20 < level) return;
        const diff: f64 = @floatFromInt(level - 1);
        self.interval = @intFromFloat(std.math.pow(f64, 0.8 - (diff * 0.007), diff) * 1000);
    }
};
