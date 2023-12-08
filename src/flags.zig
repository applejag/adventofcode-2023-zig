// SPDX-FileCopyrightText: 2023 Kalle Fagerberg
//
// SPDX-License-Identifier: BSD-3-Clause

const std = @import("std");

pub const Arg = struct {
    position: u32,
    value: []const u8,
};

pub const Flag = struct {
    key: []const u8,
    value: ?[]const u8,
};

pub const Value = union(enum) {
    arg: Arg,
    flag: Flag,
};

pub const FlagIterator = struct {
    arg_iterator: std.process.ArgIterator,
    arg_next_position: u32,
    arg_only: bool,
    cached_next: ?[]const u8,

    pub fn next(self: *@This()) ?Value {
        const value: []const u8 = if (self.cached_next) |v| v else self.arg_iterator.next() orelse return null;

        if (value.len == 0 or value[0] != '-' or self.arg_only) {
            return self.arg(value);
        }

        if (value.len == 2 and value[1] == '-') {
            // "--" => treat all following values as args
            self.arg_only = true;
            return self.next();
        }

        if (value.len >= 2 and value[1] != '-') {
            if (value.len > 2 and value[2] == '=') {
                // "-h=foo" => Flag{.key = "-h", .value = "foo"}
                return Value{ .flag = Flag{
                    .key = value[0..2],
                    .value = value[3..],
                } };
            }

            if (value.len > 2) {
                // "-hfoo" => Flag{.key = "-h", .value = "foo"}
                return Value{ .flag = Flag{
                    .key = value[0..2],
                    .value = value[2..],
                } };
            }

            // "-h" => Flag{.key = "-h", .value = null}
            // "-h foo" => Flag{.key = "-h", .value = "foo"}
            return Value{ .flag = Flag{
                .key = value[0..2],
                .value = self.peek_next_arg(),
            } };
        }

        const equal_index = std.mem.indexOfScalar(u8, value, '=');
        if (equal_index) |index| {
            // "--moo=foo" => Flag{.key = "--moo", .value = "foo"}
            return Value{ .flag = Flag{
                .key = value[0..index],
                .value = value[index + 1 ..],
            } };
        }

        // "--moo" => Flag{.key = "--moo", .value = null}
        // "--moo foo" => Flag{.key = "--moo", .value = "foo"}
        return Value{ .flag = Flag{
            .key = value,
            .value = self.peek_next_arg(),
        } };
    }

    fn arg(self: *@This(), value: []const u8) Value {
        const position = self.arg_next_position;
        self.arg_next_position += 1;
        return Value{ .arg = Arg{
            .position = position,
            .value = value,
        } };
    }

    fn peek_next_arg(self: *@This()) ?[]const u8 {
        const next_value: []const u8 = self.arg_iterator.next() orelse {
            return null;
        };

        if (next_value.len > 0 and next_value[0] == '-') {
            self.cached_next = next_value;
            return null;
        }

        return next_value;
    }

    pub fn deinit(self: @This()) void {
        self.arg_iterator.deinit();
    }
};

pub fn iterate(iter: std.process.ArgIterator) FlagIterator {
    return FlagIterator{
        .arg_iterator = iter,
        .arg_next_position = 0,
        .arg_only = false,
        .cached_next = null,
    };
}
