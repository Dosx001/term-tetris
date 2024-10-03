const Shape = @import("bag.zig").Shape;
const c = @cImport({
    @cInclude("ncurses.h");
});

pub const Board = struct {
    win: ?*c.WINDOW,
    pub fn init() Board {
        const win =
            c.newwin(22, 21, 0, 12);
        _ = c.wprintw(win,
            \\  . . . . . . . . .
            \\  . . . . . . . . .
            \\  . . . . . . . . .
            \\  . . . . . . . . .
            \\  . . . . . . . . .
            \\  . . . . . . . . .
            \\  . . . . . . . . .
            \\  . . . . . . . . .
            \\  . . . . . . . . .
            \\  . . . . . . . . .
            \\  . . . . . . . . .
            \\  . . . . . . . . .
            \\  . . . . . . . . .
            \\  . . . . . . . . .
            \\  . . . . . . . . .
            \\  . . . . . . . . .
            \\  . . . . . . . . .
            \\  . . . . . . . . .
            \\  . . . . . . . . .
            \\  . . . . . . . . .
            \\  . . . . . . . . .
        );
        _ = c.box(win, 0, 0);
        _ = c.wrefresh(win);
        return Board{ .win = win };
    }
};
