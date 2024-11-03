const std = @import("std");

const Score = struct {
    name: [3]u8 = [3]u8{ 'N', '/', 'A' },
    score: u64 = 0,
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
        if (score) std.mem.sort(Score, &self.scores, .{}, cmp);
        self.writeStorage(file);
    }
};
