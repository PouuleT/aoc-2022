const std = @import("std");
const print = std.debug.print;
const process = std.process;
const heap = std.heap;
const mem = std.mem;
const fs = std.fs;

pub fn main() !void {
    var arena = heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var allocator: mem.Allocator = arena.allocator();

    var arg_it = try process.argsWithAllocator(allocator);
    // skip our own name
    _ = arg_it.skip();

    const filename = arg_it.next() orelse {
        print("Missing filename\n", .{});
        return error.InvalidArgs;
    };

    print("Filename: {s}\n", .{filename});
    _ = try testPart1(filename);
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
        // print("{d} ( current max {d} ( max {d} ))\n", .{ val, current_max, max });
    }
    print("Max: {d}\n", .{max});
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
            // print("Evalute {d} vs top3\n", .{current});
            var tmp: u32 = 0;
            for (top3) |val, idx| {
                if (current > val) {
                    // print("{d} > {d} ( {d} )\n", .{ current, val, idx });
                    tmp = val;
                    top3[idx] = current;
                    if (idx > 0) {
                        top3[idx - 1] = tmp;
                    }
                }
            }
            current = 0;
            // print("top 3: {d} {d} {d} )\n", .{ top3[0], top3[1], top3[2] });
            continue;
        }
        var val = try std.fmt.parseUnsigned(u32, line, 10);
        current += val;
        // print("{d} ( sum {d} )\n", .{ val, current });
    }
    for (top3) |val| {
        max += val;
    }
    print("Max: {d}\n", .{max});
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
