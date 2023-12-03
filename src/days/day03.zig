// SPDX-FileCopyrightText: 2023 Kalle Fagerberg
//
// SPDX-License-Identifier: BSD-3-Clause

const std = @import("std");

pub fn part1(allocator: std.mem.Allocator, input: []const u8) !void {
    _ = allocator;
    const sum = try part1Sum(input);
    std.log.info("Sum = {d}", .{sum});
}

fn part1Sum(input: []const u8) !u32 {
    var sum: u32 = 0;
    const slice = try Slice2D.parse(input);
    var number_iter = slice.iterNumbers();
    while (number_iter.next()) |num| {
        const min_x = if (num.x == 0) num.x else num.x - 1;
        const min_y = if (num.y == 0) num.y else num.y - 1;
        // We're interested in neighbors, so some +1 here and there.
        // Zig for range loop has exclusive end.
        // For x, we get the extra +1 from the num.range.len.
        // For y, we have +2 instead of +1.
        const is_part_number = outer: for (min_x..num.x + num.range.len + 1) |x| {
            for (min_y..num.y + 2) |y| {
                if (slice.get(x, y)) |value| {
                    if (value != '.' and !isDigit(value)) {
                        break :outer true;
                    }
                }
            }
        } else false;

        if (!is_part_number) {
            continue;
        }

        const parsed = try std.fmt.parseUnsigned(u32, num.range, 10);
        sum += parsed;
    }
    return sum;
}

test "part1" {
    const sum = try part1Sum(
        \\467..114..
        \\...*......
        \\..35..633.
        \\......#...
        \\617*......
        \\.....+.58.
        \\..592.....
        \\......755.
        \\...$.*....
        \\.664.598..
    );
    try std.testing.expect(sum == 4361);
}

test "Slice2D.get" {
    const slice = try Slice2D.parse(
        \\467..114..
        \\...*......
        \\..35..633.
        \\......#...
        \\617*......
        \\.....+.58.
        \\..592.....
        \\......755.
        \\...$.*....
        \\.664.598..
    );
    var list = try std.ArrayList(u8).initCapacity(std.testing.allocator, slice.slice.len);
    defer list.deinit();
    for (0..slice.height) |y| {
        for (0..slice.width) |x| {
            try list.append(slice.get(x, y) orelse 0);
        }
    }
    const expected: []const u8 =
        "467..114.." ++
        "...*......" ++
        "..35..633." ++
        "......#..." ++
        "617*......" ++
        ".....+.58." ++
        "..592....." ++
        "......755." ++
        "...$.*...." ++
        ".664.598..";
    try std.testing.expectEqualSlices(u8, expected, list.items);
}

test "Slice2D.iter" {
    const slice = try Slice2D.parse(
        \\467..114..
        \\...*......
        \\..35..633.
        \\......#...
        \\617*......
        \\.....+.58.
        \\..592.....
        \\......755.
        \\...$.*....
        \\.664.598..
    );
    var list = try std.ArrayList(u8).initCapacity(std.testing.allocator, slice.slice.len);
    defer list.deinit();
    var iter = slice.iter();
    while (iter.next()) |pos| {
        try list.append(pos.value);
    }
    const expected: []const u8 =
        "467..114.." ++
        "...*......" ++
        "..35..633." ++
        "......#..." ++
        "617*......" ++
        ".....+.58." ++
        "..592....." ++
        "......755." ++
        "...$.*...." ++
        ".664.598..";
    try std.testing.expectEqualSlices(u8, expected, list.items);
}

test "Slice2D.range" {
    const slice = try Slice2D.parse(
        \\467..114..
        \\...*......
        \\..35..633.
        \\......#...
        \\617*......
        \\.....+.58.
        \\..592.....
        \\......755.
        \\...$.*....
        \\.664.598..
    );
    try std.testing.expectEqualStrings("467", try slice.range(0, 0, 3));
    try std.testing.expectEqualStrings("35", try slice.range(2, 2, 2));
    try std.testing.expectEqualStrings("598..", try slice.range(5, 9, 5));

    try std.testing.expectError(error.InvalidArgument, slice.range(5, 9, 6));
}

test "Slice2D.iterNumbers" {
    const slice = try Slice2D.parse(
        \\467..114..
        \\...*.....1
        \\..35..633.
        \\......#...
        \\617*......
        \\.....+.58.
        \\..592.....
        \\.......755
        \\120$.*....
        \\.664.598..
    );
    var list = std.ArrayList([]const u8).init(std.testing.allocator);
    defer list.deinit();
    var number_iter = slice.iterNumbers();
    while (number_iter.next()) |num| {
        try list.append(num.range);
    }
    const expected: []const u8 =
        \\467
        \\114
        \\1
        \\35
        \\633
        \\617
        \\58
        \\592
        \\755
        \\120
        \\664
        \\598
    ;
    const actual = try std.mem.join(std.testing.allocator, "\n", list.items);
    defer std.testing.allocator.free(actual);

    try std.testing.expectEqualStrings(expected, actual);
}

