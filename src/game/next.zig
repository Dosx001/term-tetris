const Shape = @import("bag.zig").Shape;
const c = @cImport({
    @cInclude("ncurses.h");
});

pub const Next = struct {
    win: ?*c.WINDOW,
    pub fn init() Next {
        const win = c.newwin(5, 12, 5, 0);
        _ = c.mvwprintw(win, 1, 1, "NEXT");
        _ = c.box(win, 0, 0);
        _ = c.wrefresh(win);
        return Next{ .win = win };
    }
    pub fn deinit(self: *Next) void {
        _ = c.delwin(self.win);
    }
    pub fn draw(self: *Next, shape: Shape) void {
        _ = c.mvwprintw(self.win, 2, 4, "    ");
        _ = c.mvwprintw(self.win, 3, 4, "   ");
        switch (shape) {
            .I => _ = c.mvwprintw(self.win, 2, 4, "####"),
            .J => {
                _ = c.mvwprintw(self.win, 2, 4, "#");
                _ = c.mvwprintw(self.win, 3, 4, "###");
            },
            .L => _ = {
                _ = c.mvwprintw(self.win, 2, 6, "#");
                _ = c.mvwprintw(self.win, 3, 4, "###");
            },
            .O => {
                _ = c.mvwprintw(self.win, 2, 4, "##");
                _ = c.mvwprintw(self.win, 3, 4, "##");
            },
            .S => _ = {
                _ = c.mvwprintw(self.win, 2, 5, "##");
                _ = c.mvwprintw(self.win, 3, 4, "##");
            },
            .T => _ = {
                _ = c.mvwprintw(self.win, 2, 5, "#");
                _ = c.mvwprintw(self.win, 3, 4, "###");
            },
            .Z => _ = {
                _ = c.mvwprintw(self.win, 2, 4, "##");
                _ = c.mvwprintw(self.win, 3, 5, "##");
            },
        }
        _ = c.wrefresh(self.win);
    }
};
