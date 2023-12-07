// SPDX-FileCopyrightText: 2023 Kalle Fagerberg
//
// SPDX-License-Identifier: BSD-3-Clause

const std = @import("std");
const flags = @import("flags.zig");

const Part = enum(u2) {
    part1 = 1,
    part2 = 2,
};

const Args = struct {
    day: u32,
    part: Part,
};

const default_args = Args{
    .day = 0,
    .part = .part1,
};

const days = [_]type{
    @import("days/day01.zig"),
    @import("days/day02.zig"),
    @import("days/day03.zig"),
    @import("days/day04.zig"),
    @import("days/day05.zig"),
    @import("days/day06.zig"),
    @import("days/day07.zig"),
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var args_iter = try std.process.argsWithAllocator(allocator);
    defer args_iter.deinit();
    const args = try (parseArgs(args_iter) catch |err| if (err == error.MissingArgument) {
        return;
    } else err);

    const input = try getInputFile(allocator, args.day);
    defer allocator.free(input);

    std.log.info("Running day {d:0>2} part {d}", .{ args.day, @intFromEnum(args.part) });

    try runDay(allocator, args, input);
}

fn getInputFile(allocator: std.mem.Allocator, day: u32) ![]u8 {
    const day_formatted = try std.fmt.allocPrint(allocator, "day{d:0>2}.txt", .{day});
    defer allocator.free(day_formatted);

    const path = try std.fs.path.join(allocator, &[_][]const u8{ "input", day_formatted });
    defer allocator.free(path);

    const file = std.fs.cwd().openFile(path, .{}) catch |err| {
        if (err == error.FileNotFound) {
            std.log.err("Tried to open file: {s}", .{path});
        }
        return err;
    };
    defer file.close();

    const megabyte = 1000 * 1000;
    return try file.readToEndAlloc(allocator, megabyte);
}

fn runDay(allocator: std.mem.Allocator, args: Args, input: []u8) !void {
    return switch (args.day - 1) {
        inline 0...days.len - 1 => |index| runPart(days[index], allocator, args.part, input),
        else => error.OutOfRange,
    };
}

fn runPart(comptime day: type, allocator: std.mem.Allocator, part: Part, input: []u8) !void {
    return switch (part) {
        .part1 => {
            if (@hasDecl(day, "part1")) {
                return day.part1(allocator, input);
            }
            std.log.err("This day does not have part 1 implemented.", .{});
            return error.NotImplemented;
        },
        .part2 => {
            if (@hasDecl(day, "part2")) {
                return day.part2(allocator, input);
            }
            std.log.err("This day does not have part 2 implemented.", .{});
            return error.NotImplemented;
        },
    };
}

fn printUsage(exe_path: []const u8) void {
    const exe_basename = std.fs.path.basename(exe_path);
    std.log.info(
        \\Usage: {?s} [flags]
        \\
        \\Flags:
        \\  -d, --day=int    Advent calendar day. Number between 1 and {d}
        \\  -p, --part=int   Part of day, 1 or 2 (default 1)
        \\
    , .{ exe_basename, days.len });
}

fn parseArgs(args_iter: std.process.ArgIterator) !Args {
    var flags_iter = flags.iterate(args_iter);

    var exe_name: []const u8 = "adventofcode-2023-zig";
    var flag_day: ?[]const u8 = null;
    var flag_part: ?[]const u8 = null;

    while (flags_iter.next()) |value| {
        switch (value) {
            .flag => |flag| {
                if (std.mem.eql(u8, flag.key, "-d") or
                    std.mem.eql(u8, flag.key, "--day"))
                {
                    flag_day = flag.value;
                } else if (std.mem.eql(u8, flag.key, "-p") or
                    std.mem.eql(u8, flag.key, "--part"))
                {
                    flag_part = flag.value;
                } else {
                    printUsage(exe_name);
                    std.log.err("Unknown flag: {s}", .{flag.key});
                    return error.UnexpectedFlag;
                }
            },
            .arg => |arg| {
                if (arg.position == 0) {
                    exe_name = arg.value;
                    continue;
                }
                std.log.err("Arguments not allowed", .{});
                return error.UnexpectedArgument;
            },
        }
    }

    if (flag_day == null) {
        printUsage(exe_name);
        std.log.err("Missing required --day flag", .{});
        return error.MissingArgument;
    }
    const day_str = flag_day.?;

    const day = std.fmt.parseUnsigned(u32, day_str, 10) catch |err| {
        printUsage(exe_name);
        std.log.err("Failed to parse --day flag: {}", .{err});
        return error.InvalidArgument;
    };

    if (day <= 0 or day > days.len) {
        printUsage(exe_name);
        std.log.err("Flag --day was out of range (1-{d})", .{days.len});
        return error.InvalidArgument;
    }

    var args = default_args;
    args.day = day;

    if (flag_part) |part_str| {
        const part = std.fmt.parseUnsigned(u32, part_str, 10) catch |err| {
            printUsage(exe_name);
            std.log.err("Failed to parse --part flag: {}", .{err});
            return error.InvalidArgument;
        };

        args.part = switch (part) {
            1 => .part1,
            2 => .part2,
            else => {
                printUsage(exe_name);
                std.log.err("Flag --part was out of range (1-2)", .{});
                return error.InvalidArgument;
            },
        };
    }

    return args;
}

test {
    std.testing.refAllDecls(@This());
}
