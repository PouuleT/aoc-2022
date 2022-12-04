const std = @import("std");
const print = std.debug.print;
const mem = std.mem;
const fs = std.fs;
const fmt = std.fmt;
const cmdline = @import("libs/cmdline.zig");

pub fn main() !void {
    const p = try cmdline.parse();

    const solution: u32 = switch (p.part) {
        1 => try testPart1(p.filename),
        2 => try testPart2(p.filename),
        else => {
            return error.InvalidArgs;
        },
    };
    print("Solution: {d}\n", .{solution});
}

const Pair = struct {
    first: [2]u8 = undefined,
    second: [2]u8 = undefined,

    pub fn fullyContained(self: *Pair) u8 {
        if (self.first[0] >= self.second[0] and self.first[1] <= self.second[1]) {
            return 1;
        }
        if (self.first[0] <= self.second[0] and self.first[1] >= self.second[1]) {
            return 1;
        }
        return 0;
    }
    pub fn overlaps(self: *Pair) u8 {
        if (self.first[1] < self.second[0] or
            self.second[1] < self.first[0])
            return 0;
        return 1;
    }
};

pub fn parseRange(p: *[2]u8, range: []const u8) !void {
    var found = std.mem.indexOf(u8, range, "-").?;
    var first = range[0..found];
    var second = range[(found + 1)..];
    p[0] = try fmt.parseInt(u8, first, 10);
    p[1] = try fmt.parseInt(u8, second, 10);
}

pub fn parseLine(p: *Pair, line: []const u8) !void {
    var found = std.mem.indexOf(u8, line, ",").?;
    try parseRange(&p.first, line[0..found]);
    try parseRange(&p.second, line[(found + 1)..]);
}

pub fn testPart1(filename: []const u8) !u32 {
    var file = try fs.cwd().openFile(filename, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var buf: [50]u8 = undefined;
    var max: u32 = 0;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var p = Pair{};
        try parseLine(&p, line);
        max += p.fullyContained();
    }
    return max;
}

pub fn testPart2(filename: []const u8) !u32 {
    var file = try fs.cwd().openFile(filename, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var buf: [50]u8 = undefined;
    var max: u32 = 0;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var p = Pair{};
        try parseLine(&p, line);
        max += p.overlaps();
    }
    return max;
}

test "part-1: example input" {
    try std.testing.expectEqual(try testPart1("inputs/04/test-1"), 2);
}

test "part-1: input" {
    try std.testing.expectEqual(try testPart1("inputs/04/input"), 433);
}

test "part-2: example input" {
    try std.testing.expectEqual(try testPart2("inputs/04/test-1"), 4);
}

test "part-2: input" {
    try std.testing.expectEqual(try testPart2("inputs/04/input"), 852);
}
