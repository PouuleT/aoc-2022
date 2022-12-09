const std = @import("std");
const print = std.debug.print;
const mem = std.mem;
const fs = std.fs;
const fmt = std.fmt;
const cmdline = @import("libs/cmdline.zig");

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

const Map = struct {
    len: usize,
    trees: [100][100]u8,

    pub fn Print(self: *Map) void {
        print("----------\n", .{});
        var i: usize = 0;
        var j: usize = 0;
        while (i < self.len) : (i += 1) {
            while (j < self.len) : (j += 1) {
                print("{c}", .{self.trees[i][j]});
            }
            print("\n", .{});
            j = 0;
        }
    }

    pub fn init() !*Map {
        var m = try allocator.create(Map);
        m.len = 0;
        m.trees = [_][100]u8{[_]u8{' '} ** 100} ** 100;
        return m;
    }

    pub fn findVisibleTrees(self: *Map) !u64 {
        // Initialize the visible trees with the trees on the edge
        var tmpMap: *Map = try Map.init();
        tmpMap.len = self.len;

        // On each line
        var i: usize = 0;
        var j: usize = 0;
        var max: u64 = 0;
        while (i < self.len) : (i += 1) {
            // Look from left to right
            max = 0;
            while (j < self.len) : (j += 1) {
                if (tmpMap.trees[i][j] != 'V') {
                    if ((i == 0) or (j == 0)) {
                        tmpMap.trees[i][j] = 'V';
                    }
                    if (self.trees[i][j] > max) {
                        tmpMap.trees[i][j] = 'V';
                    }
                }
                max = @max(max, self.trees[i][j]);
            }
            // Look from right to left
            j = self.len - 1;
            max = 0;
            while (j > 0) : (j -= 1) {
                if (tmpMap.trees[i][j] != 'V') {
                    if ((j == self.len - 1) or (i == self.len - 1)) {
                        tmpMap.trees[i][j] = 'V';
                    }
                    if (self.trees[i][j] > max) {
                        tmpMap.trees[i][j] = 'V';
                    }
                }
                max = @max(max, self.trees[i][j]);
            }
            j = 0;
        }

        // On each column
        j = 0;
        while (j < self.len) : (j += 1) {
            // Look from top to bottom
            max = 0;
            while (i < self.len) : (i += 1) {
                if (tmpMap.trees[i][j] != 'V') {
                    if ((i == 0) or (j == 0)) {
                        tmpMap.trees[i][j] = 'V';
                    }
                    if (self.trees[i][j] > max) {
                        tmpMap.trees[i][j] = 'V';
                    }
                }
                max = @max(max, self.trees[i][j]);
            }
            // Look from bottom to top
            i = self.len - 1;
            max = 0;
            while (i > 0) : (i -= 1) {
                if (tmpMap.trees[i][j] != 'V') {
                    if ((j == self.len - 1) or (i == self.len - 1)) {
                        tmpMap.trees[i][j] = 'V';
                    }
                    if (self.trees[i][j] > max) {
                        tmpMap.trees[i][j] = 'V';
                    }
                }
                max = @max(max, self.trees[i][j]);
            }
            i = 0;
        }
        return tmpMap.countVisibleTrees();
    }

    pub fn computeScenicScore(self: *Map, x: usize, y: usize) !u64 {
        var height: u64 = self.trees[x][y];
        // Look UP
        var i: usize = x - 1;
        var j: usize = y;
        var up: u64 = 0;
        while (i >= 0) : (i -= 1) {
            up += 1;
            if (self.trees[i][j] >= height) break;
            if (i == 0) break;
        }

        // Look DOWN
        i = x + 1;
        j = y;
        var down: u64 = 0;
        while (i < self.len) : (i += 1) {
            down += 1;
            if (self.trees[i][j] >= height) break;
        }

        // Look LEFT
        i = x;
        j = y - 1;
        var left: u64 = 0;
        while (j >= 0) : (j -= 1) {
            left += 1;
            if (self.trees[i][j] >= height) break;
            if (j == 0) break;
        }

        // Look RIGHT
        i = x;
        j = y + 1;
        var right: u64 = 0;
        while (j < self.len) : (j += 1) {
            right += 1;
            if (self.trees[i][j] >= height) break;
        }
        return up * down * left * right;
    }

    pub fn getIdealSpot(self: *Map) !u64 {
        var i: usize = 0;
        var j: usize = 0;
        var max: u64 = 0;
        while (i < self.len) : (i += 1) {
            while (j < self.len) : (j += 1) {
                if ((i == 0) or (j == 0) or (i == self.len - 1) or (j == self.len - 1)) continue;
                max = @max(max, try self.computeScenicScore(i, j));
            }
            j = 0;
        }

        return max;
    }

    pub fn countVisibleTrees(self: *Map) u64 {
        var i: usize = 0;
        var j: usize = 0;
        var max: u64 = 0;
        while (i < self.len) : (i += 1) {
            while (j < self.len) : (j += 1) {
                if (self.trees[i][j] == 'V') max += 1;
            }
            j = 0;
        }
        return max;
    }
};

pub fn parse(filename: []const u8) !?*Map {
    var file = try fs.cwd().openFile(filename, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var buf: [100]u8 = undefined;
    var m: ?*Map = null;
    m = try Map.init();
    var i: u8 = 0;

    while (try in_stream.readUntilDelimiterOrEof(buf[0..], '\n')) |line| {
        if (m.?.len == 0) m.?.len = line.len;
        mem.copy(u8, &m.?.trees[i], line);
        i += 1;
    }

    return m;
}

pub fn testPart1(filename: []const u8) !u64 {
    var map = try parse(filename);
    return try map.?.findVisibleTrees();
}

pub fn testPart2(filename: []const u8) !u64 {
    var map = try parse(filename);
    return try map.?.getIdealSpot();
}

test "part-1: example input" {
    try std.testing.expectEqual(@as(u64, 21), try testPart1("inputs/08/test-1"));
}

test "part-1: input" {
    try std.testing.expectEqual(@as(u64, 1823), try testPart1("inputs/08/input"));
}

test "part-2: example input" {
    try std.testing.expectEqual(@as(u64, 8), try testPart2("inputs/08/test-1"));
}

test "part-2: input" {
    try std.testing.expectEqual(@as(u64, 211680), try testPart2("inputs/08/input"));
}
