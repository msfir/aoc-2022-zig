const std = @import("std");

const testInput =
    \\2-4,6-8
    \\2-3,4-5
    \\5-7,7-9
    \\2-8,3-7
    \\6-6,4-6
    \\2-6,4-8
;

const InclusiveRange = struct {
    const Self = @This();

    start: i32,
    end: i32,

    pub fn init(start: i32, end: i32) !Self {
        if (start > end) {
            return error.InvalidRange;
        }
        return .{
            .start = start,
            .end = end,
        };
    }

    pub fn contains(self: Self, other: Self) bool {
        return self.start <= other.start and self.end >= other.end;
    }

    pub fn overlaps(self: Self, other: Self) bool {
        return self.end >= other.start and self.start <= other.start;
    }

    pub fn parse(str: []const u8) !Self {
        // format: {start}-{end}
        var iter = std.mem.split(u8, str, "-");
        const start = try std.fmt.parseInt(i32, iter.next().?, 10);
        const end = try std.fmt.parseInt(i32, iter.next().?, 10);
        return try Self.init(start, end);
    }
};

pub fn runAll() !void {
    try part1();
    try part2();
}

pub fn part1() !void {
    var file = try std.fs.cwd().openFile("src/input/day4.txt", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    const reader = buf_reader.reader();

    const score = try part1CountFullyContains(reader);
    std.debug.print("Day 4 Part 1: {}\n", .{score});
}

pub fn part2() !void {
    var file = try std.fs.cwd().openFile("src/input/day4.txt", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    const reader = buf_reader.reader();

    const score = try part2CountOverlaps(reader);
    std.debug.print("Day 4 Part 2: {}\n", .{score});
}

fn part1CountFullyContains(reader: anytype) !i32 {
    var buf: [128]u8 = undefined;
    var count: i32 = 0;
    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var ranges = std.mem.split(u8, line, ",");
        const range1 = try InclusiveRange.parse(ranges.next().?);
        const range2 = try InclusiveRange.parse(ranges.next().?);
        if (range1.contains(range2) or range2.contains(range1)) {
            count += 1;
        }
    }
    return count;
}

fn part2CountOverlaps(reader: anytype) !i32 {
    var buf: [128]u8 = undefined;
    var count: i32 = 0;
    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var ranges = std.mem.split(u8, line, ",");
        const range1 = try InclusiveRange.parse(ranges.next().?);
        const range2 = try InclusiveRange.parse(ranges.next().?);
        if (range1.overlaps(range2) or range2.overlaps(range1)) {
            count += 1;
        }
    }
    return count;
}

test "range parser" {
    const range = try InclusiveRange.parse("40-80");
    try std.testing.expect(range.start == 40 and range.end == 80);
}

test "range contains" {
    const range1 = try InclusiveRange.init(5, 10);
    const range2 = try InclusiveRange.init(7, 9);
    try std.testing.expect(range1.contains(range2));
    try std.testing.expect(range2.contains(range1) == false);
}

test "part 1" {
    var fis = std.io.fixedBufferStream(testInput);
    const reader = fis.reader();
    const count = try part1CountFullyContains(reader);
    try std.testing.expectEqual(@as(i32, 2), count);
}

test "part 2" {
    var fis = std.io.fixedBufferStream(testInput);
    const reader = fis.reader();
    const count = try part2CountOverlaps(reader);
    try std.testing.expectEqual(@as(i32, 4), count);
}
