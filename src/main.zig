// SPDX-FileCopyrightText: 2023 Kalle Fagerberg
//
// SPDX-License-Identifier: BSD-3-Clause

const std = @import("std");

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
    struct {}, // placeholder for day 03
    struct {}, // placeholder for day 04
    struct {}, // placeholder for day 05
    struct {}, // placeholder for day 06
    struct {}, // placeholder for day 07
    struct {}, // placeholder for day 08
    struct {}, // placeholder for day 09
    struct {}, // placeholder for day 10
    struct {}, // placeholder for day 11
    struct {}, // placeholder for day 12
    struct {}, // placeholder for day 13
    struct {}, // placeholder for day 14
    struct {}, // placeholder for day 15
    struct {}, // placeholder for day 16
    struct {}, // placeholder for day 17
    struct {}, // placeholder for day 18
    struct {}, // placeholder for day 19
    struct {}, // placeholder for day 20
    struct {}, // placeholder for day 21
    struct {}, // placeholder for day 22
    struct {}, // placeholder for day 23
    struct {}, // placeholder for day 24
    struct {}, // placeholder for day 25
};

pub fn main() !void {
    const arg_day = nthArg(1);
    const arg_part = nthArg(2);
    if (arg_day == null) {
        printUsage();
        return;
    }

    const args = try parseArgs(arg_day, arg_part);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

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

fn printUsage() void {
    var exe_path_arg = nthArg(0);
    if (exe_path_arg) |*exe_path| {
        exe_path.* = std.fs.path.basename(exe_path.*);
    }
    std.log.info(
        \\Usage: {?s} <day> [part]
        \\
        \\Arguments:
        \\  day    Advent calendar day. Number between 1 and {d}
        \\  part   Part of day, 1 or 2 (default 1)
    , .{ exe_path_arg, days.len });
}

fn parseArgs(arg_day: ?[]const u8, arg_part: ?[]const u8) !Args {
    if (arg_day == null) {
        std.log.err("Missing <day> argument", .{});
        printUsage();
        return error.MissingArgument;
    }
    const day_str = arg_day.?;

    const day = std.fmt.parseUnsigned(u32, day_str, 10) catch |err| {
        std.log.err("Failed to parse <day> argument: {}", .{err});
        printUsage();
        return error.InvalidArgument;
    };

    if (day <= 0 or day > days.len) {
        std.log.err("Argument <day> was out of range (1-{d})", .{days.len});
        printUsage();
        return error.InvalidArgument;
    }

    var args = default_args;
    args.day = day;

    if (arg_part) |part_str| {
        const part = std.fmt.parseUnsigned(u32, part_str, 10) catch |err| {
            std.log.err("Failed to parse [part] argument: {}", .{err});
            printUsage();
            return error.InvalidArgument;
        };

        args.part = switch (part) {
            1 => .part1,
            2 => .part2,
            else => {
                std.log.err("Argument [part] was out of range (1-2)", .{});
                printUsage();
                return error.InvalidArgument;
            },
        };
    }

    return args;
}

fn nthArg(nth: isize) ?[]const u8 {
    var index: isize = 0;
    var iter = std.process.args();
    while (iter.next()) |arg| {
        if (nth == index) {
            return arg;
        }
        index += 1;
    }
    return null;
}

test {
    std.testing.refAllDecls(@This());
}
