const std = @import("std");
const print = std.debug.print;
const mem = std.mem;
const fs = std.fs;
const fmt = std.fmt;
const cmdline = @import("libs/cmdline.zig");

const allocator = std.heap.page_allocator;

const max_size = 512;

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

const Point = struct {
    x: i16,
    y: i16,
    pub fn moveHoriz(self: *Point, sign: i8) void {
        self.x += sign;
    }
    pub fn moveVert(self: *Point, sign: i8) void {
        self.y += sign;
    }
};

const Direction = enum(u8) {
    Right = 'R',
    Left = 'L',
    Up = 'U',
    Down = 'D',
};

const Map = struct {
    len: u16,
    points: [max_size][max_size]u8,
    Head: Point,
    Tail: Point,
    map: std.AutoHashMap(Point, bool),
    // std.AutoHashMap(Point, bool)

    pub fn Print(self: *Map) void {
        print("\n----------\n", .{});
        var i: u16 = self.len - 1;
        var j: u16 = 0;
        while (i >= 0) : (i -= 1) {
            while (j < self.len) : (j += 1) {
                var cur: Point = .{
                    .x = @intCast(i16, i),
                    .y = @intCast(i16, j),
                };
                var c: u8 = self.points[i][j];
                if (i == 0 and j == 0) c = 's';
                if (std.meta.eql(cur, self.Tail)) c = 'T';
                if (std.meta.eql(cur, self.Head)) c = 'H';
                print("{c}", .{c});
            }
            print("\n", .{});
            j = 0;
            if (i == 0) break;
        }
    }

    pub fn init() !*Map {
        var m = try allocator.create(Map);
        m.len = max_size;
        m.points = [_][max_size]u8{[_]u8{'.'} ** max_size} ** max_size;
        m.Tail = .{
            .x = 128,
            .y = 128,
        };
        m.Head = .{
            .x = 128,
            .y = 128,
        };
        m.map = std.AutoHashMap(Point, bool).init(allocator);
        return m;
    }

    pub fn move(self: *Map, direction: Direction, distance: u8) !void {
        var i: u8 = 0;
        while (i < distance) : (i += 1) {
            self.moveHead(direction);
            // self.Print();
            try self.moveTail();
            // self.Print();
        }
    }

    pub fn moveHead(self: *Map, direction: Direction) void {
        switch (direction) {
            Direction.Up => self.Head.x += 1,
            Direction.Down => self.Head.x -= 1,
            Direction.Left => self.Head.y -= 1,
            Direction.Right => self.Head.y += 1,
        }
    }

    pub fn moveTail(self: *Map) !void {
        // Check if we need to move
        var distX: i16 = @as(i16, self.Head.x) - @as(i16, self.Tail.x);
        var distY: i16 = @as(i16, self.Head.y) - @as(i16, self.Tail.y);
        // Diagonal
        if (((try std.math.absInt(distX) >= 1) and (try std.math.absInt(distY) >= 1)) and (@max(try std.math.absInt(distY), try std.math.absInt(distX)) > 1)) {
            self.Tail.moveHoriz(getSign(distX));
            self.Tail.moveVert(getSign(distY));
        } else if (try std.math.absInt(distX) > 1) {
            self.Tail.moveHoriz(getSign(distX));
        } else if (try std.math.absInt(distY) > 1) {
            self.Tail.moveVert(getSign(distY));
        }
        self.points[@intCast(usize, self.Tail.x)][@intCast(usize, self.Tail.y)] = '#';
        var p: Point = .{ .x = self.Tail.x, .y = self.Tail.y };
        try self.map.put(p, true);
        return;
    }

    pub fn countTailVisited(self: *Map) u64 {
        return self.map.count();
    }
};

pub fn getSign(x: i16) i8 {
    if (x == 0) return 0;
    if (x > 0) {
        return 1;
    } else {
        return -1;
    }
}

pub fn parse(filename: []const u8) !?*Map {
    var file = try fs.cwd().openFile(filename, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var buf: [5]u8 = undefined;
    var m: ?*Map = try Map.init();

    while (try in_stream.readUntilDelimiterOrEof(buf[0..], '\n')) |line| {
        // m.?.Print();
        var direction: Direction = @intToEnum(Direction, line[0]);
        var lastSpace = std.mem.lastIndexOf(u8, line, " ").?;
        var distance: u8 = try fmt.parseInt(u8, line[lastSpace + 1 ..], 10);
        try m.?.move(direction, distance);
    }

    return m;
}

pub fn testPart1(filename: []const u8) !u64 {
    var map = try parse(filename);
    // map.?.Print();
    return map.?.countTailVisited();
}

pub fn testPart2(filename: []const u8) !u64 {
    var map = try parse(filename);
    return map.?.countTailVisited();
}

test "part-1: example input" {
    try std.testing.expectEqual(@as(u64, 13), try testPart1("inputs/09/test-1"));
}

test "part-1: input" {
    try std.testing.expectEqual(@as(u64, 6044), try testPart1("inputs/09/input"));
}

// test "part-2: example input" {
//     try std.testing.expectEqual(@as(u64, 8), try testPart2("inputs/09/test-1"));
// }
//
// test "part-2: input" {
//     try std.testing.expectEqual(@as(u64, 211680), try testPart2("inputs/09/input"));
// }