const Slice2D = struct {
    width: usize,
    height: usize,
    slice: []const u8,

    pub fn parse(input: []const u8) !Slice2D {
        const stripped = std.mem.trim(u8, input, "\n ");
        var lines_iter = std.mem.splitScalar(u8, stripped, '\n');

        const first_line = lines_iter.next();
        if (first_line == null) {
            return error.InvalidArgument;
        }
        const width = first_line.?.len;
        var height: usize = 1;

        while (lines_iter.next()) |line| {
            height += 1;
            if (line.len != width) {
                return error.InvalidArgument;
            }
        }

        return Slice2D{
            .width = width,
            .height = height,
            .slice = stripped,
        };
    }

    pub fn lines(self: @This()) std.mem.SplitIterator(u8, .scalar) {
        return std.mem.splitScalar(u8, self.slice, '\n');
    }

    pub fn index(self: @This(), x: usize, y: usize) ?usize {
        if (x < 0 or x >= self.width) {
            return null;
        }
        if (y < 0 or y >= self.height) {
            return null;
        }
        // An extra +y to skip over the \n chars
        return x + y * self.height + y;
    }

    pub fn get(self: @This(), x: usize, y: usize) ?u8 {
        if (self.index(x, y)) |i| {
            return self.slice[i];
        }
        return null;
    }

    pub fn range(self: @This(), x: usize, y: usize, len: usize) ![]const u8 {
        if (x < 0 or x > self.width) {
            return error.InvalidArgument;
        }
        if (y < 0 or y > self.height) {
            return error.InvalidArgument;
        }
        if (len <= 0 or x + len > self.width) {
            return error.InvalidArgument;
        }
        // An extra +y to skip over the \n chars
        const i = x + y * self.height + y;
        return self.slice[i .. i + len];
    }

    pub fn iter(self: @This()) PosIter {
        return PosIter{
            .slice = self,
            .x = 0,
            .y = 0,
        };
    }

    const PosIter = struct {
        slice: Slice2D,
        x: usize,
        y: usize,

        const Pos = struct {
            value: u8,
            x: usize,
            y: usize,
        };

        pub fn next(self: *@This()) ?Pos {
            const pos = Pos{
                .value = self.slice.get(self.x, self.y) orelse {
                    return null;
                },
                .x = self.x,
                .y = self.y,
            };

            self.x += 1;
            if (self.x >= self.slice.width) {
                self.y += 1;
                self.x = 0;
            }

            return pos;
        }
    };

    pub fn iterNumbers(self: @This()) NumberIter {
        return NumberIter{
            .pos_iter = self.iter(),
        };
    }

    const NumberIter = struct {
        pos_iter: PosIter,

        const Number = struct {
            range: []const u8,
            x: usize,
            y: usize,
        };

        pub fn next(self: *@This()) ?Number {
            var start: ?PosIter.Pos = null;
            var end: ?PosIter.Pos = null;
            while (self.pos_iter.next()) |pos| {
                if (isDigit(pos.value)) {
                    if (start == null) {
                        start = pos;
                    }
                    end = pos;

                    // Return if at end of line
                    if (pos.x + 1 == self.pos_iter.slice.width) {
                        if (self.returnNumber(start.?, end.?)) |num| {
                            return num;
                        }
                    }
                } else if (start != null) {
                    if (self.returnNumber(start.?, end.?)) |num| {
                        return num;
                    }
                }
            }
            if (start != null) {
                if (self.returnNumber(start.?, end.?)) |num| {
                    return num;
                }
            }

            return null;
        }

        fn returnNumber(self: @This(), start: PosIter.Pos, end: PosIter.Pos) ?Number {
            const len = end.x - start.x + 1;
            const slice = self.pos_iter.slice.range(start.x, start.y, len) catch {
                return null;
            };
            return Number{
                .range = slice,
                .x = start.x,
                .y = start.y,
            };
        }
    };
};

fn parseDigit(digit: u8) !u8 {
    return switch (digit) {
        '0'...'9' => digit - '0',
        else => error.InvalidArgument,
    };
}

fn isDigit(digit: u8) bool {
    return switch (digit) {
        '0'...'9' => true,
        else => false,
    };
}
