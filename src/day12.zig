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
    visited: bool,
    tested: bool,

    pub fn isEqual(self: *Point, p: *Point) bool {
        if (p.x == self.x and p.y == self.y) return true;
        return false;
    }

    pub fn validNeighbor(self: *Point, neigh: *Point) bool {
        if (neigh.visited) return false;
        if (neigh.tested) return false;
        if (neigh.elevation > self.elevation + 1) return false;

        var newDistance: u32 = self.distance.? + 1;
        if (neigh.distance == null or neigh.distance.? > newDistance) {
            neigh.distance = newDistance;
            return true;
        }
        return false;
    }
};

const Map = struct {
    width: usize,
    height: usize,
    map: [100][100]Point,
    start: *Point,
    end: *Point,
    predecessor: *Point,

    fn lessThan(context: void, a: *Point, b: *Point) std.math.Order {
        _ = context;
        var da: u32 = a.distance.?;
        var db: u32 = b.distance.?;
        return std.math.order(da, db);
    }

    pub fn Print(self: *Map, cur: *Point) void {
        print("\n----------\n", .{});
        var i: u16 = 0;
        var j: u16 = 0;

        while (i < self.height) : (i += 1) {
            while (j < self.width) : (j += 1) {
                var c = self.map[i][j].elevation;
                if (i == self.end.x and j == self.end.y) {
                    c = 'E';
                } else if (i == self.start.x and j == self.start.y) {
                    c = 'S';
                }
                print("{c}", .{c});
                if (self.map[i][j].isEqual(cur)) {
                    print("@", .{});
                    continue;
                }
                if (self.map[i][j].visited) {
                    print("*", .{});
                    continue;
                }
                print(" ", .{});
            }
            j = 0;
            print("\n", .{});
        }
        print("\n", .{});
    }

    pub fn init() !*Map {
        var m = try allocator.create(Map);
        m.width = 0;
        m.height = 0;

        return m;
    }

    pub fn nextNeighborsUpdate(self: *Map, cur: *Point, prio: *std.PriorityQueue(*Point, void, lessThan)) !void {
        var x = cur.x;
        var y = cur.y;

        if ((y < self.width - 1) and (cur.validNeighbor(&self.map[x][y + 1])))
            try prio.add(&self.map[x][y + 1]);
        if ((y > 0) and (cur.validNeighbor(&self.map[x][y - 1])))
            try prio.add(&self.map[x][y - 1]);
        if ((x > 0) and (cur.validNeighbor(&self.map[x - 1][y])))
            try prio.add(&self.map[x - 1][y]);
        if ((x < self.height - 1) and (cur.validNeighbor(&self.map[x + 1][y])))
            try prio.add(&self.map[x + 1][y]);
    }

    pub fn reinit(self: *Map) void {
        var i: usize = 0;
        var j: usize = 0;
        while (i < self.height) : (i += 1) {
            while (j < self.width) : (j += 1) {
                self.map[i][j].distance = null;
                self.map[i][j].visited = false;
            }
            j = 0;
        }
    }

    pub fn findShortestLen(self: *Map, start: *Point) !?u32 {
        self.reinit();
        start.distance = 0;
        var cpt: usize = 0;

        var prio = std.PriorityQueue(*Point, void, lessThan).init(allocator, undefined);
        defer prio.deinit();

        try prio.add(start);
        while (prio.removeOrNull()) |item| {
            if (item.visited) continue;
            if (self.end.isEqual(item)) {
                return item.distance.?;
            }
            cpt += 1;
            item.visited = true;
            try self.nextNeighborsUpdate(item, &prio);
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
            m.map[i][j].visited = false;
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
            if (m.map[i][j].elevation != 'a') continue;

            if (try m.findShortestLen(&m.map[i][j])) |res| {
                min = @min(min, res);
            }
            m.map[i][j].tested = true;
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
