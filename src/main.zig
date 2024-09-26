const nc = @cImport(@cInclude("ncurses.h"));

pub fn main() !void {
    _ = nc.initscr();
    _ = nc.refresh();
    _ = nc.getch();
    _ = nc.endwin();
}
