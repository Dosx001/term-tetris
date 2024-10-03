const Shape = @import("bag.zig").Shape;
const Color = @import("board.zig").Color;

pub const Game = struct {
    pub fn init() Game {
        return .{};
    }
    pub fn insert(_: *Game, shape: Shape, state: *[24][10]Color) void {
        switch (shape) {
            .I => {
                inline for (3..7) |i| state[0][i] = .Cyan;
            },
            .J => {
                state[0][3] = .Blue;
                inline for (3..6) |i| state[1][i] = .Blue;
            },
            .L => {
                state[0][5] = .Orange;
                inline for (3..6) |i| state[1][i] = .Orange;
            },
            .O => {
                inline for (4..6) |i| {
                    state[0][i] = .Yellow;
                    state[1][i] = .Yellow;
                }
            },
            .S => {
                inline for (3..5) |i| {
                    state[0][i + 1] = .Green;
                    state[1][i] = .Green;
                }
            },
            .T => {
                state[0][4] = .Magenta;
                inline for (3..6) |i| state[1][i] = .Magenta;
            },
            .Z => {
                inline for (3..5) |i| {
                    state[0][i] = .Red;
                    state[1][i + 1] = .Red;
                }
            },
            .Empty => {
                state[0][0] = .Black;
            },
        }
    }
};
