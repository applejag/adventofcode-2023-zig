const std = @import("std");

pub fn part1() !void {
    std.debug.print("day01 part1 :)\n", .{});
}

test "day01 foobar" {
    const value = 1 + 2;
    try std.testing.expectEqual(3, value);
}
