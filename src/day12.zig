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

const Point = struct {
    x: usize,
    y: usize,
    elevation: u8,
    distance: ?u32,
};

const Map = struct {
    width: usize,
    height: usize,
    map: [100][100]Point,
    cur: *Point,
    start: *Point,
    end: *Point,
    predecessor: *Point,
    prio: std.PriorityQueue(*Point, void, lessThan),

    fn lessThan(context: void, a: *Point, b: *Point) std.math.Order {
        _ = context;
        var da: u32 = a.distance.?;
        var db: u32 = b.distance.?;
        return std.math.order(da, db);
    }

    pub fn Print(self: *Map) void {
        print("\n----------\n", .{});
        var i: u16 = 0;
        var j: u16 = 0;
        print("Width: {d} Height: {d}\n", .{ self.width, self.height });
        print("Start: {d},{d}\n", .{ self.start.x, self.start.y });
        print("End: {d},{d}\n", .{ self.end.x, self.end.y });
        print("Current: {d},{d}\n", .{ self.cur.x, self.cur.y });
        print("Map:\n", .{});
        while (i < self.height) : (i += 1) {
            while (j < self.width) : (j += 1) {
                var c = self.map[i][j].elevation;
                if (i == self.cur.x and j == self.cur.y) {
                    print("{c}*", .{c});
                    continue;
                }
                if (i == self.end.x and j == self.end.y) {
                    c = 'E';
                } else if (i == self.start.x and j == self.start.y) {
                    c = 'S';
                }
                print("{c} ", .{c});
            }
            j = 0;
            print("\n", .{});
        }
    }

    pub fn init() !*Map {
        var m = try allocator.create(Map);
        m.width = 0;
        m.height = 0;
        m.prio = std.PriorityQueue(*Point, void, lessThan).init(allocator, undefined);

        return m;
    }

    pub fn isFinished(self: Map) bool {
        if (self.cur.x == self.end.x and self.cur.y == self.end.y) return true;
        return false;
    }

    pub fn next(self: *Map) *Point {
        return self.prio.remove();
    }

    pub fn nextNeighbors(self: *Map) ![]*Point {
        var neighbors: std.ArrayList(*Point) = std.ArrayList(*Point).init(allocator);
        var x = self.cur.x;
        var y = self.cur.y;
        var val = self.cur.elevation;

        if (x > 0) {
            if (self.map[x - 1][y].elevation <= val + 1)
                try neighbors.append(&self.map[x - 1][y]);
        }
        if (x < self.height - 1) {
            if (self.map[x + 1][y].elevation <= val + 1)
                try neighbors.append(&self.map[x + 1][y]);
        }
        if (y > 0) {
            if (self.map[x][y - 1].elevation <= val + 1)
                try neighbors.append(&self.map[x][y - 1]);
        }
        if (y < self.width - 1) {
            if (self.map[x][y + 1].elevation <= val + 1)
                try neighbors.append(&self.map[x][y + 1]);
        }

        return neighbors.items;
    }

    pub fn reinit(self: *Map) void {
        while (self.prio.removeOrNull() != null) {
            continue;
        }
        var i: usize = 0;
        var j: usize = 0;
        while (i < self.height) : (i += 1) {
            while (j < self.width) : (j += 1) {
                self.map[i][j].distance = null;
            }
            j = 0;
        }
    }

    pub fn findShortestLen(self: *Map, start: *Point) !?u32 {
        self.reinit();
        self.cur = start;
        self.cur.distance = 0;

        try self.prio.add(start);
        while (!self.isFinished()) {
            if (self.prio.count() == 0) {
                break;
            }
            self.cur = self.next();
            for (try self.nextNeighbors()) |n| {
                var newDistance: u32 = self.cur.distance.? + 1;
                if (n.distance == null or n.distance.? > newDistance) {
                    n.distance = newDistance;
                    try self.prio.add(n);
                }
            }
        } else {
            return self.end.distance.?;
        }

        return null;
    }
};

pub fn parse(filename: []const u8) !?*Map {
    var file = try fs.cwd().openFile(filename, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var buf: [80]u8 = undefined;
    var i: u8 = 0;
    var j: u8 = 0;
    var m = try Map.init();

    while (try in_stream.readUntilDelimiterOrEof(buf[0..], '\n')) |line| {
        if (m.width == 0) m.width = line.len;
        while (j < m.width) : (j += 1) {
            m.map[i][j].elevation = line[j];
            m.map[i][j].x = i;
            m.map[i][j].y = j;
            m.map[i][j].distance = null;
            switch (m.map[i][j].elevation) {
                'E' => {
                    m.map[i][j].elevation = 'z';
                    m.end = &m.map[i][j];
                },
                'S' => {
                    m.map[i][j].elevation = 'a';
                    m.map[i][j].distance = 0;
                    m.start = &m.map[i][j];
                },
                else => {},
            }
        }
        j = 0;
        i += 1;
    }
    m.height = i;

    return m;
}

pub fn testPart1(filename: []const u8) !u64 {
    var map = try parse(filename);
    var m = map.?;
    // m.Print();
    if (try m.findShortestLen(m.start)) |res| {
        return res;
    }
    return 0;
}

pub fn testPart2(filename: []const u8) !u64 {
    var map = try parse(filename);
    var m = map.?;
    // m.Print();
    var i: usize = 0;
    var j: usize = 0;
    var min: u32 = std.math.maxInt(u32);
    while (i < m.height) : (i += 1) {
        while (j < m.width) : (j += 1) {
            if (m.map[i][j].elevation == 'a') {
                if (try m.findShortestLen(&m.map[i][j])) |res| {
                    min = @min(min, res);
                }
            }
        }
        j = 0;
    }
    return min;
}

test "part-1: example input" {
    try std.testing.expectEqual(@as(u64, 31), try testPart1("inputs/12/test-1"));
}

test "part-1: input" {
    try std.testing.expectEqual(@as(u64, 352), try testPart1("inputs/12/input"));
}

test "part-2: example input" {
    try std.testing.expectEqual(@as(u64, 29), try testPart2("inputs/12/test-1"));
}

test "part-2: input" {
    try std.testing.expectEqual(@as(u64, 345), try testPart2("inputs/12/input"));
}
