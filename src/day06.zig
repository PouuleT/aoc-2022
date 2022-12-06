const std = @import("std");
const print = std.debug.print;
const mem = std.mem;
const fs = std.fs;
const fmt = std.fmt;
const cmdline = @import("libs/cmdline.zig");

pub fn main() !void {
    const p = try cmdline.parse();

    const solution: [15]u8 = switch (p.part) {
        1 => try testPart1(p.filename),
        2 => try testPart2(p.filename),
        else => {
            return error.InvalidArgs;
        },
    };
    print("Solution: {s}\n", .{solution});
}

pub fn check(marker: []const u8) bool {
    for (marker) |c, i| {
        for (marker) |cc, ii| {
            if (i == ii) continue;
            if (c == cc) return false;
        }
    }
    return true;
}

pub fn testPart1(filename: []const u8) !u64 {
    var file = try fs.cwd().openFile(filename, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var buf: [4096]u8 = undefined;
    var line = try in_stream.readUntilDelimiterOrEof(&buf, '\n') orelse unreachable;
    var marker: [4]u8 = undefined;
    for (line) |c, idx| {
        marker[idx % 4] = c;
        if (idx < 3) continue;
        if (check(&marker)) return @as(u64, idx + 1);
    }

    return 0;
}

pub fn testPart2(filename: []const u8) !u64 {
    var file = try fs.cwd().openFile(filename, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var buf: [4096]u8 = undefined;
    var line = try in_stream.readUntilDelimiterOrEof(&buf, '\n') orelse unreachable;
    var marker: [14]u8 = undefined;
    for (line) |c, idx| {
        marker[idx % 14] = c;
        if (idx < 13) continue;
        if (check(&marker)) return @as(u64, idx + 1);
    }

    return 0;
}

test "part-1: example input" {
    try std.testing.expectEqual(@as(u64, 7), try testPart1("inputs/06/test-1"));
}

test "part-1: example input 2" {
    try std.testing.expectEqual(@as(u64, 5), try testPart1("inputs/06/test-2"));
}

test "part-1: example input 3" {
    try std.testing.expectEqual(@as(u64, 6), try testPart1("inputs/06/test-3"));
}

test "part-1: example input 4" {
    try std.testing.expectEqual(@as(u64, 10), try testPart1("inputs/06/test-4"));
}

test "part-1: example input 5" {
    try std.testing.expectEqual(@as(u64, 11), try testPart1("inputs/06/test-5"));
}

test "part-1: input" {
    try std.testing.expectEqual(@as(u64, 1647), try testPart1("inputs/06/input"));
}

test "part-2: example input" {
    try std.testing.expectEqual(@as(u64, 19), try testPart2("inputs/06/test-1"));
}

test "part-2: example input 2" {
    try std.testing.expectEqual(@as(u64, 23), try testPart2("inputs/06/test-2"));
}

test "part-2: example input 3" {
    try std.testing.expectEqual(@as(u64, 23), try testPart2("inputs/06/test-3"));
}

test "part-2: example input 4" {
    try std.testing.expectEqual(@as(u64, 29), try testPart2("inputs/06/test-4"));
}

test "part-2: example input 5" {
    try std.testing.expectEqual(@as(u64, 26), try testPart2("inputs/06/test-5"));
}

test "part-2: input" {
    try std.testing.expectEqual(@as(u64, 2447), try testPart2("inputs/06/input"));
}
