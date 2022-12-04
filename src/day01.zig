const std = @import("std");
const print = std.debug.print;
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

pub fn testPart1(filename: []const u8) !u32 {
    var file = try fs.cwd().openFile(filename, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var buf: [20]u8 = undefined;
    var max: u32 = 0;
    var current_max: u32 = 0;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (line.len == 0) {
            if (current_max > max) {
                max = current_max;
            }
            current_max = 0;
            continue;
        }
        var val = try std.fmt.parseUnsigned(u32, line, 10);
        current_max += val;
    }
    return max;
}

pub fn testPart2(filename: []const u8) !u32 {
    var file = try fs.cwd().openFile(filename, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var buf: [20]u8 = undefined;
    var current: u32 = 0;
    var top3 = [3]u32{ 0, 0, 0 };
    var max: u32 = 0;

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (line.len == 0) {
            var tmp: u32 = 0;
            for (top3) |val, idx| {
                if (current > val) {
                    tmp = val;
                    top3[idx] = current;
                    if (idx > 0) {
                        top3[idx - 1] = tmp;
                    }
                }
            }
            current = 0;
            continue;
        }
        var val = try std.fmt.parseUnsigned(u32, line, 10);
        current += val;
    }
    for (top3) |val| {
        max += val;
    }
    return max;
}

test "part-1: example input" {
    try std.testing.expect(try testPart1("inputs/01/test-1") == 24000);
}

test "part-1: input" {
    try std.testing.expect(try testPart1("inputs/01/input") == 70369);
}

test "part-2: example input" {
    try std.testing.expect(try testPart2("inputs/01/test-1") == 45000);
}

test "part-2: input" {
    try std.testing.expect(try testPart2("inputs/01/input") == 203002);
}
