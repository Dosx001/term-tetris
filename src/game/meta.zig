const c = @cImport({
    @cInclude("ncurses.h");
});

pub const Meta = struct {
    win: ?*c.WINDOW,
    pub fn init() Meta {
        const win = c.newwin(8, 12, 14, 0);
        _ = c.mvwprintw(win, 1, 1,
            \\SCORE
            \\ 2147483647
            \\ LEVEL
            \\
            \\ LINES
        );
        _ = c.box(win, 0, 0);
        _ = c.wrefresh(win);
        return Meta{ .win = win };
    }
    pub fn deinit(self: *Meta) void {
        _ = c.delwin(self.win);
    }
};
