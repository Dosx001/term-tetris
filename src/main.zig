const nc = @cImport(@cInclude("ncurses.h"));

pub fn main() !void {
    _ = nc.initscr();
    _ = nc.noecho();
    const title: ?*nc.WINDOW = nc.newwin(10, 30, 2, 65);
    _ = nc.refresh();
    _ = nc.box(title, 0, 0);
    _ = nc.wmove(title, 5, 7);
    _ = nc.waddstr(title, "Terminal Tetris");
    _ = nc.wrefresh(title);
    _ = nc.getch();
    _ = nc.endwin();
}
