const c = @cImport({
    @cInclude("ncurses.h");
});

pub const Board = struct {
    win: ?*c.WINDOW,
    pub fn init() Board {
        const win =
            c.newwin(22, 21, 0, 12);
        _ = c.waddstr(win,
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
    pub fn deinit(self: *Board) void {
        _ = c.delwin(self.win);
    }
};
