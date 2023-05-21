const day1 = @import("day1.zig");
const day2 = @import("day2.zig");
const day3 = @import("day3.zig");
const day4 = @import("day4.zig");

pub fn main() !void {
    try day1.runAll();
    try day2.runAll();
    try day3.runAll();
    try day4.runAll();
}
