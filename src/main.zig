const std = @import("std");
const Bag = @import("game/bag.zig");
const Board = @import("game/board.zig");
const Hold = @import("game/hold.zig");
const Meta = @import("game/meta.zig");
const Next = @import("game/next.zig");
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
    c.ESCDELAY = 0;
    _ = c.setlocale(c.LC_ALL, "");
    _ = c.initscr();
    _ = c.noecho();
    _ = c.curs_set(0);
    _ = c.keypad(c.stdscr, true);
    _ = c.start_color();
    _ = c.use_default_colors();
    _ = c.init_pair(1, c.COLOR_RED, c.COLOR_RED);
    _ = c.init_pair(2, 214, 214);
    _ = c.init_pair(3, c.COLOR_YELLOW, c.COLOR_YELLOW);
    _ = c.init_pair(4, c.COLOR_GREEN, c.COLOR_GREEN);
    _ = c.init_pair(5, c.COLOR_CYAN, c.COLOR_CYAN);
    _ = c.init_pair(6, c.COLOR_BLUE, c.COLOR_BLUE);
    _ = c.init_pair(7, c.COLOR_MAGENTA, c.COLOR_MAGENTA);
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
    _ = c.mvaddstr(0, 0,
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
    _ = c.delwin(win);
    inline for (items) |item| _ = c.free_item(item);
    return state;
}

fn play() Display {
    _ = c.refresh();
    var bag = Bag.Bag.init();
    var board = Board.Board.init();
    var hold = Hold.Hold.init();
    var meta = Meta.Meta.init();
    var next = Next.Next.init();
    var input: c_int = undefined;
    var shape: Bag.Shape = undefined;
    while (input != 27) {
        input = c.getch();
        shape = bag.grab();
        next.draw(shape);
    }
    board.deinit();
    hold.deinit();
    meta.deinit();
    next.deinit();
    return Display.start;
}

fn help() Display {
    _ = c.mvaddstr(0, 0,
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
