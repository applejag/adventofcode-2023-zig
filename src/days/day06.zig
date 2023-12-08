// SPDX-FileCopyrightText: 2023 Kalle Fagerberg
//
// SPDX-License-Identifier: BSD-3-Clause

const std = @import("std");

pub fn part1(allocator: std.mem.Allocator, input: []const u8) !void {
    _ = allocator;
    const num = try part1Num(input);
    std.log.info("Num = {d}", .{num});
}

fn part1Num(input: []const u8) !u32 {
    var lines_iter = std.mem.tokenizeScalar(u8, input, '\n');
    const time_line = lines_iter.next() orelse return error.InvalidArgument;
    const distance_line = lines_iter.next() orelse return error.InvalidArgument;

    var time_iter = std.mem.tokenizeScalar(u8, time_line, ' ');
    var distance_iter = std.mem.tokenizeScalar(u8, distance_line, ' ');

    _ = time_iter.next(); // ignore column "Time:"
    _ = distance_iter.next(); // ignore column "Distance:"

    var product: u32 = 1;

    while (time_iter.next()) |time_str| {
        const distance_str = distance_iter.next() orelse return error.InvalidArgument;
        const time = try std.fmt.parseUnsigned(u32, time_str, 10);
        const distance = try std.fmt.parseUnsigned(u32, distance_str, 10);

        var ways: u32 = 0;

        for (1..time) |hold_time| {
            if (hold_time * (time - hold_time) > distance) {
                ways += 1;
            }
        }

        product *= ways;
    }

    return product;
}

test "part1" {
    const num = try part1Num(
        \\Time:      7  15   30
        \\Distance:  9  40  200
    );
    try std.testing.expect(num == 288);
}
