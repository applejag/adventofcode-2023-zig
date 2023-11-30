// SPDX-FileCopyrightText: 2023 Kalle Fagerberg
//
// SPDX-License-Identifier: BSD-3-Clause

const std = @import("std");

pub fn part1(allocator: std.mem.Allocator, input: []u8) !void {
    _ = allocator;

    std.debug.print("day01 part1 :)\n", .{});

    var sum: i32 = 0;

    const stripped = std.mem.trim(u8, input, "\n ");
    var lines_iter = std.mem.split(u8, stripped, "\n");
    while (lines_iter.next()) |line| {
        const first_digit = std.mem.indexOfAny(u8, line, "0123456789");
        const last_digit = std.mem.lastIndexOfAny(u8, line, "0123456789");

        if (first_digit == null) {
            std.log.warn("Missing first digit in line: '{s}'", .{line});
            continue;
        }
        if (last_digit == null) {
            std.log.warn("Missing last digit in line: '{s}'", .{line});
            continue;
        }

        const num = parseDigitPair(line[first_digit.?], line[last_digit.?]) catch |err| {
            std.log.warn("Failed to parse digits in line: '{s}', {}", .{ line, err });
            continue;
        };

        std.log.info("Line: '{s}', number: {d}", .{ line, num });
        sum += num;
    }

    std.log.info("Sum = {d}", .{sum});
}

fn parseDigitPair(first: u8, second: u8) !u8 {
    const first_num = try parseDigit(first);
    const last_num = try parseDigit(second);

    return first_num * 10 + last_num;
}

fn parseDigit(digit: u8) !u8 {
    return switch (digit) {
        '0'...'9' => digit - '0',
        else => error.InvalidArgument,
    };
}
