const std = @import("std");
const print = std.debug.print;
const mem = std.mem;
const fs = std.fs;
const fmt = std.fmt;
const cmdline = @import("libs/cmdline.zig");

const ArrayList = std.ArrayList;
const allocator = std.heap.page_allocator;

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

const Move = struct {
    Nb: u8 = 0,
    From: u8 = 0,
    To: u8 = 0,
};

const Harbor = struct {
    Stacks: []ArrayList(u8) = undefined,
    Moves: [512]Move = undefined,
    MoveNb: u8 = 0,

    pub fn Arrange9000(self: *Harbor) !void {
        for (self.Moves) |move| {
            if (move.Nb == 0) break;
            var nb: u32 = 0;
            while (nb < move.Nb) {
                var popped = self.Stacks[move.From - 1].pop();
                try self.Stacks[move.To - 1].append(popped);
                nb += 1;
            }
        }
    }

    pub fn Arrange9001(self: *Harbor) !void {
        for (self.Moves) |move| {
            if (move.Nb == 0) break;
            var len: usize = self.Stacks[move.From - 1].items.len;
            try self.Stacks[move.To - 1].appendSlice(self.Stacks[move.From - 1].items[(len - move.Nb)..len]);
            var nb: u8 = 0;
            while (nb < move.Nb) {
                _ = self.Stacks[move.From - 1].pop();
                nb += 1;
            }
            nb += 1;
        }
    }

    pub fn Print(self: *Harbor) !void {
        // print to debug
        var idx: u32 = 0;
        var stackId: u32 = 0;
        while (stackId < self.Stacks.len) : (stackId += 1) {
            idx = 0;
            while (idx < self.Stacks[stackId].items.len) : (idx += 1) {
                print("{c} ", .{self.Stacks[stackId].items[idx]});
            }
            print("\n", .{});
        }
    }

    pub fn Parse(self: *Harbor, filename: []const u8) !void {
        var file = try fs.cwd().openFile(filename, .{});
        defer file.close();

        var buf_reader = std.io.bufferedReader(file.reader());
        var in_stream = buf_reader.reader();

        var buf: [50]u8 = undefined;
        var input: [50][10]u8 = undefined;
        var nbRow: u8 = 0;
        var nbCol: u8 = 0;
        while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
            if ((line.len == 0) or (line[1] == '1')) {
                break;
            }
            var i: u8 = 1;
            var idx: u8 = 0;
            while (i <= line.len) : (i += 4) {
                input[nbRow][idx] = line[i];
                idx += 1;
            }
            if (nbCol == 0) nbCol = idx;
            nbRow += 1;
        }

        var nbMoves: u32 = 0;
        while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
            if (line.len == 0) continue;
            var splits = std.mem.split(u8, line, " ");
            _ = splits.next().?;
            var count = splits.next().?;
            _ = splits.next().?;
            var from = splits.next().?;
            _ = splits.next().?;
            var to = splits.next().?;
            self.Moves[nbMoves] = Move{
                .Nb = try fmt.parseInt(u8, count, 10),
                .From = try fmt.parseInt(u8, from, 10),
                .To = try fmt.parseInt(u8, to, 10),
            };
            nbMoves += 1;
        }

        var row: u8 = nbRow;
        var col: u8 = 0;
        self.Stacks = try allocator.alloc(ArrayList(u8), nbCol);
        for (self.Stacks) |_, o| {
            self.Stacks[o] = ArrayList(u8).init(allocator);
        }

        while (row > 0) : (row -= 1) {
            while (col < nbCol) : (col += 1) {
                if (input[row - 1][col] == ' ') continue;
                try self.Stacks[col].append(input[row - 1][col]);
            }
            col = 0;
        }
    }

    pub fn deinit(self: *Harbor) void {
        for (self.Stacks) |o| o.deinit();
        allocator.free(self.Stacks);
    }
};

pub fn testPart1(filename: []const u8) ![15]u8 {
    var h = Harbor{};
    try h.Parse(filename);
    defer h.deinit();

    try h.Arrange9000();
    // try h.Print();
    var stackId: u32 = 0;
    var result: [15]u8 = [_]u8{' '} ** 15;
    while (stackId < h.Stacks.len) : (stackId += 1) {
        var popped = h.Stacks[stackId].pop();
        result[stackId] = popped;
    }

    return result;
}

pub fn testPart2(filename: []const u8) ![15]u8 {
    var h = Harbor{};
    try h.Parse(filename);
    defer h.deinit();

    try h.Arrange9001();
    // try h.Print();
    var stackId: u32 = 0;
    var result: [15]u8 = [_]u8{' '} ** 15;
    while (stackId < h.Stacks.len) : (stackId += 1) {
        var popped = h.Stacks[stackId].pop();
        result[stackId] = popped;
    }

    return result;
}

test "part-1: example input" {
    const expected = "CMZ";
    const result = testPart1("inputs/05/test-1") catch unreachable;
    try std.testing.expectEqualSlices(u8, result[0..expected.len], expected);
}

test "part-1: input" {
    const expected = "TGWSMRBPN";
    const result = testPart1("inputs/05/input") catch unreachable;
    try std.testing.expectEqualSlices(u8, result[0..expected.len], expected);
}

test "part-2: example input" {
    const expected = "MCD";
    const result = testPart2("inputs/05/test-1") catch unreachable;
    try std.testing.expectEqualSlices(u8, result[0..expected.len], expected);
}

test "part-2: input" {
    const expected = "TZLTLWRNF";
    const result = testPart2("inputs/05/input") catch unreachable;
    try std.testing.expectEqualSlices(u8, result[0..expected.len], expected);
}
