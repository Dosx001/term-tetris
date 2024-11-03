const std = @import("std");
const Bag = @import("game/bag.zig");
const Board = @import("game/board.zig");
const Hold = @import("game/hold.zig");
const Logic = @import("game/logic.zig");
const Meta = @import("game/meta.zig");
const Next = @import("game/next.zig");
const Storage = @import("game/storage.zig");
const c = @cImport({
    @cInclude("ncurses.h");
    @cInclude("menu.h");
    @cInclude("locale.h");
});

const Display = enum {
    Exit,
    Help,
    Play,
    PlayMenu,
    Start,
};

const GameLoop = enum { Exit, Lost, Playing };

pub const Spin = enum { None, Normal, Mini, Full };

pub fn main() !void {
    c.ESCDELAY = 0;
    _ = c.setlocale(c.LC_ALL, "C.utf8");
    _ = c.initscr();
    _ = c.noecho();
    _ = c.curs_set(0);
    _ = c.keypad(c.stdscr, true);
    _ = c.start_color();
    _ = c.use_default_colors();
    _ = c.init_pair(1, 0, c.COLOR_RED);
    _ = c.init_pair(2, 0, 208);
    _ = c.init_pair(3, 0, c.COLOR_YELLOW);
    _ = c.init_pair(4, 0, c.COLOR_GREEN);
    _ = c.init_pair(5, 0, c.COLOR_CYAN);
    _ = c.init_pair(6, 0, c.COLOR_BLUE);
    _ = c.init_pair(7, 0, c.COLOR_MAGENTA);
    var state = Display.Start;
    while (true) {
        state = switch (state) {
            Display.Exit => break,
            Display.Help => help(),
            Display.PlayMenu => play_menu(),
            Display.Play => play(),
            Display.Start => start(),
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
    } else |_| return Display.Exit;
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
                    0 => return Display.PlayMenu,
                    1 => return Display.Help,
                    2 => return Display.Exit,
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

fn play_menu() Display {
    _ = c.refresh();
    const win = c.newwin(8, 28, 5, 7);
    _ = c.box(win, 0, 0);
    _ = c.mvwaddstr(win, 1, 8, "High Scores");
    var storage = Storage.Storage.init();
    inline for (0..5) |i|
        _ = c.mvwprintw(
            win,
            @intCast(i + 2),
            2,
            "%s %lu",
            &storage.scores[i].name,
            storage.scores[i].score,
        );
    _ = c.wrefresh(win);
    _ = c.mvprintw(13, 0,
        \\         Press Enter to start
        \\         Press j/k to -/+1 level
        \\               Level: %i
    , storage.level);
    while (true) {
        switch (c.getch()) {
            10 => {
                _ = c.delwin(win);
                return Display.Play;
            },
            27, 113 => {
                _ = c.delwin(win);
                return Display.Start;
            },
            106 => {
                if (1 < storage.level) {
                    storage.level -= 1;
                    storage.setStorage(false);
                }
            },
            107 => {
                if (storage.level < 20) {
                    storage.level += 1;
                    storage.setStorage(false);
                }
            },
            else => continue,
        }
        _ = c.mvprintw(15, 22, "%i ", storage.level);
    }
}

fn play() Display {
    _ = c.nodelay(c.stdscr, true);
    _ = c.refresh();
    var bag = Bag.Bag.init();
    var board = Board.Board.init();
    var hold = Hold.Hold.init();
    var storage = Storage.Storage.init();
    var meta = Meta.Meta.init(storage.level);
    var next = Next.Next.init(&bag);
    var display = Display.Start;
    var allow = true;
    var input: c_int = undefined;
    var shape: Bag.Shape = .Empty;
    var state: [24][10]Board.Color = [_][10]Board.Color{[_]Board.Color{Board.Color.Black} ** 10} ** 24;
    var spin: Spin = .None;
    var gameloop: GameLoop = .Playing;
    var logic = Logic.Logic.init(storage.level);
    while (gameloop == .Playing) {
        if (shape == .Empty) {
            allow = true;
            if (meta.refresh(&state, &spin)) logic.updateInterval(meta.level);
            shape = next.draw(bag.grab());
            if (logic.insert(shape, &state)) gameloop = .Lost;
            board.colorGhost(shape);
            board.draw(&state);
        }
        meta.checkSpin(&spin);
        input = c.getch();
        if (input != c.ERR) {
            switch (input) {
                c.KEY_LEFT => logic.left(&state),
                c.KEY_RIGHT => logic.right(&state),
                c.KEY_UP => spin = logic.rotate(&state, shape, true),
                c.KEY_DOWN => {
                    if (logic.down(&state)) shape = .Empty;
                    meta.updateScore(1);
                },
                27, 113 => gameloop = .Exit,
                32 => {
                    meta.updateScore(logic.harddrop(&state));
                    shape = .Empty;
                },
                99 => {
                    if (allow) {
                        allow = false;
                        logic.delete(&state);
                        logic.deleteGhost(&state);
                        shape = hold.capture(shape);
                        if (shape == .Empty) shape = next.draw(bag.grab());
                        if (logic.insert(shape, &state)) gameloop = .Lost;
                        board.colorGhost(shape);
                    }
                },
                112 => {
                    _ = c.nodelay(c.stdscr, false);
                    while (c.getch() != 112) {}
                    board.animate(&state);
                    _ = c.nodelay(c.stdscr, true);
                    logic.now = std.time.milliTimestamp();
                },
                114 => {
                    display = Display.Play;
                    gameloop = .Exit;
                },
                122 => spin = logic.rotate(&state, shape, false),
                else => {},
            }
            board.draw(&state);
        }
        if (logic.update()) {
            if (logic.down(&state)) shape = .Empty;
            board.draw(&state);
        }
    }
    _ = c.nodelay(c.stdscr, false);
    if (gameloop == .Lost) {
        board.animate(&state);
        if (storage.scores[4].score < meta.score) {
            storage.scores[4].score = meta.score;
            storage.setStorage(true);
        }
        if (c.getch() == 114) display = Display.Play;
    }
    board.deinit();
    hold.deinit();
    meta.deinit();
    next.deinit();
    return display;
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
    return Display.Start;
}
