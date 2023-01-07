const std = @import("std");
const print = std.debug.print;
const mem = std.mem;
const fs = std.fs;
const fmt = std.fmt;
const cmdline = @import("libs/cmdline.zig");
var allocator: mem.Allocator = undefined;

pub fn main() !void {
    const p = try cmdline.parse();

    allocator = std.heap.page_allocator;
    const solution: u32 = switch (p.part) {
        1 => try solvePart1(p.filename),
        2 => try solvePart2(p.filename),
        else => {
            return error.InvalidArgs;
        },
    };
    print("Solution: {d}\n", .{solution});
}

const Map = struct {
    minY: u32 = 0,
    maxY: u32 = 0,
    maxX: u32 = 0,
    map: [800][200]u8,

    pub fn init() !*Map {
        var m = try allocator.create(Map);
        m.minY = 800;
        m.maxY = 0;
        m.maxX = 0;
        var i: usize = 0;
        while (i < 200) : (i += 1) {
            var j: usize = 0;
            while (j < 800) : (j += 1) {
                m.map[j][i] = '.';
            }
        }
        return m;
    }

    pub fn deinit(self: *Map) void {
        allocator.destroy(self);
    }

    pub fn Print(self: *Map) void {
        print("Min: {d}, Max: {d}\n", .{ self.minY, self.maxY });
        var i: usize = 0;
        while (i <= self.maxX) : (i += 1) {
            print("{d} - ", .{i});
            var j: usize = self.minY;
            while (j <= self.maxY) : (j += 1) {
                print("{c}", .{self.map[j][i]});
            }
            print("\n", .{});
        }
    }

    pub fn rock(self: *Map, x: usize, y: usize) void {
        self.map[y][x] = '#';
    }

    pub fn move(self: *Map, p: Point) Point {
        // Check if we can simply go down
        if (self.map[p.y][p.x + 1] == '.') {
            self.map[p.y][p.x] = '.';
            self.map[p.y][p.x + 1] = 'o';

            return Point{
                .x = p.x + 1,
                .y = p.y,
            };
        } else if (self.map[p.y - 1][p.x + 1] == '.') {
            self.map[p.y][p.x] = '.';
            self.map[p.y - 1][p.x + 1] = 'o';

            return Point{
                .x = p.x + 1,
                .y = p.y - 1,
            };
        } else if (self.map[p.y + 1][p.x + 1] == '.') {
            self.map[p.y][p.x] = '.';
            self.map[p.y + 1][p.x + 1] = 'o';

            return Point{
                .x = p.x + 1,
                .y = p.y + 1,
            };
        } else {
            return Point{
                .x = p.x,
                .y = p.y,
            };
        }
    }

    pub fn sendSand(self: *Map, x: u32, y: u32) bool {
        self.map[y][x] = '+';
        var p: Point = .{
            .x = x,
            .y = y,
        };
        var tmp: Point = undefined;
        while (true) {
            if (p.x > self.maxX) {
                return false;
            }
            tmp = self.move(p);
            if (tmp.x == p.x and tmp.y == p.y) {
                break;
            }
            p = tmp;
        }
        return true;
    }

    pub fn sendSand2(self: *Map, x: u32, y: u32) bool {
        var p: Point = .{
            .x = x,
            .y = y,
        };
        var tmp: Point = undefined;
        while (true) {
            tmp = self.move(p);
            if (tmp.x == p.x and tmp.y == p.y) {
                break;
            }
            p = tmp;
        }
        if (p.x == 0) {
            return false;
        }
        return true;
    }
};

const Point = struct {
    x: u32 = 0,
    y: u32 = 0,
};

pub fn parse(filename: []const u8) !*Map {
    var file = try fs.cwd().openFile(filename, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var m: *Map = try Map.init();
    var buf: [500]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var splits = std.mem.split(u8, line, " -> ");

        var previous: ?Point = null;
        while (splits.next()) |s| {
            var found = std.mem.indexOf(u8, s, ",").?;
            var current: Point = .{
                .x = try fmt.parseInt(u32, s[found + 1 ..], 10),
                .y = try fmt.parseInt(u32, s[0..found], 10),
            };
            m.minY = @min(m.minY, current.y);
            m.maxY = @max(m.maxY, current.y);
            m.maxX = @max(m.maxX, current.x);
            if (previous) |p| {
                var i: usize = @min(p.x, current.x);
                while (i <= @max(p.x, current.x)) : (i += 1) {
                    var j: usize = @min(p.y, current.y);
                    while (j <= @max(p.y, current.y)) : (j += 1) {
                        m.rock(i, j);
                    }
                }
            }
            previous = current;
        }
    }
    return m;
}

pub fn solvePart1(filename: []const u8) !u32 {
    var m = try parse(filename);
    // m.Print();

    var i: u32 = 0;
    while (m.sendSand(0, 500)) : (i += 1) {
        // m.Print();
    }

    return i;
}

pub fn solvePart2(filename: []const u8) !u32 {
    var m = try parse(filename);
    m.maxX = m.maxX + 2;
    var i: u32 = 0;
    while (i < 800) : (i += 1) {
        m.rock(m.maxX, i);
    }
    // m.Print();

    i = 0;
    while (m.sendSand2(0, 500)) : (i += 1) {
        // m.Print();
    }

    return i + 1;
}

test "part-1: example input" {
    allocator = std.heap.page_allocator;
    try std.testing.expectEqual(@as(u64, 24), try solvePart1("inputs/14/test-1"));
}

test "part-1: input" {
    allocator = std.heap.page_allocator;
    try std.testing.expectEqual(@as(u64, 805), try solvePart1("inputs/14/input"));
}

test "part-2: example input" {
    allocator = std.heap.page_allocator;
    try std.testing.expectEqual(@as(u64, 93), try solvePart2("inputs/14/test-1"));
}

test "part-2: input" {
    allocator = std.heap.page_allocator;
    try std.testing.expectEqual(@as(u64, 25161), try solvePart2("inputs/14/input"));
}
