// SPDX-FileCopyrightText: 2023 Kalle Fagerberg
//
// SPDX-License-Identifier: BSD-3-Clause

const std = @import("std");

pub fn part1(allocator: std.mem.Allocator, input: []const u8) !void {
    _ = allocator;

    var sum: i32 = 0;

    const stripped = std.mem.trim(u8, input, "\n ");
    var lines_iter = std.mem.split(u8, stripped, "\n");
    while (lines_iter.next()) |line| {
        const first_digit = std.mem.indexOfAny(u8, line, digit_chars);
        const last_digit = std.mem.lastIndexOfAny(u8, line, digit_chars);

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

        //std.log.info("Line: '{s}', number: {d}", .{ line, num });
        sum += num;
    }

    std.log.info("Sum = {d}", .{sum});
}

pub fn part2(allocator: std.mem.Allocator, input: []const u8) !void {
    _ = allocator;

    var sum: i32 = 0;

    const stripped = std.mem.trim(u8, input, "\n ");
    var lines_iter = std.mem.split(u8, stripped, "\n");
    while (lines_iter.next()) |line| {
        const num = findPart2Num(line) catch |err| {
            std.log.warn("Failed to find digits in line: '{s}', {}", .{ line, err });
            continue;
        };

        sum += num;
    }

    std.log.info("Sum = {d}", .{sum});
}

const digit_chars = "0123456789";

const Digit = struct {
    name: []const u8,
    value: u8,
};

const digits = [_]Digit{
    Digit{ .name = "zero", .value = 0 },
    Digit{ .name = "one", .value = 1 },
    Digit{ .name = "two", .value = 2 },
    Digit{ .name = "three", .value = 3 },
    Digit{ .name = "four", .value = 4 },
    Digit{ .name = "five", .value = 5 },
    Digit{ .name = "six", .value = 6 },
    Digit{ .name = "seven", .value = 7 },
    Digit{ .name = "eight", .value = 8 },
    Digit{ .name = "nine", .value = 9 },
};

fn findPart2Num(line: []const u8) !u8 {
    const first_num = try findFirstDigit(line);
    const last_num = try findLastDigit(line);
    return first_num * 10 + last_num;
}

fn findFirstDigit(line: []const u8) !u8 {
    const char_index_maybe = std.mem.indexOfAny(u8, line, digit_chars);
    var name_index_maybe: ?usize = null;
    var name_value: u8 = 0;

    for (digits) |digit| {
        const index = std.mem.indexOf(u8, line, digit.name);
        if (index) |i| {
            if (name_index_maybe == null or i < name_index_maybe.?) {
                name_index_maybe = i;
                name_value = digit.value;
            }
        }
    }

    if (char_index_maybe) |char_index| {
        if (name_index_maybe) |name_index| {
            if (name_index < char_index) {
                return name_value;
            } else {
                return try parseDigit(line[char_index]);
            }
        } else {
            return try parseDigit(line[char_index]);
        }
    } else if (name_index_maybe) |_| {
        return name_value;
    } else {
        return error.NoDigitFound;
    }
}

fn findLastDigit(line: []const u8) !u8 {
    const char_index_maybe = std.mem.lastIndexOfAny(u8, line, digit_chars);
    var name_index_maybe: ?usize = null;
    var name_value: u8 = 0;

    for (digits) |digit| {
        const index = std.mem.lastIndexOf(u8, line, digit.name);
        if (index) |i| {
            if (name_index_maybe == null or i > name_index_maybe.?) {
                name_index_maybe = i;
                name_value = digit.value;
            }
        }
    }

    if (char_index_maybe) |char_index| {
        if (name_index_maybe) |name_index| {
            if (name_index > char_index) {
                return name_value;
            } else {
                return try parseDigit(line[char_index]);
            }
        } else {
            return try parseDigit(line[char_index]);
        }
    } else if (name_index_maybe) |_| {
        return name_value;
    } else {
        return error.NoDigitFound;
    }
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
