const day1 = @import("day1.zig");
const day2 = @import("day2.zig");
const day3 = @import("day3.zig");
const day4 = @import("day4.zig");
const day5 = @import("day5.zig");
const day6 = @import("day6.zig");
const day7 = @import("day7.zig");

pub fn main() !void {
    try day1.runAll();
    try day2.runAll();
    try day3.runAll();
    try day4.runAll();
    try day5.runAll();
    try day6.runAll();
    try day7.runAll();
}
