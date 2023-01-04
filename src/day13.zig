const std = @import("std");
const print = std.debug.print;
const mem = std.mem;
const fs = std.fs;
const fmt = std.fmt;
const cmdline = @import("libs/cmdline.zig");
var allocator: mem.Allocator = undefined;

pub fn main() !void {
    const p = try cmdline.parse();

    allocator = std.heap.page_allocator;
    const solution: u32 = switch (p.part) {
        1 => try solvePart1(p.filename),
        2 => try solvePart2(p.filename),
        else => {
            return error.InvalidArgs;
        },
    };
    print("Solution: {d}\n", .{solution});
}

const PacketList = struct {
    Parent: *PacketList = undefined,
    Children: std.ArrayList(*PacketList),
    Value: ?u8 = null,

    pub fn Print(self: *PacketList) void {
        if (self.Value) |v| {
            print("{d}", .{v});
            return;
        }

        print("[", .{});
        for (self.Children.items) |p, i| {
            p.Print();
            if (i != self.Children.items.len - 1) {
                print(",", .{});
            }
        }
        print("]", .{});
    }

    fn init() !*PacketList {
        var p = try allocator.create(PacketList);
        p.Children = std.ArrayList(*PacketList).init(allocator);
        p.Value = null;
        return p;
    }

    pub fn deinit(self: *PacketList) void {
        for (self.Children.items) |p| {
            p.deinit();
        }
        allocator.destroy(self);
    }

    fn parse(self: *PacketList, line: []const u8) !void {
        var current: *PacketList = self;
        var startIdx: usize = 0;
        var parsing: bool = false;
        var new: *PacketList = undefined;
        for (line) |c, idx| {
            switch (c) {
                '0'...'9' => {
                    if (parsing == true) continue;
                    parsing = true;
                    startIdx = idx;
                    continue;
                },
                else => {},
            }

            new = try PacketList.init();
            new.Parent = current;
            if (parsing) {
                new.Value = try fmt.parseInt(u8, line[startIdx..idx], 10);
                parsing = false;
            }
            try current.Children.append(new);

            switch (c) {
                '[' => {
                    current = new;
                },
                ']' => {
                    current = current.Parent;
                },
                else => {},
            }
        }
        return;
    }

    fn lessThan(context: void, a: *PacketList, b: *PacketList) bool {
        _ = context;
        var order = getOrder(a, b) catch .gt;
        if (order == .lt) {
            return true;
        }
        return false;
        // var da: u32 = a.distance.?;
        // var db: u32 = b.distance.?;
        // return std.math.order(da, db);
    }
};

pub fn getOrder(left: *PacketList, right: *PacketList) !std.math.Order {
    // If both sides have a value, compare them directly
    if (left.Value) |lv| {
        if (right.Value) |rv| {
            if (lv > rv) {
                return .gt;
            } else if (lv == rv) {
                return .eq;
            } else {
                return .lt;
            }
        } else {
            var new = try PacketList.init();
            new.Parent = left;
            new.Value = lv;
            try left.Children.append(new);
            left.Value = null;
        }
    } else {
        if (right.Value) |rv| {
            var new = try PacketList.init();
            new.Parent = right;
            new.Value = rv;
            try right.Children.append(new);
            right.Value = null;
        }
    }

    // If both sides are lists
    for (left.Children.items) |l, i| {
        // If left side is bigger than right side
        if (i + 1 > right.Children.items.len) {
            return .gt;
        }
        // Compare item, continue if the order is right so far
        switch (try getOrder(l, right.Children.items[i])) {
            .lt => return .lt,
            .gt => return .gt,
            else => continue,
        }
    }
    // After we compared all the values, check the len
    if (left.Children.items.len == right.Children.items.len) {
        return .eq;
    } else {
        return .lt;
    }

    return .lt;
}

pub fn parse(filename: []const u8) !*std.ArrayList(*PacketList) {
    var file = try fs.cwd().openFile(filename, .{});
    defer file.close();

    var pktList: std.ArrayList(*PacketList) = std.ArrayList(*PacketList).init(allocator);
    var new: *PacketList = undefined;

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var buf: [255]u8 = undefined;
    var i: u32 = 0;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        defer i += 1;
        if (i % 3 == 2) continue;

        new = try PacketList.init();
        try new.parse(line);
        try pktList.append(new);
    }
    return &pktList;
}

pub fn solvePart1(filename: []const u8) !u32 {
    var res: u32 = 0;
    var cpt: u32 = 1;
    var i: usize = 0;
    var list = try parse(filename);
    defer {
        // Free
        for (list.items) |p| {
            p.deinit();
        }
        list.deinit();
    }

    while (i < list.items.len) : (i += 1) {
        // Pair up the packets for comparison
        if (i % 2 == 0) continue;

        var left = list.items[i - 1];
        var right = list.items[i];
        if (try getOrder(left, right) == .lt) {
            res += cpt;
        }
        cpt += 1;
    }

    return res;
}

pub fn solvePart2(filename: []const u8) !u32 {
    var list = try parse(filename);

    var dividerPkt1: *PacketList = try PacketList.init();
    var dividerPkt2: *PacketList = try PacketList.init();

    try dividerPkt1.parse("[[2]]");
    try dividerPkt2.parse("[[6]]");

    try list.append(dividerPkt1);
    try list.append(dividerPkt2);

    var x = list.toOwnedSlice();
    defer {
        for (x) |p| {
            p.deinit();
        }
        allocator.free(x);
    }

    std.sort.sort(*PacketList, x, {}, PacketList.lessThan);
    var p1: u32 = 0;
    var p2: u32 = 0;

    var i: usize = 0;
    while (i < x.len) : (i += 1) {
        if (x[i] == dividerPkt1) {
            p1 = @intCast(u32, i + 1);
        }
        if (x[i] == dividerPkt2) {
            p2 = @intCast(u32, i + 1);
        }
    }

    return p1 * p2;
}

test "part-1: example input" {
    allocator = std.heap.page_allocator;
    try std.testing.expectEqual(@as(u64, 13), try solvePart1("inputs/13/test-1"));
}

test "part-1: input" {
    allocator = std.heap.page_allocator;
    try std.testing.expectEqual(@as(u64, 6046), try solvePart1("inputs/13/input"));
}

test "part-2: example input" {
    allocator = std.heap.page_allocator;
    try std.testing.expectEqual(@as(u64, 140), try solvePart2("inputs/13/test-1"));
}

test "part-2: input" {
    allocator = std.heap.page_allocator;
    try std.testing.expectEqual(@as(u64, 21423), try solvePart2("inputs/13/input"));
}
