// SPDX-FileCopyrightText: 2023 Kalle Fagerberg
//
// SPDX-License-Identifier: BSD-3-Clause

const std = @import("std");

pub fn part1(allocator: std.mem.Allocator, input: []const u8) !void {
    const sum = try part1Sum(allocator, input);
    std.log.info("Sum = {d}", .{sum});
}

fn part1Sum(allocator: std.mem.Allocator, input: []const u8) !u32 {
    const card_list = try CardList.parse(allocator, input);
    defer card_list.deinit();

    var sum: u32 = 0;
    for (card_list.cards.items) |card| {
        var points: u16 = 0;
        for (card.winning_numbers.items) |winning_num| {
            if (std.mem.indexOfScalar(u8, card.my_numbers.items, winning_num) != null) {
                points += if (points == 0) 1 else points;
            }
        }
        sum += points;
    }

    return sum;
}

test "part1" {
    const sum = try part1Sum(std.testing.allocator,
        \\Card 1: 41 48 83 86 17 | 83 86  6 31 17  9 48 53
        \\Card 2: 13 32 20 16 61 | 61 30 68 82 17 32 24 19
        \\Card 3:  1 21 53 59 44 | 69 82 63 72 16 21 14  1
        \\Card 4: 41 92 73 84 69 | 59 84 76 51 58  5 54 83
        \\Card 5: 87 83 26 28 32 | 88 30 70 12 93 22 82 36
        \\Card 6: 31 18 13 56 72 | 74 77 10 23 35 67 36 11
    );
    try std.testing.expect(sum == 13);
}

const CardList = struct {
    cards: std.ArrayList(Card),

    pub fn deinit(self: @This()) void {
        for (self.cards.items) |card| {
            card.deinit();
        }
        self.cards.deinit();
    }

    pub fn parse(allocator: std.mem.Allocator, input: []const u8) !CardList {
        var list = std.ArrayList(Card).init(allocator);
        errdefer list.deinit();

        const stripped = std.mem.trim(u8, input, "\n ");
        var lines_iter = std.mem.splitScalar(u8, stripped, '\n');
        while (lines_iter.next()) |line| {
            const card = try Card.parse(allocator, line);
            errdefer card.deinit();
            try list.append(card);
        }

        return CardList{
            .cards = list,
        };
    }
};

const Card = struct {
    id: u8,
    winning_numbers: std.ArrayList(u8),
    my_numbers: std.ArrayList(u8),

    pub fn deinit(self: @This()) void {
        self.winning_numbers.deinit();
        self.my_numbers.deinit();
    }

    pub fn parse(allocator: std.mem.Allocator, input: []const u8) !Card {
        var card = Card{
            .id = 0,
            .winning_numbers = try std.ArrayList(u8).initCapacity(allocator, 10),
            .my_numbers = try std.ArrayList(u8).initCapacity(allocator, 25),
        };
        errdefer card.deinit();

        const prefix: []const u8 = "Card ";
        const colon_index = std.mem.indexOfScalar(u8, input, ':') orelse {
            return error.InvalidArgument;
        };
        const id_str = std.mem.trimLeft(u8, input[prefix.len..colon_index], " ");
        card.id = try std.fmt.parseUnsigned(u8, id_str, 10);

        const numbers_str = input[colon_index + 1 ..];
        const pipe_index = std.mem.indexOfScalar(u8, numbers_str, '|') orelse {
            return error.InvalidArgument;
        };

        const winning_numbers_str = numbers_str[0..pipe_index];
        const my_numbers_str = numbers_str[pipe_index + 1 ..];

        var winning_numbers_iter = std.mem.tokenizeScalar(u8, winning_numbers_str, ' ');
        while (winning_numbers_iter.next()) |num_str| {
            const num = try std.fmt.parseUnsigned(u8, num_str, 10);
            try card.winning_numbers.append(num);
        }

        var my_numbers_iter = std.mem.tokenizeScalar(u8, my_numbers_str, ' ');
        while (my_numbers_iter.next()) |num_str| {
            const num = try std.fmt.parseUnsigned(u8, num_str, 10);
            try card.my_numbers.append(num);
        }

        return card;
    }
};

test "Card.parse" {
    const card = try Card.parse(std.testing.allocator, "Card  23: 41 48 83 86 17 | 83 86  6 31 17  9 48 53");
    defer card.deinit();
    try std.testing.expect(card.id == 23);
    try std.testing.expectEqualSlices(u8, &[_]u8{ 41, 48, 83, 86, 17 }, card.winning_numbers.items);
    try std.testing.expectEqualSlices(u8, &[_]u8{ 83, 86, 6, 31, 17, 9, 48, 53 }, card.my_numbers.items);
}
