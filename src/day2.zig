const std = @import("std");

const test_input =
    \\A Y
    \\B X
    \\C Z
;

const Outcome = enum(u8) {
    win = 6,
    draw = 3,
    lose = 0,

    pub fn parse(sym: u8) Outcome {
        return switch (sym) {
            'X' => .lose,
            'Y' => .draw,
            'Z' => .win,
            else => unreachable,
        };
    }
};

const Shape = enum(u8) {
    rock = 1,
    paper = 2,
    scissors = 3,

    pub fn parse(sym: u8) Shape {
        return switch (sym) {
            'A', 'X' => .rock,
            'B', 'Y' => .paper,
            'C', 'Z' => .scissors,
            else => unreachable, // problem in input file
        };
    }

    pub fn winsFrom(self: Shape) Shape {
        return switch (self) {
            .rock => .scissors,
            .paper => .rock,
            .scissors => .paper,
        };
    }

    pub fn losesBy(self: Shape) Shape {
        return switch (self) {
            .rock => .paper,
            .paper => .scissors,
            .scissors => .rock,
        };
    }

    pub fn compete(self: Shape, opponent: Shape) Outcome {
        const idx_self = @enumToInt(self) - 1;
        const idx_opponent = @enumToInt(opponent) - 1;
        const rock = [3]Outcome{ .draw, .lose, .win };
        const paper = [3]Outcome{ .win, .draw, .lose };
        const scissors = [3]Outcome{ .lose, .win, .draw };
        const outcomes = [_][3]Outcome{ rock, paper, scissors };
        return outcomes[idx_self][idx_opponent];
    }
};

const Part1Round = struct {
    ours: Shape,
    theirs: Shape,

    pub fn compete(self: Part1Round) i32 {
        const outcome = @intCast(i32, @enumToInt(self.ours) + @enumToInt(self.ours.compete(self.theirs)));
        return outcome;
    }

    pub fn parse(str: []const u8) Part1Round {
        var temp = std.mem.trimLeft(u8, str, " ");
        const theirs = Shape.parse(temp[0]);
        temp = std.mem.trimLeft(u8, temp[1..], " ");
        const ours = Shape.parse(temp[0]);
        return .{
            .ours = ours,
            .theirs = theirs,
        };
    }
};

const Part2Round = struct {
    theirs: Shape,
    outcome: Outcome,

    pub fn compete(self: Part2Round) i32 {
        const ours: Shape = switch (self.outcome) {
            .draw => self.theirs,
            .win => self.theirs.losesBy(),
            .lose => self.theirs.winsFrom(),
        };
        const round = Part1Round{ .ours = ours, .theirs = self.theirs };
        return round.compete();
    }

    pub fn parse(str: []const u8) Part2Round {
        var temp = std.mem.trimLeft(u8, str, " ");
        const theirs = Shape.parse(temp[0]);
        temp = std.mem.trimLeft(u8, temp[1..], " ");
        const outcome = Outcome.parse(temp[0]);
        return .{
            .theirs = theirs,
            .outcome = outcome,
        };
    }
};

pub fn runAll() !void {
    try part1();
    try part2();
}

pub fn part1() !void {
    var file = try std.fs.cwd().openFile("src/input/day2.txt", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    const reader = buf_reader.reader();

    const score = try part1TotalScore(reader);
    std.debug.print("Day 2 Part 1: {}\n", .{score});
}

pub fn part2() !void {
    var file = try std.fs.cwd().openFile("src/input/day2.txt", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    const reader = buf_reader.reader();

    const score = try part2TotalScore(reader);
    std.debug.print("Day 2 Part 2: {}\n", .{score});
}

fn part1TotalScore(reader: anytype) !i32 {
    var buf: [64]u8 = undefined;
    var sum: i32 = 0;
    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        const pair = Part1Round.parse(line);
        sum += pair.compete();
    }
    return sum;
}

fn part2TotalScore(reader: anytype) !i32 {
    var buf: [64]u8 = undefined;
    var sum: i32 = 0;
    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        const pair = Part2Round.parse(line);
        sum += pair.compete();
    }
    return sum;
}

test "part one" {
    var fis = std.io.fixedBufferStream(test_input);
    const reader = fis.reader();
    const score = try part1TotalScore(reader);
    try std.testing.expectEqual(@as(i32, 15), score);
}

test "part two" {
    var fis = std.io.fixedBufferStream(test_input);
    const reader = fis.reader();
    const score = try part2TotalScore(reader);
    try std.testing.expectEqual(@as(i32, 12), score);
}