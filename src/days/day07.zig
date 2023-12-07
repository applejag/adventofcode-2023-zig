// SPDX-FileCopyrightText: 2023 Kalle Fagerberg
//
// SPDX-License-Identifier: BSD-3-Clause

const std = @import("std");

pub fn part1(allocator: std.mem.Allocator, input: []const u8) !void {
    const num = try part1Num(allocator, input);
    std.log.info("Num = {d}", .{num});
}

fn part1Num(allocator: std.mem.Allocator, input: []const u8) !u64 {
    var list = std.ArrayList(Hand).init(allocator);
    defer list.deinit();

    var iter = iterateHands(input, .{});
    while (try iter.next()) |hand| {
        try list.append(hand);
    }

    std.mem.sort(Hand, list.items, {}, Hand.sortLess);

    var sum: u64 = 0;
    for (list.items, 0..) |hand, index| {
        sum += hand.bid * (index + 1);
    }
    return sum;
}

test "part1" {
    const num = try part1Num(std.testing.allocator,
        \\32T3K 765
        \\T55J5 684
        \\KK677 28
        \\KTJJT 220
        \\QQQJA 483
    );
    try std.testing.expectEqual(@as(u64, 6440), num);
}

pub fn part2(allocator: std.mem.Allocator, input: []const u8) !void {
    const num = try part2Num(allocator, input);
    std.log.info("Num = {d}", .{num});
}

fn part2Num(allocator: std.mem.Allocator, input: []const u8) !u64 {
    var list = std.ArrayList(Hand).init(allocator);
    defer list.deinit();

    var iter = iterateHands(input, .{ .j_is_wildcard = true });
    while (try iter.next()) |hand| {
        try list.append(hand);
    }

    std.mem.sort(Hand, list.items, {}, Hand.sortLess);

    var sum: u64 = 0;
    for (list.items, 0..) |hand, index| {
        sum += hand.bid * (index + 1);
    }
    return sum;
}

test "part2" {
    const num = try part2Num(std.testing.allocator,
        \\32T3K 765
        \\T55J5 684
        \\KK677 28
        \\KTJJT 220
        \\QQQJA 483
    );
    try std.testing.expectEqual(@as(u64, 5905), num);
}

const HandType = enum {
    none,
    highCard,
    onePair,
    twoPair,
    threeOfAKind,
    fullHouse,
    fourOfAKind,
    fiveOfAKind,

    pub fn parse(cards: [5]Card) HandType {
        var card_counts = [_]u4{0} ** 14;
        var wildcard_count: u4 = 0;
        for (cards) |card| {
            if (card == .wildcard) {
                wildcard_count += 1;
            } else {
                card_counts[card.index()] += 1;
            }
        }
        if (wildcard_count > 0) {
            for (&card_counts) |*value| {
                if (value.* > 0) {
                    value.* += wildcard_count;
                }
            }
        }
        var total_count: u32 = 0;
        for (card_counts) |count| {
            if (count >= 5) {
                return HandType.fiveOfAKind;
            } else if (count > 0) {
                total_count += 1;
            }
        }
        if (std.mem.indexOfScalar(u4, &card_counts, 4) != null) {
            return HandType.fourOfAKind;
        }
        if (std.mem.indexOfScalar(u4, &card_counts, 3)) |_| {
            if (std.mem.indexOfScalar(u4, &card_counts, 2)) |_| {
                return HandType.fullHouse;
            }
            return HandType.threeOfAKind;
        }
        if (std.mem.indexOfScalar(u4, &card_counts, 2)) |index| {
            if (std.mem.indexOfScalarPos(u4, &card_counts, index + 1, 2)) |_| {
                return HandType.twoPair;
            }
            return HandType.onePair;
        }
        if (total_count >= 5) {
            return HandType.highCard;
        }
        return HandType.none;
    }

    pub fn less(a: HandType, b: HandType) bool {
        return @intFromEnum(a) < @intFromEnum(b);
    }
};

test "HandType.parse: 32T3K" {
    const hand_type = HandType.parse([_]Card{ ._3, ._2, .t, ._3, .k });
    try std.testing.expectEqual(HandType.onePair, hand_type);
}

test "HandType.parse: T55J5 part1" {
    const hand_type = HandType.parse([_]Card{ .t, ._5, ._5, .j, ._5 });
    try std.testing.expectEqual(HandType.threeOfAKind, hand_type);
}

test "HandType.parse: T55J5 part2" {
    const hand_type = HandType.parse([_]Card{ .t, ._5, ._5, .wildcard, ._5 });
    try std.testing.expectEqual(HandType.fourOfAKind, hand_type);
}

test "HandType.parse: QQQJA part1" {
    const hand_type = HandType.parse([_]Card{ .q, .q, .q, .j, .a });
    try std.testing.expectEqual(HandType.threeOfAKind, hand_type);
}

test "HandType.parse: QQQJA part2" {
    const hand_type = HandType.parse([_]Card{ .q, .q, .q, .wildcard, .a });
    try std.testing.expectEqual(HandType.fourOfAKind, hand_type);
}

const Card = enum {
    _2,
    _3,
    _4,
    _5,
    _6,
    _7,
    _8,
    _9,
    t,
    j,
    wildcard,
    q,
    k,
    a,

    pub fn parse(input: u8, options: HandParseOptions) !Card {
        return switch (input) {
            '2' => ._2,
            '3' => ._3,
            '4' => ._4,
            '5' => ._5,
            '6' => ._6,
            '7' => ._7,
            '8' => ._8,
            '9' => ._9,
            'T' => .t,
            'J' => if (options.j_is_wildcard) .wildcard else .j,
            'Q' => .q,
            'K' => .k,
            'A' => .a,
            else => return error.InvalidArgument,
        };
    }

    pub fn index(self: @This()) usize {
        return @intFromEnum(self);
    }
};

const HandParseOptions = struct {
    j_is_wildcard: bool = false,
};

const Hand = struct {
    hand_type: HandType,
    cards: [5]Card,
    bid: u32,

    pub fn parse(line: []const u8, options: HandParseOptions) !Hand {
        var cards: [5]Card = undefined;
        for (line[0..5], 0..) |card, index| {
            cards[index] = try Card.parse(card, options);
        }

        return Hand{
            .hand_type = HandType.parse(cards),
            .cards = cards,
            .bid = try std.fmt.parseUnsigned(u32, line[6..], 10),
        };
    }

    pub fn sortLess(_: void, a: Hand, b: Hand) bool {
        if (a.hand_type != b.hand_type) {
            return HandType.less(a.hand_type, b.hand_type);
        }
        for (a.cards, b.cards) |a_card, b_card| {
            if (a_card != b_card) {
                return a_card.index() < b_card.index();
            }
        }
        return false;
    }
};

const HandIterator = struct {
    options: HandParseOptions,
    line_iterator: std.mem.TokenIterator(u8, .scalar),

    pub fn next(self: *@This()) !?Hand {
        const line = self.line_iterator.next() orelse return null;
        return try Hand.parse(line, self.options);
    }
};

fn iterateHands(input: []const u8, options: HandParseOptions) HandIterator {
    return HandIterator{
        .options = options,
        .line_iterator = std.mem.tokenizeScalar(u8, input, '\n'),
    };
}
