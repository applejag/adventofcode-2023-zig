// SPDX-FileCopyrightText: 2023 Kalle Fagerberg
//
// SPDX-License-Identifier: BSD-3-Clause

const std = @import("std");

pub fn part1(allocator: std.mem.Allocator, input: []const u8) !void {
    const sum = try part1Sum(allocator, input);
    std.log.info("Sum = {d}", .{sum});
}

fn part1Sum(allocator: std.mem.Allocator, input: []const u8) !u32 {
    const game_list = try parseGames(allocator, input);
    defer game_list.deinit();
    return sumPossibleGameIDs(game_list);
}

test "part1" {
    const sum = try part1Sum(std.testing.allocator,
        \\Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green
        \\Game 2: 1 blue, 2 green; 3 green, 4 blue, 1 red; 1 green, 1 blue
        \\Game 3: 8 green, 6 blue, 20 red; 5 blue, 4 red, 13 green; 5 green, 1 red
        \\Game 4: 1 green, 3 red, 6 blue; 3 green, 6 red; 3 green, 15 blue, 14 red
        \\Game 5: 6 red, 1 blue, 3 green; 2 blue, 1 red, 2 green
    );
    try std.testing.expectEqual(@as(u32, 8), sum);
}

pub fn part2(allocator: std.mem.Allocator, input: []const u8) !void {
    const sum = try part2Sum(allocator, input);
    std.log.info("Sum = {d}", .{sum});
}

fn part2Sum(allocator: std.mem.Allocator, input: []const u8) !u32 {
    const game_list = try parseGames(allocator, input);
    defer game_list.deinit();
    return sumPowerOfGames(game_list);
}

test "part2" {
    const sum = try part2Sum(std.testing.allocator,
        \\Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green
        \\Game 2: 1 blue, 2 green; 3 green, 4 blue, 1 red; 1 green, 1 blue
        \\Game 3: 8 green, 6 blue, 20 red; 5 blue, 4 red, 13 green; 5 green, 1 red
        \\Game 4: 1 green, 3 red, 6 blue; 3 green, 6 red; 3 green, 15 blue, 14 red
        \\Game 5: 6 red, 1 blue, 3 green; 2 blue, 1 red, 2 green
    );
    try std.testing.expectEqual(@as(u32, 2286), sum);
}

fn sumPossibleGameIDs(game_list: GameList) u32 {
    const max = Set{
        .red_cubes = 12,
        .green_cubes = 13,
        .blue_cubes = 14,
    };

    var sum: u32 = 0;
    for (game_list.games.items) |game| {
        const too_many_cubes = for (game.sets.items) |set| {
            if (set.red_cubes > max.red_cubes or
                set.green_cubes > max.green_cubes or
                set.blue_cubes > max.blue_cubes)
            {
                std.log.info("Game {d} has too many cubes", .{game.id});
                break true;
            }
        } else false;

        if (!too_many_cubes) {
            sum += game.id;
        }
    }

    return sum;
}

fn sumPowerOfGames(game_list: GameList) u32 {
    var sum: u32 = 0;
    for (game_list.games.items) |game| {
        sum += powerOfGame(game);
    }
    return sum;
}

fn powerOfGame(game: Game) u32 {
    var max = game.sets.items[0];
    for (game.sets.items[1..]) |set| {
        max.red_cubes = @max(max.red_cubes, set.red_cubes);
        max.green_cubes = @max(max.green_cubes, set.green_cubes);
        max.blue_cubes = @max(max.blue_cubes, set.blue_cubes);
    }
    return @as(u32, max.red_cubes) *
        @as(u32, max.green_cubes) *
        @as(u32, max.blue_cubes);
}

const Set = struct {
    red_cubes: u8,
    green_cubes: u8,
    blue_cubes: u8,
};

const Game = struct {
    id: u8,
    sets: std.ArrayList(Set),

    pub fn deinit(self: @This()) void {
        self.sets.deinit();
    }
};

const GameList = struct {
    games: std.ArrayList(Game),

    pub fn deinit(self: @This()) void {
        for (self.games.items) |game| {
            game.deinit();
        }
        self.games.deinit();
    }
};

fn parseGames(allocator: std.mem.Allocator, input: []const u8) !GameList {
    var list = std.ArrayList(Game).init(allocator);
    errdefer list.deinit();

    var lines = iterLines(input);
    while (lines.next()) |line| {
        try list.append(try parseGame(allocator, line));
    }

    return GameList{
        .games = list,
    };
}

fn parseGame(allocator: std.mem.Allocator, line: []const u8) !Game {
    const game_prefix = "Game ";
    if (!hasPrefix(line, game_prefix)) {
        return error.InvalidFormat;
    }
    const colon_index = std.mem.indexOfScalar(u8, line, ':');
    if (colon_index == null) {
        return error.InvalidFormat;
    }
    const game_id_str = line[game_prefix.len..colon_index.?];
    const game_id = try std.fmt.parseUnsigned(u8, game_id_str, 10);

    // +2 to skip both the colon and the space after
    const sets_str = line[colon_index.? + 2 .. line.len];

    return Game{
        .id = game_id,
        .sets = try parseSets(allocator, sets_str),
    };
}

fn parseSets(allocator: std.mem.Allocator, sets_str: []const u8) !std.ArrayList(Set) {
    const delimiter = "; ";
    const sets_count = std.mem.count(u8, sets_str, delimiter) + 1;
    var list = try std.ArrayList(Set).initCapacity(allocator, sets_count);
    errdefer list.deinit();

    var sets_iter = std.mem.split(u8, sets_str, delimiter);
    while (sets_iter.next()) |set| {
        try list.append(try parseSet(set));
    }

    return list;
}

fn parseSet(set_str: []const u8) !Set {
    var set = Set{
        .red_cubes = 0,
        .green_cubes = 0,
        .blue_cubes = 0,
    };
    var cubes_iter = std.mem.split(u8, set_str, ", ");
    while (cubes_iter.next()) |cubes_str| {
        const space_index = std.mem.indexOfScalar(u8, cubes_str, ' ');
        if (space_index == null) {
            return error.InvalidFormat;
        }
        const count_str = cubes_str[0..space_index.?];
        const count = try std.fmt.parseUnsigned(u8, count_str, 10);
        const color_char = cubes_str[space_index.? + 1];
        switch (color_char) {
            'r' => set.red_cubes += count,
            'g' => set.green_cubes += count,
            'b' => set.blue_cubes += count,
            else => return error.UnknownColor,
        }
    }
    return set;
}

fn iterLines(multiline: []const u8) std.mem.SplitIterator(u8, .sequence) {
    const stripped = std.mem.trim(u8, multiline, "\n ");
    const lines_iter = std.mem.split(u8, stripped, "\n");
    return lines_iter;
}

fn hasPrefix(value: []const u8, prefix: []const u8) bool {
    if (value.len < prefix.len) {
        return false;
    }
    return std.mem.eql(u8, value[0..prefix.len], prefix);
}
