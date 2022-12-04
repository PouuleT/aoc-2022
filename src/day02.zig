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

// Opponent:
// A for Rock, B for Paper, and C for Scissors
// Me:
// X for Rock, Y for Paper, and Z for Scissors
//
// (1 for Rock, 2 for Paper, and 3 for Scissors)
// plus the score for the outcome of the round
// (0 if you lost, 3 if the round was a draw, and 6 if you won).
pub fn game(player1: u32, player2: u32) u32 {
    const points = [3]u8{ 1, 2, 3 };
    var ret: u32 = 0;
    if (player1 == player2) {
        // draw
        ret += 3;
    } else if ((player1 + 1) % 3 == player2) {
        // player2 wins
        ret += 6;
    }
    return ret + points[player2];
}

pub fn testPart1(filename: []const u8) !u32 {
    var file = try fs.cwd().openFile(filename, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var buf: [20]u8 = undefined;
    var max: u32 = 0;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var player1 = line[0] - 'A';
        var player2 = line[2] - 'X';
        var result = game(player1, player2);
        max += result;
    }
    return max;
}

// X 0 == lose
// Y 1 == draw
// Z 2 == win
pub fn guessPlay(player1: u32, outcome: u32) u32 {
    if (outcome == 1) {
        return player1;
    } else if (outcome == 0) {
        return (player1 + 2) % 3;
    }
    return (player1 + 1) % 3;
}

pub fn testPart2(filename: []const u8) !u32 {
    var file = try fs.cwd().openFile(filename, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var buf: [20]u8 = undefined;
    var max: u32 = 0;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var player1 = line[0] - 'A';
        var player2 = guessPlay(player1, line[2] - 'X');
        var result = game(player1, player2);
        max += result;
    }
    return max;
}

test "part-1: example input" {
    try std.testing.expectEqual(try testPart1("inputs/02/test-1"), 15);
}

test "part-1: input" {
    try std.testing.expectEqual(try testPart1("inputs/02/input"), 14375);
}

test "part-2: example input" {
    try std.testing.expectEqual(try testPart2("inputs/02/test-1"), 12);
}

test "part-2: input" {
    try std.testing.expectEqual(try testPart2("inputs/02/input"), 10274);
}
