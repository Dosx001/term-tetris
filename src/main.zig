const std = @import("std");
const nc = @cImport(@cInclude("ncurses.h"));

pub fn main() !void {
    _ = nc.initscr();
    _ = nc.noecho();
    const title = nc.newwin(10, 30, 2, 65);
    const menu = nc.newwin(10, 30, 12, 65);
    _ = nc.refresh();
    _ = nc.box(title, 0, 0);
    _ = nc.wmove(title, 5, 7);
    _ = nc.waddstr(title, "Terminal Tetris");
    _ = nc.wrefresh(title);
    _ = nc.box(menu, 0, 0);
    _ = nc.wmove(menu, 4, 12);
    _ = nc.waddstr(menu, "Play");
    _ = nc.wmove(menu, 5, 12);
    _ = nc.waddstr(menu, "Quit");
    _ = nc.mvaddstr(22, 64, "j/k, w/s, or arrow keys to move");
    _ = nc.wmove(menu, 4, 11);
    _ = nc.wrefresh(menu);
    var cursor = [2]c_int{ 4, 11 };
    var run = true;
    var value: c_int = 0;
    while (run) {
        value = nc.getch();
        switch (value) {
            10 => {
                switch (cursor[0]) {
                    4 => {},
                    5 => {
                        run = false;
                    },
                    else => {},
                }
            },
            106 => {
                if (cursor[0] != 5) {
                    cursor[0] += 1;
                    _ = nc.wmove(menu, cursor[0], cursor[1]);
                    _ = nc.wrefresh(menu);
                }
            },
            107 => {
                if (cursor[0] != 4) {
                    cursor[0] -= 1;
                    _ = nc.wmove(menu, cursor[0], cursor[1]);
                    _ = nc.wrefresh(menu);
                }
            },
            else => {},
        }
    }
    _ = nc.endwin();
}
