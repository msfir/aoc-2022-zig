const std = @import("std");

const testInput =
    \\    [D]    
    \\[N] [C]    
    \\[Z] [M] [P]
    \\ 1   2   3 
    \\
    \\move 1 from 2 to 1
    \\move 3 from 1 to 3
    \\move 2 from 2 to 1
    \\move 1 from 1 to 2
;

const SupplyStacks = struct {
    const Self = @This();

    size: usize,
    stacks: []std.ArrayList(u8),
    allocator: std.mem.Allocator,

    pub fn init(size: usize, allocator: std.mem.Allocator) !Self {
        var stacks = try allocator.alloc(std.ArrayList(u8), size);
        std.mem.set(std.ArrayList(u8), stacks, std.ArrayList(u8).init(allocator));
        return .{
            .size = size,
            .stacks = stacks,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Self) void {
        for (self.stacks) |stack| {
            stack.deinit();
        }
        self.allocator.free(self.stacks);
    }

    pub fn moveOneByOne(self: *Self, from: usize, to: usize, count: u32) !void {
        var i: u32 = 0;
        while (i < count) : (i += 1) {
            try self.stacks[to].append(self.stacks[from].pop());
        }
    }

    pub fn moveAtOnce(self: *Self, from: usize, to: usize, count: u32) !void {
        var i: u32 = 0;
        var temp = try std.ArrayList(u8).initCapacity(self.allocator, count);
        defer temp.deinit();
        while (i < count) : (i += 1) {
            try temp.append(self.stacks[from].pop());
        }
        i = 0;
        while (i < count) : (i += 1) {
            try self.stacks[to].append(temp.pop());
        }
    }

    pub fn push(self: *Self, item: u8, to: usize) !void {
        try self.stacks[to].append(item);
    }

    pub fn parse(str: []const u8, allocator: std.mem.Allocator) !Self {
        const size = (std.mem.indexOf(u8, str, "\n").? - @as(usize, 3)) / 4 + 1;
        var supplies = try Self.init(size, allocator);
        var lines = std.mem.split(u8, str, "\n");
        var len: usize = 0;
        while (lines.next()) |line| {
            if (len == size) {
                len = 0;
                break;
            }
            var i: usize = 1;
            var idx: usize = 0;
            while (i < line.len) : (i += 4) {
                if (line[i] != ' ') try supplies.push(line[i], idx);
                idx += 1;
            }
            len += 1;
        }
        for (supplies.stacks) |*stack| {
            std.mem.reverse(u8, stack.items);
        }
        return supplies;
    }
};

const MoveAction = struct {
    const Self = @This();

    from: usize,
    to: usize,
    count: u32,

    pub fn init(from: usize, to: usize, count: u32) Self {
        return .{
            .from = from,
            .to = to,
            .count = count,
        };
    }

    pub fn parse(str: []const u8) !Self {
        var fields = std.mem.split(u8, str, " ");
        _ = fields.next().?; // move
        const count = try std.fmt.parseInt(u8, fields.next().?, 10);
        _ = fields.next().?; // from
        const from = try std.fmt.parseInt(u8, fields.next().?, 10);
        _ = fields.next().?; // to
        const to = try std.fmt.parseInt(u8, fields.next().?, 10);
        return .{
            .count = count,
            .from = from - 1,
            .to = to - 1,
        };
    }
};

pub fn runAll() !void {
    try part1();
    try part2();
}

pub fn part1() !void {
    const allocator = std.heap.page_allocator;
    var file = try std.fs.cwd().openFile("src/input/day5.txt", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    const reader = buf_reader.reader();

    const result = try part1PrintTopStacks(reader, allocator);
    defer allocator.free(result);
    std.debug.print("Day 5 Part 1: {s}\n", .{result});
}

pub fn part2() !void {
    const allocator = std.heap.page_allocator;
    var file = try std.fs.cwd().openFile("src/input/day5.txt", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    const reader = buf_reader.reader();

    const result = try part2PrintTopStacks(reader, allocator);
    defer allocator.free(result);
    std.debug.print("Day 5 Part 2: {s}\n", .{result});
}

fn part1PrintTopStacks(reader: anytype, allocator: std.mem.Allocator) ![]u8 {
    var buf = try reader.readAllAlloc(allocator, 1024 * 1024 * 1024);
    var sections = std.mem.split(u8, buf, "\n\n");
    var supplies = try SupplyStacks.parse(sections.next().?, allocator);
    defer supplies.deinit();
    var actions = std.mem.split(u8, sections.next().?, "\n");
    while (actions.next()) |action| {
        const act = try MoveAction.parse(action);
        try supplies.moveOneByOne(act.from, act.to, act.count);
    }
    var result = try allocator.alloc(u8, supplies.size);
    for (result) |_, i| {
        result[i] = supplies.stacks[i].pop();
    }
    return result;
}

fn part2PrintTopStacks(reader: anytype, allocator: std.mem.Allocator) ![]u8 {
    var buf = try reader.readAllAlloc(allocator, 1024 * 1024 * 1024);
    var sections = std.mem.split(u8, buf, "\n\n");
    var supplies = try SupplyStacks.parse(sections.next().?, allocator);
    defer supplies.deinit();
    var actions = std.mem.split(u8, sections.next().?, "\n");
    while (actions.next()) |action| {
        const act = try MoveAction.parse(action);
        try supplies.moveAtOnce(act.from, act.to, act.count);
    }
    var result = try allocator.alloc(u8, supplies.size);
    for (result) |_, i| {
        result[i] = supplies.stacks[i].pop();
    }
    return result;
}

test "supply stacks parse" {
    var sections = std.mem.split(u8, testInput, "\n\n");
    var supplies = try SupplyStacks.parse(sections.next().?, std.testing.allocator);
    defer supplies.deinit();
    try std.testing.expectEqualStrings("ZN", supplies.stacks[0].items);
    try std.testing.expectEqualStrings("MCD", supplies.stacks[1].items);
    try std.testing.expectEqualStrings("P", supplies.stacks[2].items);
}

test "move action parse" {
    const action = try MoveAction.parse("move 3 from 1 to 2");
    try std.testing.expectFmt("3 0 1", "{} {} {}", .{ action.count, action.from, action.to });
}

test "part 1" {
    var fis = std.io.fixedBufferStream(testInput);
    const reader = fis.reader();
    const allocator = std.heap.page_allocator;
    var result = try part1PrintTopStacks(reader, allocator);
    defer allocator.free(result);
    try std.testing.expectEqualStrings("CMZ", result);
}

test "part 2" {
    var fis = std.io.fixedBufferStream(testInput);
    const reader = fis.reader();
    const allocator = std.heap.page_allocator;
    var result = try part2PrintTopStacks(reader, allocator);
    defer allocator.free(result);
    try std.testing.expectEqualStrings("MCD", result);
}
