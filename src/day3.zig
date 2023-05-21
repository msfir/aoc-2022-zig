const std = @import("std");

const testInput =
    \\vJrwpWtwJgWrhcsFMMfFFhFp
    \\jqHRNqRjqzjGDLGLrsFMfFZSrLrFZsSL
    \\PmmdzqPrVvPwwTWBwg
    \\wMqvLMZHhHMvwLHjbvcjnnSBnvTQFn
    \\ttgJtRGJQctTZtZT
    \\CrZsJsPPZsGzwwsLwLmpwMDw
;

const Rucksack = struct {
    const Self = @This();

    first: []const u8,
    second: []const u8,

    pub fn init(content: []const u8) Self {
        return .{
            .first = content[0 .. content.len / 2],
            .second = content[content.len / 2 ..],
        };
    }

    pub fn getSharedItem(self: Self) u8 {
        var firstBits: u64 = 0;
        var secondBits: u64 = 0;
        for (self.first) |item| {
            const pos = @intCast(u6, Self.priorityOf(item) - 1);
            firstBits |= (@as(u64, 1) << pos);
        }
        for (self.second) |item| {
            const pos = @intCast(u6, Self.priorityOf(item) - 1);
            secondBits |= (@as(u52, 1) << pos);
        }
        var i: i32 = 0;
        const shares = firstBits & secondBits;
        while (i < 52) : (i += 1) {
            if (shares >> @intCast(u6, i) & 1 == 1) {
                return if (0 <= i and i <= 25) @intCast(u8, i + 'a') else @intCast(u8, i + 'A' - 26);
            }
        }
        unreachable; // problem in the input file
    }

    pub fn priorityOf(item: u8) i32 {
        return @intCast(i32, if ('a' <= item and item <= 'z') item - 'a' + 1 else item - 'A' + 27);
    }
};

const Rucksack2 = struct {
    const Self = @This();

    first: []const u8,
    second: []const u8,
    third: []const u8,

    pub fn init(content: [3][]const u8) Self {
        return .{
            .first = content[0],
            .second = content[1],
            .third = content[2],
        };
    }

    pub fn getSharedItem(self: Self) u8 {
        var firstBits: u64 = 0;
        var secondBits: u64 = 0;
        var thirdBits: u64 = 0;
        for (self.first) |item| {
            const pos = @intCast(u6, Self.priorityOf(item) - 1);
            firstBits |= (@as(u64, 1) << pos);
        }
        for (self.second) |item| {
            const pos = @intCast(u6, Self.priorityOf(item) - 1);
            secondBits |= (@as(u52, 1) << pos);
        }
        for (self.third) |item| {
            const pos = @intCast(u6, Self.priorityOf(item) - 1);
            thirdBits |= (@as(u52, 1) << pos);
        }
        var i: i32 = 0;
        const shares = firstBits & secondBits & thirdBits;
        while (i < 52) : (i += 1) {
            if (shares >> @intCast(u6, i) & 1 == 1) {
                return if (0 <= i and i <= 25) @intCast(u8, i + 'a') else @intCast(u8, i + 'A' - 26);
            }
        }
        unreachable; // problem in the input file
    }

    pub fn priorityOf(item: u8) i32 {
        return @intCast(i32, if ('a' <= item and item <= 'z') item - 'a' + 1 else item + 27 - 'A');
    }
};

pub fn runAll() !void {
    try part1();
    try part2();
}

pub fn part1() !void {
    var file = try std.fs.cwd().openFile("src/input/day3.txt", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    const reader = buf_reader.reader();

    const score = try part1SumOfPriorities(reader);
    std.debug.print("Day 3 Part 1: {}\n", .{score});
}

pub fn part2() !void {
    var file = try std.fs.cwd().openFile("src/input/day3.txt", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    const reader = buf_reader.reader();

    const score = try part2SumOfPriorities(reader);
    std.debug.print("Day 3 Part 1: {}\n", .{score});
}

fn part1SumOfPriorities(reader: anytype) !i32 {
    var buf: [128]u8 = undefined;
    var sum: i32 = 0;
    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        const rs = Rucksack.init(line);
        const sharedItem = rs.getSharedItem();
        sum += Rucksack.priorityOf(sharedItem);
    }
    return sum;
}

fn part2SumOfPriorities(reader: anytype) !i32 {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    var buf: [128]u8 = undefined;
    var content: [3][]u8 = undefined;
    var sum: i32 = 0;
    var i: usize = 0;

    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        content[i] = try allocator.alloc(u8, line.len);
        std.mem.copy(u8, content[i], line);
        i += 1;
        if (i == 3) {
            const rs = Rucksack2.init(content);
            const sharedItem = rs.getSharedItem();
            // std.debug.print("{c} -> {}\n", .{sharedItem, Rucksack2.priorityOf(sharedItem)});
            sum += Rucksack2.priorityOf(sharedItem);
            i = 0;
            for (content) |value| {
                allocator.free(value);
            }
        }
    }
    return sum;
}

test "part 1" {
    var fis = std.io.fixedBufferStream(testInput);
    const reader = fis.reader();
    const sum = try part1SumOfPriorities(reader);
    try std.testing.expectEqual(@as(i32, 157), sum);
}

test "part 2" {
    var fis = std.io.fixedBufferStream(testInput);
    const reader = fis.reader();
    const sum = try part2SumOfPriorities(reader);
    try std.testing.expectEqual(@as(i32, 70), sum);
}
