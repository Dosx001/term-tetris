const std = @import("std");
const c = @cImport({
    @cInclude("ncurses.h");
    @cInclude("menu.h");
    @cInclude("locale.h");
});

pub fn main() !void {
    _ = c.setlocale(c.LC_ALL, "");
    _ = c.initscr();
    _ = c.noecho();
    _ = c.keypad(c.stdscr, true);
    const choices = &[_][*c]const u8{ "Play", "Help", "Quit" };
    var items: []?*c.ITEM = try std.heap.page_allocator.alloc(?*c.ITEM, choices.len);
    for (choices, 0..) |choice, i| items[i] = c.new_item(choice, null).?;
    const menu = c.new_menu(items.ptr);
    const win = c.newwin(choices.len + 2, 8, 12, 19);
    _ = c.set_menu_win(menu, win);
    _ = c.set_menu_sub(menu, c.derwin(win, choices.len, 8, 1, 0));
    _ = c.post_menu(menu);
    var run = true;
    var refresh = true;
    var input: c_int = undefined;
    while (run) {
        if (refresh) {
            _ = c.mvprintw(0, 0,
                \\    ████████╗███████╗██████╗ ███╗   ███╗
                \\    ╚══██╔══╝██╔════╝██╔══██╗████╗ ████║
                \\       ██║   █████╗  ██████╔╝██╔████╔██║
                \\       ██║   ██╔══╝  ██╔══██╗██║╚██╔╝██║
                \\       ██║   ███████╗██║  ██║██║ ╚═╝ ██║
                \\       ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝
                \\████████╗███████╗████████╗██████╗ ██╗███████╗
                \\╚══██╔══╝██╔════╝╚══██╔══╝██╔══██╗██║██╔════╝
                \\   ██║   █████╗     ██║   ██████╔╝██║███████╗
                \\   ██║   ██╔══╝     ██║   ██╔══██╗██║╚════██║
                \\   ██║   ███████╗   ██║   ██║  ██║██║███████║
                \\   ╚═╝   ╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝╚══════╝
            );
            _ = c.refresh();
            _ = c.set_current_item(menu, items[0]);
            refresh = false;
        }
        _ = c.wrefresh(win);
        input = c.getch();
        switch (input) {
            113 => run = false,
            10 => {
                switch (c.item_index(c.current_item(menu).?)) {
                    0 => _ = c.mvprintw(c.LINES - 1, 0, "Play"),
                    1 => refresh = help(),
                    2 => run = false,
                    else => {},
                }
            },
            106, c.KEY_DOWN => _ = c.menu_driver(menu, c.REQ_DOWN_ITEM),
            107, c.KEY_UP => _ = c.menu_driver(menu, c.REQ_UP_ITEM),
            else => {},
        }
    }
    _ = c.unpost_menu(menu);
    _ = c.free_menu(menu);
    for (items) |item| _ = c.free_item(item);
    _ = c.endwin();
}

fn help() bool {
    _ = c.clear();
    _ = c.mvprintw(0, 0,
        \\# Help
        \\
        \\## Menu
        \\
        \\Esc: Go back
        \\Enter: Select an option
        \\j/k or arrow keys: Move up/down
        \\
        \\## Gameplay
        \\
        \\Left/Right keys: Move shape
        \\Up Arrow: Rotate shape
        \\Down Arrow: Soft drop shape
        \\Space: Hard drop shape
        \\c: Capture shape
        \\p: Pause
    );
    while (c.getch() != 27) {}
    _ = c.clear();
    return true;
}
