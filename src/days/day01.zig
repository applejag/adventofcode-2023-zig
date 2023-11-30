// SPDX-FileCopyrightText: 2023 Kalle Fagerberg
//
// SPDX-License-Identifier: BSD-3-Clause

const std = @import("std");

pub fn part1(allocator: std.mem.Allocator, input: []u8) !void {
    _ = allocator;

    std.debug.print("day01 part1 :)\n", .{});

    std.debug.print("Some text from input: {s}\n", .{input[0..50]});
}
