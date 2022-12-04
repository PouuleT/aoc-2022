const std = @import("std");
const heap = std.heap;
const mem = std.mem;
const fmt = std.fmt;
const process = std.process;
const print = std.debug.print;

const ParsedCmd = struct {
    filename: [:0]const u8 = undefined,
    part: u8,
};

pub fn parse() anyerror!ParsedCmd {
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
    const part = arg_it.next() orelse {
        print("Missing part number\n", .{});
        return error.InvalidArgs;
    };

    var parsed = ParsedCmd{
        .filename = filename,
        .part = try fmt.parseInt(u8, part, 10),
    };
    return parsed;
}
