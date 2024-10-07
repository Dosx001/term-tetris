const std = @import("std");
const Shape = @import("bag.zig").Shape;
const c = @cImport({
    @cInclude("ncurses.h");
});

pub const Next = struct {
    win: ?*c.WINDOW,
    shape: Shape = Shape.Empty,
    pub fn init() Next {
        const win = c.newwin(5, 12, 5, 0);
        _ = c.mvwaddstr(win, 1, 1, "NEXT");
        _ = c.box(win, 0, 0);
        _ = c.wrefresh(win);
        return Next{ .win = win };
    }
    pub fn deinit(self: *Next) void {
        _ = c.delwin(self.win);
    }
    pub fn draw(self: *Next, shape: Shape) Shape {
        _ = c.mvwaddstr(self.win, 2, 4, "    ");
        _ = c.mvwaddstr(self.win, 3, 4, "   ");
        const color = switch (shape) {
            .I => c.COLOR_PAIR(5),
            .J => c.COLOR_PAIR(6),
            .L => c.COLOR_PAIR(2),
            .O => c.COLOR_PAIR(3),
            .S => c.COLOR_PAIR(4),
            .T => c.COLOR_PAIR(7),
            .Z => c.COLOR_PAIR(1),
            .Empty => c.COLOR_PAIR(0),
        };
        _ = c.wattron(self.win, color);
        switch (shape) {
            .I => _ = c.mvwaddstr(self.win, 2, 4, "    "),
            .J => {
                _ = c.mvwaddstr(self.win, 2, 4, " ");
                _ = c.mvwaddstr(self.win, 3, 4, "   ");
            },
            .L => {
                _ = c.mvwaddstr(self.win, 2, 6, " ");
                _ = c.mvwaddstr(self.win, 3, 4, "   ");
            },
            .O => {
                _ = c.mvwaddstr(self.win, 2, 4, "  ");
                _ = c.mvwaddstr(self.win, 3, 4, "  ");
            },
            .S => {
                _ = c.mvwaddstr(self.win, 2, 5, "  ");
                _ = c.mvwaddstr(self.win, 3, 4, "  ");
            },
            .T => {
                _ = c.mvwaddstr(self.win, 2, 5, " ");
                _ = c.mvwaddstr(self.win, 3, 4, "   ");
            },
            .Z => {
                _ = c.mvwaddstr(self.win, 2, 4, "  ");
                _ = c.mvwaddstr(self.win, 3, 5, "  ");
            },
            else => {},
        }
        _ = c.wattroff(self.win, color);
        _ = c.wrefresh(self.win);
        const tmp = self.shape;
        self.shape = shape;
        return tmp;
    }
};
