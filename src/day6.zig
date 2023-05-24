const std = @import("std");

const testInput = [_][]const u8{
    "mjqjpqmgbljsphdztnvjfqwrcgsmlb",
    "bvwbjplbgvbhsrlpgdmjqwftvncz",
    "nppdvjthqldpwncqszvftbrmjlhg",
    "nznrnfrfntjfmvfwmzdfjlvtqnbhcprsg",
    "zcfzfwzzqfrljwzlrfnpqdbhtmscgvjw",
};

const WindowIterator = struct {
    const Self = @This();

    buf: []const u8,
    index: usize,
    width: usize,

    pub fn init(buf: []const u8, width: usize) Self {
        return .{
            .buf = buf,
            .index = 0,
            .width = width,
        };
    }

    pub fn next(self: *Self) ?[]const u8 {
        if (self.index + self.width >= self.buf.len) {
            return null;
        }
        const window = self.buf[self.index .. self.index + self.width];
        self.index += 1;
        return window;
    }
};

pub fn runAll() !void {
    try part1();
    try part2();
}

pub fn part1() !void {
    const allocator = std.heap.page_allocator;
    var file = try std.fs.cwd().openFile("src/input/day6.txt", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    const reader = buf_reader.reader();

    const ans = try part1DetectStartOfPacketMarker(reader, allocator);
    std.debug.print("Day 6 Part 1: {}\n", .{ans});
}

pub fn part2() !void {
    const allocator = std.heap.page_allocator;
    var file = try std.fs.cwd().openFile("src/input/day6.txt", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    const reader = buf_reader.reader();

    const ans = try part2DetectStartOfMessageMarker(reader, allocator);
    std.debug.print("Day 6 Part 2: {}\n", .{ans});
}

fn part1DetectStartOfPacketMarker(reader: anytype, allocator: std.mem.Allocator) !usize {
    return try runLogic(reader, allocator, 4);
}

fn part2DetectStartOfMessageMarker(reader: anytype, allocator: std.mem.Allocator) !usize {
    return try runLogic(reader, allocator, 14);
}

fn runLogic(reader: anytype, allocator: std.mem.Allocator, windowWidth: usize) !usize {
    const buf = try reader.readAllAlloc(allocator, 1024 * 1024 * 1024);
    defer allocator.free(buf);

    var iter = WindowIterator.init(buf, windowWidth);
    outer: while (iter.next()) |pack| {
        var appearance: u128 = 0;
        for (pack) |char| {
            if (appearance >> @intCast(u7, char) & 1 == 1) {
                continue :outer;
            }
            appearance |= @as(u128, 1) << @intCast(u7, char);
        }
        return iter.index + iter.width - 1;
    }
    return 0;
}

test "window iterator" {
    const buf = "abcdefg";
    const expected = [_][]const u8{ "abcd", "bcde", "cdef", "defg" };
    var iter = WindowIterator.init(buf, 4);
    var i: usize = 0;
    while (iter.next()) |text| : (i += 1) {
        try std.testing.expectEqualStrings(expected[i], text);
    }
    try std.testing.expect(iter.next() == null);
}

test "part 1" {
    const expected = [_]usize{ 7, 5, 6, 10, 11 };
    const allocator = std.heap.page_allocator;
    for (testInput) |input, i| {
        var fis = std.io.fixedBufferStream(input);
        const reader = fis.reader();
        const ans = try part1DetectStartOfPacketMarker(reader, allocator);
        try std.testing.expectEqual(expected[i], ans);
    }
}

test "part 2" {
    const expected = [_]usize{ 19, 23, 23, 29, 26 };
    const allocator = std.heap.page_allocator;
    for (testInput) |input, i| {
        var fis = std.io.fixedBufferStream(input);
        const reader = fis.reader();
        const ans = try part2DetectStartOfMessageMarker(reader, allocator);
        try std.testing.expectEqual(expected[i], ans);
    }
}
