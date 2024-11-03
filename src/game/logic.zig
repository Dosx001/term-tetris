const std = @import("std");
const Spin = @import("root").Spin;
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
    interval: i64,
    ghost: [4][2]usize = .{ .{ 0, 0 }, .{ 0, 0 }, .{ 0, 0 }, .{ 0, 0 } },
    position: [4][2]usize = .{ .{ 0, 0 }, .{ 0, 0 }, .{ 0, 0 }, .{ 0, 0 } },
    orientation: Matrix = undefined,
    col: usize = 0,
    row: usize = 4,
    kick: bool = true,
    delay: bool = false,
    pub fn init(level: u16) Logic {
        const diff: f64 = @floatFromInt(level - 1);
        return .{
            .interval = @intFromFloat(
                std.math.pow(f64, 0.8 - (diff * 0.007), diff) * 1000,
            ),
            .now = std.time.milliTimestamp(),
        };
    }
    pub fn update(self: *Logic) bool {
        const time = std.time.milliTimestamp();
        const diff: i64 = time - self.now;
        if (self.delay and self.interval <= 500) {
            if (500 <= diff) {
                self.now = time;
                return true;
            }
        } else if (self.interval <= diff) {
            self.now = time;
            return true;
        }
        std.time.sleep(@intCast(diff * 1000));
        return false;
    }
    pub fn delete(self: *Logic, state: *[24][10]Color) void {
        inline for (0..4) |i|
            state[self.position[i][0]][self.position[i][1]] = .Black;
    }
    pub fn deleteGhost(self: *Logic, state: *[24][10]Color) void {
        inline for (self.ghost) |p| {
            if (state[p[0]][p[1]] == .Ghost)
                state[p[0]][p[1]] = .Black;
        }
    }
    fn setDelay(self: *Logic) void {
        self.delay = self.position[0][0] == self.ghost[0][0];
    }
    fn ignore(self: *Logic, state: *[24][10]Color, y: usize, x: usize) bool {
        if (state[y][x] == .Ghost) return true;
        inline for (self.position) |p|
            if (p[0] == y and p[1] == x) return true;
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
        self.setDelay();
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
        self.setDelay();
    }
    pub fn down(self: *Logic, state: *[24][10]Color) bool {
        for (self.position) |p| {
            if (23 == p[0]) return true;
            if (self.ignore(state, p[0] + 1, p[1])) continue;
            if (state[p[0] + 1][p[1]] != .Black) return true;
        }
        self.row += 1;
        const color = state[self.position[0][0]][self.position[0][1]];
        self.delete(state);
        inline for (0..4) |i| {
            self.position[i][0] += 1;
            state[self.position[i][0]][self.position[i][1]] = color;
        }
        self.setDelay();
        self.now = std.time.milliTimestamp();
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
                if (22 < p[0]) {
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
    fn checkRotation(
        self: *Logic,
        state: *[24][10]Color,
        position: *[4][2]usize,
    ) bool {
        for (position) |p| {
            if (24 == p[0]) break;
            if (self.ignore(state, p[0], p[1])) continue;
            if (state[p[0]][p[1]] != .Black) break;
        } else return false;
        if (self.kick) {
            self.kick = false;
            const offset: usize = switch (self.orientation) {
                .M4x4 => 2,
                .M3x3 => 1,
                .M2x2 => 0,
            };
            inline for (0..4) |i| position[i][0] -= offset;
            for (position) |p| {
                if (24 == p[0]) return true;
                if (self.ignore(state, p[0], p[1])) continue;
                if (state[p[0]][p[1]] != .Black) return true;
            } else return false;
        }
        return true;
    }
    pub fn rotate(
        self: *Logic,
        state: *[24][10]Color,
        shape: Shape,
        clockwise: bool,
    ) Spin {
        var spin: Spin = .None;
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
                if (self.checkRotation(state, &position)) return .None;
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
                if (shape != .T) {
                    if (self.checkRotation(state, &position)) return .None;
                } else {
                    var kick = false;
                    var pos_copy: [4][2]usize = undefined;
                    if (self.kick) {
                        kick = true;
                        self.kick = false;
                        std.mem.copyForwards([2]usize, &pos_copy, &position);
                    }
                    if (self.checkRotation(state, &position)) {
                        inline for (0..4) |i| {
                            if (clockwise) {
                                position[i][1] -= 1;
                            } else position[i][1] += 1;
                            position[i][0] += 2;
                        }
                        if (self.checkRotation(state, &position)) {
                            inline for (0..4) |i| position[i][0] -= 2;
                            if (!self.checkRotation(state, &position)) spin = .Mini;
                        } else spin = .Full;
                    } else spin = .Normal;
                    if (kick) {
                        self.kick = true;
                        if (spin == .None) {
                            if (self.checkRotation(state, &pos_copy)) return .None;
                            spin = .Normal;
                            position = pos_copy;
                        }
                    }
                    if (spin == .None) return .None;
                }
                self.orientation = Matrix{ .M3x3 = tmp };
            },
            .M2x2 => return .None,
        }
        const color = state[self.position[0][0]][self.position[0][1]];
        self.delete(state);
        inline for (0..4) |i| {
            self.position[i][0] = position[i][0];
            self.position[i][1] = position[i][1];
            state[self.position[i][0]][self.position[i][1]] = color;
        }
        self.updateGhost(state);
        self.setDelay();
        return spin;
    }
    pub fn insert(
        self: *Logic,
        shape: Shape,
        state: *[24][10]Color,
    ) bool {
        self.kick = true;
        self.delay = false;
        self.row = 4;
        self.col = if (shape == .O) 4 else 3;
        var color: Color = undefined;
        switch (shape) {
            .I => {
                color = .Cyan;
                self.orientation = .{ .M4x4 = mShape[0] };
                self.position = .{ .{ 5, 3 }, .{ 5, 4 }, .{ 5, 5 }, .{ 5, 6 } };
            },
            .J => {
                color = .Blue;
                self.orientation = .{ .M3x3 = mShape[1] };
                self.position = .{ .{ 4, 3 }, .{ 5, 3 }, .{ 5, 4 }, .{ 5, 5 } };
            },
            .L => {
                color = .Orange;
                self.orientation = .{ .M3x3 = mShape[2] };
                self.position = .{ .{ 5, 3 }, .{ 5, 4 }, .{ 5, 5 }, .{ 4, 5 } };
            },
            .O => {
                color = .Yellow;
                self.orientation = .{ .M2x2 = mShape[3] };
                self.position = .{ .{ 4, 4 }, .{ 4, 5 }, .{ 5, 4 }, .{ 5, 5 } };
            },
            .S => {
                color = .Green;
                self.orientation = .{ .M3x3 = mShape[4] };
                self.position = .{ .{ 5, 3 }, .{ 5, 4 }, .{ 4, 4 }, .{ 4, 5 } };
            },
            .T => {
                color = .Magenta;
                self.orientation = .{ .M3x3 = mShape[5] };
                self.position = .{ .{ 5, 3 }, .{ 5, 4 }, .{ 5, 5 }, .{ 4, 4 } };
            },
            .Z => {
                color = .Red;
                self.orientation = .{ .M3x3 = mShape[6] };
                self.position = .{ .{ 4, 3 }, .{ 4, 4 }, .{ 5, 4 }, .{ 5, 5 } };
            },
            .Empty => unreachable,
        }
        inline for (0..2) |_| {
            for (self.position) |p| {
                if (state[p[0]][p[1]] != .Black) {
                    self.row -= 1;
                    break;
                }
            } else break;
            inline for (0..4) |i| self.position[i][0] -= 1;
        } else return true;
        inline for (self.position) |p| state[p[0]][p[1]] = color;
        self.ghost = self.position;
        self.ghostDown(state);
        self.now = std.time.milliTimestamp();
        return false;
    }
    pub fn updateInterval(self: *Logic, level: u16) void {
        if (20 < level) return;
        const diff: f64 = @floatFromInt(level - 1);
        self.interval = @intFromFloat(std.math.pow(
            f64,
            0.8 - (diff * 0.007),
            diff,
        ) * 1000);
    }
};
