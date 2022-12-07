const std = @import("std");
const print = std.debug.print;
const mem = std.mem;
const fs = std.fs;
const fmt = std.fmt;
const cmdline = @import("libs/cmdline.zig");

const ArrayList = std.ArrayList;
const allocator = std.heap.page_allocator;

pub fn main() !void {
    const p = try cmdline.parse();

    const solution: u64 = switch (p.part) {
        1 => try testPart1(p.filename),
        2 => try testPart2(p.filename),
        else => {
            return error.InvalidArgs;
        },
    };
    print("Solution: {d}\n", .{solution});
}

const Cmd = enum(u8) {
    cd = 'c',
    ls = 'l',
};

const Type = enum {
    FileType,
    DirType,
};

const File = struct {
    fileType: Type,
    name: []u8,
    Parent: ?*File,
    Children: ArrayList(*File),
    fileSize: u64 = 0,

    pub fn Print(self: *File, prefix: u8) void {
        var i: u8 = 0;
        while (i < prefix) : (i += 1) {
            print(" ", .{});
        }
        switch (self.fileType) {
            Type.DirType => print("- {s} (dir) ( {d} )\n", .{ self.name, self.size() }),
            Type.FileType => print("- {s} (file, size={d})\n", .{ self.name, self.size() }),
        }
        for (self.Children.items) |dir| {
            dir.Print(prefix + 1);
        }
    }

    pub fn init(name: []const u8) !*File {
        var file = try allocator.create(File);
        file.Children = ArrayList(*File).init(allocator);
        file.name = try allocator.alloc(u8, name.len);
        mem.copy(u8, file.name, name);
        file.Parent = null;
        return file;
    }

    pub fn size(self: *File) u64 {
        var dirSize: u64 = 0;
        return switch (self.fileType) {
            Type.DirType => {
                for (self.Children.items) |f| {
                    dirSize += f.size();
                }
                return dirSize;
            },
            Type.FileType => self.fileSize,
        };
    }

    pub fn findAtMost100000(self: *File) u64 {
        if (self.fileType == Type.FileType) return 0;
        var total: u64 = 0;
        var mySize = self.size();
        if (self.size() <= 100000) {
            total += mySize;
        }

        for (self.Children.items) |dir| {
            if (self.fileType == Type.FileType) continue;
            total += dir.findAtMost100000();
        }
        return total;
    }

    pub fn findMinDirToDelete(self: *File, neededFreed: u64) u64 {
        var min: u64 = std.math.maxInt(u64);
        var mySize: u64 = self.size();
        if (mySize > neededFreed)
            min = mySize;
        for (self.Children.items) |d| {
            if (d.fileType == Type.FileType) continue;
            min = @min(min, d.findMinDirToDelete(neededFreed));
        }
        return min;
    }
};

pub fn parse(filename: []const u8) !?*File {
    var file = try fs.cwd().openFile(filename, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var buf: [50]u8 = undefined;
    var cmd: Cmd = Cmd.cd;
    var currentDir: ?*File = null;

    while (try in_stream.readUntilDelimiterOrEof(buf[0..], '\n')) |line| {
        var lastSpace = std.mem.lastIndexOf(u8, line, " ").?;
        if (line.len == 0) continue;
        switch (line[0]) {
            '$' => {
                // We are doing a command
                if (line.len < 3) continue;
                cmd = @intToEnum(Cmd, line[2]);
                switch (cmd) {
                    Cmd.cd => {
                        var name = line[(lastSpace + 1)..];
                        if (name[0] == '.') {
                            currentDir = currentDir.?.Parent;
                        } else {
                            var dir = try File.init(name);
                            dir.fileType = Type.DirType;

                            if (currentDir != null) try currentDir.?.Children.append(dir);

                            dir.Parent = currentDir;
                            currentDir = dir;
                        }
                    },
                    Cmd.ls => {},
                }
            },
            'd' => {
                // We are listing a dir
            },
            else => {
                // We are listing a file
                var size: u64 = try fmt.parseInt(u64, line[0..lastSpace], 10);
                var name = line[(lastSpace + 1)..];
                var f = try File.init(name);
                f.fileType = Type.FileType;
                f.fileSize = size;

                if (currentDir != null) try currentDir.?.Children.append(f);

                f.Parent = currentDir;
            },
        }
    }
    while (currentDir.?.Parent != null) {
        currentDir = currentDir.?.Parent;
    }
    // currentDir.?.Print(0);
    return currentDir;
}

pub fn testPart1(filename: []const u8) !u64 {
    var root = try parse(filename);
    return root.?.findAtMost100000();
}

pub fn testPart2(filename: []const u8) !u64 {
    var root = try parse(filename);

    var totalSpace: u64 = 70000000;
    var minSpace: u64 = 30000000;
    var totalUsed: u64 = root.?.size();
    var totalFree: u64 = totalSpace - totalUsed;
    var neededFreed: u64 = minSpace - totalFree;

    return root.?.findMinDirToDelete(neededFreed);
}

test "part-1: example input" {
    try std.testing.expectEqual(@as(u64, 95437), try testPart1("inputs/07/test-1"));
}

test "part-1: input" {
    try std.testing.expectEqual(@as(u64, 1449447), try testPart1("inputs/07/input"));
}

test "part-2: example input" {
    try std.testing.expectEqual(@as(u64, 24933642), try testPart2("inputs/07/test-1"));
}

test "part-2: input" {
    try std.testing.expectEqual(@as(u64, 8679207), try testPart2("inputs/07/input"));
}
