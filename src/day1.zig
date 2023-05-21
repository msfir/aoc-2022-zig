const std = @import("std");
const testing = std.testing;

const test_input =
    \\1000
    \\2000
    \\3000
    \\
    \\4000
    \\
    \\5000
    \\6000
    \\
    \\7000
    \\8000
    \\9000
    \\
    \\10000
;

pub fn runAll() !void {
    try part1();
    try part2();
}

pub fn part1() !void {
    var file = try std.fs.cwd().openFile("src/input/day1.txt", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    const in_stream = buf_reader.reader();

    const max = try part1MaxSum(in_stream);
    std.debug.print("Day 1 Part 1: {}\n", .{max});
}

pub fn part2() !void {
    var file = try std.fs.cwd().openFile("src/input/day1.txt", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    const in_stream = buf_reader.reader();

    const sum = try part2Top3Sum(in_stream);
    std.debug.print("Day 1 Part 2: {}\n", .{sum});
}

fn part1MaxSum(reader: anytype) !i32 {
    var buf: [10]u8 = undefined;
    var sum: i32 = 0;
    var max: i32 = 0;
    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (line.len == 0) {
            if (sum > max) {
                max = sum;
            }
            sum = 0;
        } else {
            sum += try std.fmt.parseInt(i32, line, 10);
        }
    }
    if (sum > max) {
        max = sum;
    }
    return max;
}

fn part2Top3Sum(reader: anytype) !i32 {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    var list = std.ArrayList(i32).init(allocator);
    defer list.deinit();
    var buf: [10]u8 = undefined;
    var sum: i32 = 0;
    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (line.len == 0) {
            try list.append(sum);
            sum = 0;
        } else {
            sum += try std.fmt.parseInt(i32, line, 10);
        }
    }
    try list.append(sum);
    std.sort.sort(i32, list.items, {}, std.sort.desc(i32));
    sum = 0;
    for (list.items[0..3]) |item| {
        sum += item;
    }
    return sum;
}

test "part1" {
    var fis = std.io.fixedBufferStream(test_input);
    const reader = fis.reader();
    try testing.expectEqual(@as(i32, 24000), try part1MaxSum(reader));
}

test "part2" {
    var fis = std.io.fixedBufferStream(test_input);
    const reader = fis.reader();
    try testing.expectEqual(@as(i32, 45000), try part2Top3Sum(reader));
}