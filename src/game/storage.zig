const std = @import("std");
const c = @cImport({
    @cInclude("ncurses.h");
    @cInclude("form.h");
});

const Score = struct {
    name: [3]u8 = [3]u8{ 'N', '/', 'A' },
    score: u64 = 0,
    mark: bool = false,
};

pub const Storage = struct {
    level: u16 = 1,
    scores: [5]Score = [_]Score{Score{}} ** 5,
    file_path: []u8 = undefined,
    pub fn init() Storage {
        var storage = Storage{};
        const home = std.posix.getenv("HOME") orelse return storage;
        const path = std.fs.path.join(
            std.heap.page_allocator,
            &[2][]const u8{ home, ".local/share/term-tetris" },
        ) catch return storage;
        std.fs.makeDirAbsolute(path) catch |e| {
            switch (e) {
                error.PathAlreadyExists => {},
                else => return storage,
            }
        };
        storage.file_path = std.fs.path.join(
            std.heap.page_allocator,
            &[2][]const u8{ path, "data" },
        ) catch return storage;
        storage.getStorage();
        return storage;
    }
    fn getFile(self: *Storage) ?std.fs.File {
        return std.fs.openFileAbsolute(
            self.file_path,
            .{ .mode = .read_write },
        ) catch |e| {
            switch (e) {
                error.FileNotFound => {
                    return std.fs.createFileAbsolute(
                        self.file_path,
                        .{},
                    ) catch return null;
                },
                else => return null,
            }
        };
    }
    fn writeStorage(self: *Storage, file: std.fs.File) void {
        const writer = file.writer();
        writer.writeInt(
            u16,
            self.level,
            std.builtin.Endian.big,
        ) catch return;
        inline for (0..5) |i| {
            writer.writeAll(&self.scores[i].name) catch return;
            writer.writeInt(
                u64,
                self.scores[i].score,
                std.builtin.Endian.big,
            ) catch return;
        }
    }
    pub fn getStorage(self: *Storage) void {
        const file = self.getFile() orelse return;
        defer file.close();
        const stat = file.stat() catch return;
        if (stat.size == 0) {
            self.writeStorage(file);
        } else {
            const reader = file.reader();
            self.level = reader.readInt(
                u16,
                std.builtin.Endian.big,
            ) catch return;
            inline for (0..5) |i| {
                self.scores[i].name = reader.readBytesNoEof(
                    3,
                ) catch return;
                self.scores[i].score = reader.readInt(
                    u64,
                    std.builtin.Endian.big,
                ) catch return;
            }
        }
    }
    fn cmp(_: @TypeOf(.{}), a: Score, b: Score) bool {
        return b.score < a.score;
    }
    pub fn setStorage(self: *Storage, score: bool) void {
        const file = self.getFile() orelse return;
        defer file.close();
        if (score) {
            self.scores[4].mark = true;
            std.mem.sort(Score, &self.scores, .{}, cmp);
            const win = c.newwin(8, 28, 5, 9);
            _ = c.box(win, 0, 0);
            _ = c.mvwaddstr(win, 1, 8, "High Scores");
            var fields: [6]?*c.FIELD = .{null} ** 6;
            var y: usize = 0;
            inline for (0..5) |i| {
                fields[i] = c.new_field(1, 3, @intCast(i + 1), 1, 0, 0);
                if (self.scores[i].mark) {
                    self.scores[i].mark = false;
                    y = i;
                    _ = c.set_field_back(fields[i], c.A_UNDERLINE);
                    _ = c.field_opts_off(fields[i], c.O_AUTOSKIP);
                } else _ = c.set_field_buffer(
                    fields[i],
                    0,
                    &self.scores[i].name,
                );
                _ = c.mvwprintw(
                    win,
                    @intCast(i + 2),
                    6,
                    "%lu",
                    self.scores[i].score,
                );
            }
            const form = c.new_form(&fields);
            _ = c.set_form_win(form, win);
            _ = c.set_form_sub(form, c.derwin(win, 6, 4, 1, 1));
            _ = c.set_current_field(form, fields[y]);
            _ = c.refresh();
            _ = c.post_form(form);
            _ = c.wrefresh(win);
            _ = c.curs_set(1);
            var cur: i3 = 0;
            var input: c_int = undefined;
            while (true) {
                input = c.getch();
                switch (input) {
                    10 => break,
                    c.KEY_BACKSPACE => {
                        if (0 < cur) {
                            _ = c.form_driver(
                                form,
                                if (cur == 3)
                                    c.REQ_DEL_CHAR
                                else
                                    c.REQ_DEL_PREV,
                            );
                            cur -= 1;
                        }
                    },
                    33...126 => {
                        if (cur == 3)
                            _ = c.form_driver(form, c.REQ_DEL_CHAR);
                        _ = c.form_driver(form, input);
                        if (cur < 3) cur += 1;
                    },
                    else => {},
                }
                _ = c.wrefresh(win);
            }
            _ = c.form_driver(form, c.REQ_VALIDATION);
            const buf = c.field_buffer(fields[y], 0);
            inline for (0..3) |i|
                self.scores[y].name[i] = buf[i];
            _ = c.curs_set(0);
            _ = c.delwin(win);
            _ = c.unpost_form(form);
            _ = c.free_form(form);
            _ = c.free_field(fields[0]);
        }
        self.writeStorage(file);
    }
};
