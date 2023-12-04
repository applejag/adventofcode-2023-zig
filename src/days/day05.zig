// SPDX-FileCopyrightText: 2023 Kalle Fagerberg
//
// SPDX-License-Identifier: BSD-3-Clause

const std = @import("std");

pub fn part1(allocator: std.mem.Allocator, input: []const u8) !void {
    const sum = try part1Num(allocator, input);
    std.log.info("Lowest location num = {d}", .{sum});
}

fn part1Num(allocator: std.mem.Allocator, input: []const u8) !u32 {
    const almanac = try Almanac.parse(allocator, input);
    defer almanac.deinit();

    const source_slice = try allocator.alloc(u32, almanac.seeds.len);
    defer allocator.free(source_slice);
    @memcpy(source_slice, almanac.seeds);

    std.mem.sort(u32, source_slice, {}, u32LessThan);

    var dest_slice = try allocator.alloc(u32, almanac.seeds.len);
    defer allocator.free(dest_slice);

    for (almanac.maps) |map| {
        @memcpy(dest_slice, source_slice);

        for (map.ranges) |map_range| {
            for (source_slice, 0..) |source_value, i| {
                if (source_value < map_range.source_start or
                    source_value >= map_range.source_start + map_range.range_len)
                {
                    continue;
                }
                const delta = source_value - map_range.source_start;
                dest_slice[i] = map_range.dest_start + delta;
            }
        }

        @memcpy(source_slice, dest_slice);
    }

    const smallest_dist = std.mem.min(u32, dest_slice);
    return smallest_dist;
}

test "part1" {
    const num = try part1Num(std.testing.allocator,
        \\seeds: 79 14 55 13
        \\
        \\seed-to-soil map:
        \\50 98 2
        \\52 50 48
        \\
        \\soil-to-fertilizer map:
        \\0 15 37
        \\37 52 2
        \\39 0 15
        \\
        \\fertilizer-to-water map:
        \\49 53 8
        \\0 11 42
        \\42 0 7
        \\57 7 4
        \\
        \\water-to-light map:
        \\88 18 7
        \\18 25 70
        \\
        \\light-to-temperature map:
        \\45 77 23
        \\81 45 19
        \\68 64 13
        \\
        \\temperature-to-humidity map:
        \\0 69 1
        \\1 0 69
        \\
        \\humidity-to-location map:
        \\60 56 37
        \\56 93 4
    );
    try std.testing.expectEqual(@as(u32, 35), num);
}

fn u32LessThan(_: void, lhs: u32, rhs: u32) bool {
    return lhs < rhs;
}

const Almanac = struct {
    allocator: std.mem.Allocator,
    seeds: []const u32,
    maps: []const Mapping,

    pub fn deinit(self: @This()) void {
        for (self.maps) |map| {
            map.deinit();
        }
        self.allocator.free(self.seeds);
        self.allocator.free(self.maps);
    }

    pub fn parse(allocator: std.mem.Allocator, input: []const u8) !Almanac {
        var iter = std.mem.tokenizeSequence(u8, input, "\n\n");
        const seeds = iter.next() orelse return error.InvalidArgument;

        var seeds_iter = std.mem.tokenizeScalar(u8, seeds, ' ');
        _ = seeds_iter.next(); // ignore first "seeds:" part

        var seeds_list = std.ArrayList(u32).init(allocator);
        defer seeds_list.deinit();

        while (seeds_iter.next()) |seed| {
            try seeds_list.append(try std.fmt.parseUnsigned(u32, seed, 10));
        }

        var maps_list = std.ArrayList(Mapping).init(allocator);
        defer maps_list.deinit();

        while (iter.next()) |chunk| {
            const mapping = try Mapping.parse(allocator, chunk);
            errdefer mapping.deinit();
            try maps_list.append(mapping);
        }

        return Almanac{
            .allocator = allocator,
            .seeds = try seeds_list.toOwnedSlice(),
            .maps = try maps_list.toOwnedSlice(),
        };
    }
};

const Mapping = struct {
    allocator: std.mem.Allocator,
    name: []const u8,
    ranges: []const MappingRange,

    pub fn deinit(self: @This()) void {
        self.allocator.free(self.ranges);
    }

    pub fn parse(allocator: std.mem.Allocator, input: []const u8) !Mapping {
        const trimmed = std.mem.trim(u8, input, " \n");
        var iter = std.mem.splitScalar(u8, trimmed, '\n');
        const header = iter.next() orelse return error.InvalidArgument;
        var header_iter = std.mem.splitScalar(u8, header, ' ');
        const name = header_iter.next() orelse return error.InvalidArgument;

        var list = std.ArrayList(MappingRange).init(allocator);
        defer list.deinit();

        while (iter.next()) |line| {
            try list.append(try MappingRange.parse(line));
        }

        return Mapping{
            .allocator = allocator,
            .name = name,
            .ranges = try list.toOwnedSlice(),
        };
    }
};

const MappingRange = struct {
    dest_start: u32,
    source_start: u32,
    range_len: u32,

    pub fn parse(input: []const u8) !MappingRange {
        var iter = std.mem.tokenizeScalar(u8, input, ' ');
        const dest_start = iter.next() orelse return error.InvalidArgument;
        const source_start = iter.next() orelse return error.InvalidArgument;
        const range_len = iter.next() orelse return error.InvalidArgument;
        return MappingRange{
            .dest_start = try std.fmt.parseUnsigned(u32, dest_start, 10),
            .source_start = try std.fmt.parseUnsigned(u32, source_start, 10),
            .range_len = try std.fmt.parseUnsigned(u32, range_len, 10),
        };
    }
};
