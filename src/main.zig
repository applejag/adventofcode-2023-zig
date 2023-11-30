const std = @import("std");

const Part = enum(u2) {
    part1 = 1,
    part2 = 2,
};

const Args = struct {
    day: u32,
    part: Part,
};

const days = [_]type{
    @import("days/day01.zig"),
};

pub fn main() !void {
    const arg_day = nthArg(1);
    const arg_part = nthArg(2);
    const args = try parseArgs(arg_day, arg_part);

    std.log.info("Running day {d:0>2} part {d}", .{ args.day, @intFromEnum(args.part) });

    try runDay(args);
}

fn runDay(args: Args) !void {
    return switch (args.day - 1) {
        inline 0...days.len - 1 => |index| runPart(days[index], args.part),
        else => error.OutOfRange,
    };
}

fn runPart(comptime day: type, part: Part) !void {
    return switch (part) {
        .part1 => {
            if (@hasDecl(day, "part1")) {
                return day.part1();
            }
            std.log.err("This day does not have part 1 implemented.", .{});
            return error.NotImplemented;
        },
        .part2 => {
            if (@hasDecl(day, "part2")) {
                return day.part2();
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
        \\  day    Number between 1 and {d}
        \\  part   Number between 1 and 2 (optional)
    , .{ exe_path_arg, days.len });
}

fn parseArgs(arg_day: ?[]const u8, arg_part: ?[]const u8) !Args {
    if (arg_day == null) {
        std.log.err("Missing <day> argument", .{});
        printUsage();
        return error.MissingArg;
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

    var args = Args{
        .day = day,
        .part = Part.part1,
    };

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
