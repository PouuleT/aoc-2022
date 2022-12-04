const std = @import("std");
const print = std.debug.print;
const mem = std.mem;
const fs = std.fs;
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

pub fn getValue(char: u8) u8 {
    return switch (char) {
        'a'...'z' => char - 'a' + 1,
        'A'...'Z' => char - 'A' + 27,
        else => 0,
    };
}

pub fn findDoublons(first: []const u8, second: []const u8) u32 {
    var hash: [53]bool = undefined;
    for (first) |char| {
        hash[getValue(char)] = true;
    }
    for (second) |char| {
        var val = getValue(char);
        if (hash[val]) {
            return val;
        }
    }
    return 0;
}

pub fn testPart1(filename: []const u8) !u32 {
    var file = try fs.cwd().openFile(filename, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var buf: [50]u8 = undefined;
    var max: u32 = 0;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var len = line.len / 2;
        var first = line[0..len];
        var second = line[len..];
        var d = findDoublons(first, second);
        max += d;
    }
    return max;
}

pub fn findCommon(firstThree: [3][50]u8) u32 {
    var hash = [_]u8{0} ** 53;

    for (firstThree[0]) |char| {
        var val = getValue(char);
        if (hash[val] == 0) {
            hash[val] = 1;
        }
    }
    for (firstThree[1]) |char| {
        var val = getValue(char);
        if (hash[val] == 1) {
            hash[val] = 2;
        }
    }
    for (firstThree[2]) |char| {
        var val = getValue(char);
        if (hash[val] == 2) return val;
    }
    return 0;
}

pub fn testPart2(filename: []const u8) !u32 {
    var file = try fs.cwd().openFile(filename, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var buf: [50]u8 = undefined;
    var max: u32 = 0;
    var firstThree: [3][50]u8 = undefined;
    var idx: u8 = 0;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        firstThree[idx] = undefined;
        mem.copy(u8, &firstThree[idx], line);
        idx += 1;

        if (idx == 3) {
            var d = findCommon(firstThree);
            max += d;
            idx = 0;
        }
    }
    return max;
}

test "part-1: example input" {
    try std.testing.expectEqual(try testPart1("inputs/03/test-1"), 157);
}

test "part-1: input" {
    try std.testing.expectEqual(try testPart1("inputs/03/input"), 7903);
}

test "part-2: example input" {
    try std.testing.expectEqual(try testPart2("inputs/03/test-1"), 70);
}

test "part-2: input" {
    try std.testing.expectEqual(try testPart2("inputs/03/input"), 2548);
}
