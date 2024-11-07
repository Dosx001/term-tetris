const std = @import("std");
const Bag = @import("bag.zig");
const c = @cImport({
    @cInclude("ncurses.h");
});

pub const Next = struct {
    win: ?*c.WINDOW,
    shapes: std.fifo.LinearFifo(
        Bag.Shape,
        .{ .Static = 3 },
    ) = std.fifo.LinearFifo(
        Bag.Shape,
        .{ .Static = 3 },
    ).init(),
    pub fn init(bag: *Bag.Bag) Next {
        const win = c.newwin(11, 12, 0, 34);
        _ = c.mvwaddstr(win, 1, 1, "NEXT");
        _ = c.box(win, 0, 0);
        var next = Next{ .win = win };
        inline for (0..3) |_|
            next.shapes.writeItem(bag.grab()) catch unreachable;
        _ = c.wrefresh(win);
        return next;
    }
    pub fn deinit(self: *Next) void {
        _ = c.delwin(self.win);
        self.shapes.deinit();
    }
    pub fn draw(self: *Next, shape: Bag.Shape) Bag.Shape {
        const res = self.shapes.readItem().?;
        self.shapes.writeItem(shape) catch unreachable;
        inline for (0..3) |i| {
            const y1: c_int = @intCast(3 * i + 2);
            const y2: c_int = y1 + 1;
            _ = c.mvwaddstr(self.win, y1, 4, "    ");
            _ = c.mvwaddstr(self.win, y2, 4, "   ");
            const s = self.shapes.peekItem(i);
            const color = switch (s) {
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
            switch (s) {
                .I => _ = c.mvwaddstr(self.win, y1, 4, "    "),
                .J => {
                    _ = c.mvwaddstr(self.win, y1, 4, " ");
                    _ = c.mvwaddstr(self.win, y2, 4, "   ");
                },
                .L => {
                    _ = c.mvwaddstr(self.win, y1, 6, " ");
                    _ = c.mvwaddstr(self.win, y2, 4, "   ");
                },
                .O => {
                    _ = c.mvwaddstr(self.win, y1, 4, "  ");
                    _ = c.mvwaddstr(self.win, y2, 4, "  ");
                },
                .S => {
                    _ = c.mvwaddstr(self.win, y1, 5, "  ");
                    _ = c.mvwaddstr(self.win, y2, 4, "  ");
                },
                .T => {
                    _ = c.mvwaddstr(self.win, y1, 5, " ");
                    _ = c.mvwaddstr(self.win, y2, 4, "   ");
                },
                .Z => {
                    _ = c.mvwaddstr(self.win, y1, 4, "  ");
                    _ = c.mvwaddstr(self.win, y2, 5, "  ");
                },
                else => {},
            }
            _ = c.wattroff(self.win, color);
        }
        _ = c.wrefresh(self.win);
        return res;
    }
};
