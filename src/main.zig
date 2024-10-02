const std = @import("std");
const bag = @import("bag.zig");
const c = @cImport({
    @cInclude("ncurses.h");
    @cInclude("menu.h");
    @cInclude("locale.h");
});

const Display = enum {
    exit,
    help,
    play,
    start,
};

pub fn main() !void {
    _ = c.setlocale(c.LC_ALL, "");
    _ = c.initscr();
    _ = c.noecho();
    _ = c.keypad(c.stdscr, true);
    _ = c.curs_set(0);
    c.ESCDELAY = 0;
    var state = Display.start;
    while (true) {
        state = switch (state) {
            Display.help => help(),
            Display.play => play(),
            Display.exit => break,
            Display.start => start(),
        };
        _ = c.clear();
    }
    _ = c.endwin();
}

fn start() Display {
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
    const choices = &[_][*c]const u8{ "Play", "Help", "Quit" };
    var items: []?*c.ITEM = undefined;
    if (std.heap.page_allocator.alloc(?*c.ITEM, choices.len)) |new_items| {
        items = new_items;
    } else |_| return Display.exit;
    defer std.heap.page_allocator.free(items);
    inline for (choices, 0..) |choice, i| items[i] = c.new_item(choice, null).?;
    const menu = c.new_menu(items.ptr);
    const win = c.newwin(choices.len + 2, 8, 12, 19);
    _ = c.set_menu_win(menu, win);
    _ = c.set_menu_sub(menu, c.derwin(win, choices.len, 8, 1, 0));
    _ = c.post_menu(menu);
    _ = c.refresh();
    var input: c_int = undefined;
    const state = while (true) {
        _ = c.wrefresh(win);
        input = c.getch();
        switch (input) {
            10 => {
                switch (c.item_index(c.current_item(menu).?)) {
                    0 => return Display.play,
                    1 => return Display.help,
                    2 => return Display.exit,
                    else => {},
                }
            },
            106, c.KEY_DOWN => _ = c.menu_driver(menu, c.REQ_DOWN_ITEM),
            107, c.KEY_UP => _ = c.menu_driver(menu, c.REQ_UP_ITEM),
            else => {},
        }
    };
    _ = c.unpost_menu(menu);
    _ = c.free_menu(menu);
    inline for (items) |item| _ = c.free_item(item);
    return state;
}

fn play() Display {
    const board = c.newwin(22, 21, 0, 12);
    _ = c.wprintw(board,
        \\ #.#.#.#.#.#.#.#.#.#
        \\ #.#.#.#.#.#.#.#.#.#
        \\ #.#.#.#.#.#.#.#.#.#
        \\ #.#.#.#.#.#.#.#.#.#
        \\ #.#.#.#.#.#.#.#.#.#
        \\ #.#.#.#.#.#.#.#.#.#
        \\ #.#.#.#.#.#.#.#.#.#
        \\ #.#.#.#.#.#.#.#.#.#
        \\ #.#.#.#.#.#.#.#.#.#
        \\ #.#.#.#.#.#.#.#.#.#
        \\ #.#.#.#.#.#.#.#.#.#
        \\ #.#.#.#.#.#.#.#.#.#
        \\ #.#.#.#.#.#.#.#.#.#
        \\ #.#.#.#.#.#.#.#.#.#
        \\ #.#.#.#.#.#.#.#.#.#
        \\ #.#.#.#.#.#.#.#.#.#
        \\ #.#.#.#.#.#.#.#.#.#
        \\ #.#.#.#.#.#.#.#.#.#
        \\ #.#.#.#.#.#.#.#.#.#
        \\ #.#.#.#.#.#.#.#.#.#
        \\ #.#.#.#.#.#.#.#.#.#
    );
    _ = c.box(board, 0, 0);
    const hold = c.newwin(5, 12, 0, 0);
    _ = c.box(hold, 0, 0);
    _ = c.mvwprintw(hold, 1, 1, "HOLD");
    const next = c.newwin(5, 12, 5, 0);
    _ = c.mvwprintw(next, 1, 1, "NEXT");
    _ = c.box(next, 0, 0);
    const meta = c.newwin(8, 12, 14, 0);
    _ = c.mvwprintw(meta, 1, 1,
        \\SCORE
        \\ 2147483647
        \\ LEVEL
        \\
        \\ LINES
    );
    _ = c.box(meta, 0, 0);
    _ = c.refresh();
    _ = c.wrefresh(board);
    _ = c.wrefresh(hold);
    _ = c.wrefresh(next);
    _ = c.wrefresh(meta);
    var input: c_int = undefined;
    var bg = bag.Bag.init();
    while (input != 27) {
        input = c.getch();
        _ = c.mvwprintw(next, 2, 4, "    ");
        _ = c.mvwprintw(next, 3, 4, "   ");
        switch (bg.grab()) {
            .I => _ = c.mvwprintw(next, 2, 4, "####"),
            .J => {
                _ = c.mvwprintw(next, 2, 4, "#");
                _ = c.mvwprintw(next, 3, 4, "###");
            },
            .L => _ = {
                _ = c.mvwprintw(next, 2, 6, "#");
                _ = c.mvwprintw(next, 3, 4, "###");
            },
            .O => {
                _ = c.mvwprintw(next, 2, 4, "##");
                _ = c.mvwprintw(next, 3, 4, "##");
            },
            .S => _ = {
                _ = c.mvwprintw(next, 2, 5, "##");
                _ = c.mvwprintw(next, 3, 4, "##");
            },
            .T => _ = {
                _ = c.mvwprintw(next, 2, 5, "#");
                _ = c.mvwprintw(next, 3, 4, "###");
            },
            .Z => _ = {
                _ = c.mvwprintw(next, 2, 4, "##");
                _ = c.mvwprintw(next, 3, 5, "##");
            },
        }
        _ = c.box(next, 0, 0);
        _ = c.wrefresh(next);
    }
    return Display.start;
}

fn help() Display {
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
    return Display.start;
}
