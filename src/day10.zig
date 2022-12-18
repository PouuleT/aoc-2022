const std = @import("std");
const print = std.debug.print;
const mem = std.mem;
const fs = std.fs;
const fmt = std.fmt;
const cmdline = @import("libs/cmdline.zig");

const allocator = std.heap.page_allocator;

pub fn main() !void {
    const p = try cmdline.parse();

    const solution: i64 = switch (p.part) {
        1 => try testPart1(p.filename),
        2 => try testPart2(p.filename),
        else => {
            return error.InvalidArgs;
        },
    };
    print("Solution: {d}\n", .{solution});
}

const Instruction = enum(u8) {
    Noop = 'n',
    Add = 'a',
};

pub fn check(cycleNb: u32, x: i64) i64 {
    if ((cycleNb + 20) % 40 == 0) {
        return x * @as(i64, cycleNb);
    }
    return 0;
}

pub fn printChar(cycleNb: u32, x: i64) void {
    var c: u8 = '.';
    var val: u32 = cycleNb % 40;
    if (val >= x and val < (x + 3)) c = '#';
    print("{c}", .{c});
    if (val == 0) print("\n", .{});
}

pub fn parsePart1(filename: []const u8) !i64 {
    var file = try fs.cwd().openFile(filename, .{});
    defer file.close();
    var res: i64 = 0;

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var buf: [10]u8 = undefined;
    var x: i32 = 1;

    var cycleNb: u32 = 1;
    while (try in_stream.readUntilDelimiterOrEof(buf[0..], '\n')) |line| {
        res += check(cycleNb, x);

        var instruction: Instruction = @intToEnum(Instruction, line[0]);
        switch (instruction) {
            .Noop => {
                cycleNb += 1;
                continue;
            },
            .Add => {
                var lastSpace = std.mem.lastIndexOf(u8, line, " ").?;
                var value: i32 = try fmt.parseInt(i32, line[lastSpace + 1 ..], 10);
                cycleNb += 1;
                res += check(cycleNb, x);

                cycleNb += 1;
                x += value;
            },
        }
    }

    return res;
}

pub fn parsePart2(filename: []const u8) !i64 {
    var file = try fs.cwd().openFile(filename, .{});
    defer file.close();
    var res: i64 = 0;

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var buf: [10]u8 = undefined;
    var x: i32 = 1;

    var cycleNb: u32 = 1;
    while (try in_stream.readUntilDelimiterOrEof(buf[0..], '\n')) |line| {
        printChar(cycleNb, x);

        var instruction: Instruction = @intToEnum(Instruction, line[0]);
        switch (instruction) {
            .Noop => {
                cycleNb += 1;
                continue;
            },
            .Add => {
                var lastSpace = std.mem.lastIndexOf(u8, line, " ").?;
                var value: i32 = try fmt.parseInt(i32, line[lastSpace + 1 ..], 10);
                // print(" - Add {d}\n", .{value});
                cycleNb += 1;
                printChar(cycleNb, x);

                cycleNb += 1;
                x += value;
            },
        }
    }

    return res;
}

pub fn testPart1(filename: []const u8) !i64 {
    return try parsePart1(filename);
}

pub fn testPart2(filename: []const u8) !i64 {
    return try parsePart2(filename);
}

test "part-1: example input" {
    try std.testing.expectEqual(@as(i64, 13140), try testPart1("inputs/10/test-1"));
}

test "part-1: input" {
    try std.testing.expectEqual(@as(i64, 17380), try testPart1("inputs/10/input"));
}

// ####..##...##..#..#.####.###..####..##..
// #....#..#.#..#.#..#....#.#..#.#....#..#.
// ###..#....#....#..#...#..#..#.###..#...#
// #....#.##.#....#..#..#...###..#....#....
// #....#..#.#..#.#..#.#....#.#..#....#..#.
// #.....###..##...##..####.#..#.####..##..

// test "part-2: example input" {
//     try std.testing.expectEqual(@as(u64, 1), try testPart2("inputs/09/test-1"));
// }
//
// test "part-2: input" {
//     try std.testing.expectEqual(@as(u64, 2384), try testPart2("inputs/09/input"));
// }
