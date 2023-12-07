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

    var iter = iterateHands(input);
    while (try iter.next()) |hand| {
        try list.append(hand);
    }

    std.mem.sort(Hand, list.items, {}, Hand.sortLess);

    var sum: u64 = 0;
    for (list.items, 0..) |card, index| {
        sum += card.bid * (index + 1);
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
    try std.testing.expect(num == 6440);
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

    pub fn parse(cards: *const [5]u8) !HandType {
        var card_counts = [_]u4{0} ** 13;
        for (cards) |card| {
            card_counts[try cardIndex(card)] += 1;
        }
        var total_count: u32 = 0;
        for (card_counts, 0..) |count, index| {
            if (count == 5) {
                return HandType.fiveOfAKind;
            }
            if (count == 4) {
                return HandType.fourOfAKind;
            }
            if (count == 3) {
                if (std.mem.indexOfScalarPos(u4, &card_counts, index + 1, 2) != null) {
                    return HandType.fullHouse;
                }
                return HandType.threeOfAKind;
            }
            if (count == 2) {
                if (std.mem.indexOfScalarPos(u4, &card_counts, index + 1, 3) != null) {
                    return HandType.fullHouse;
                }
                if (std.mem.indexOfScalarPos(u4, &card_counts, index + 1, 2) != null) {
                    return HandType.twoPair;
                }
                return HandType.onePair;
            }
            total_count += 1;
        }
        if (total_count == 5) {
            return HandType.highCard;
        }
        return HandType.none;
    }

    pub fn less(a: HandType, b: HandType) bool {
        return @intFromEnum(a) < @intFromEnum(b);
    }
};

fn cardIndex(card: u8) !u8 {
    // card:  AKQJT98765432
    // index: 1119876543210
    //        210
    return switch (card) {
        '2'...'9' => card - '2',
        'T' => 8,
        'J' => 9,
        'Q' => 10,
        'K' => 11,
        'A' => 12,
        else => return error.InvalidArgument,
    };
}

const Hand = struct {
    hand_type: HandType,
    cards: *const [5]u8,
    bid: u32,

    pub fn parse(line: []const u8) !Hand {
        const cards: *const [5]u8 = line[0..5];

        return Hand{
            .hand_type = try HandType.parse(cards),
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
                const a_idx = cardIndex(a_card) catch return false;
                const b_idx = cardIndex(b_card) catch return false;
                return a_idx < b_idx;
            }
        }
        return false;
    }
};

const HandIterator = struct {
    line_iterator: std.mem.TokenIterator(u8, .scalar),

    pub fn next(self: *@This()) !?Hand {
        const line = self.line_iterator.next() orelse return null;
        return try Hand.parse(line);
    }
};

fn iterateHands(input: []const u8) HandIterator {
    return HandIterator{
        .line_iterator = std.mem.tokenizeScalar(u8, input, '\n'),
    };
}
