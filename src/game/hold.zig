const c = @cImport({
    @cInclude("ncurses.h");
});

pub const Hold = struct {
    win: ?*c.WINDOW,
    pub fn init() Hold {
        const win = c.newwin(5, 12, 0, 0);
        _ = c.mvwprintw(win, 1, 1, "HOLD");
        _ = c.box(win, 0, 0);
        _ = c.wrefresh(win);
        return Hold{ .win = win };
    }
};
