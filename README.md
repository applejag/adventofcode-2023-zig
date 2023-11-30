<!--
SPDX-FileCopyrightText: 2023 Kalle Fagerberg

SPDX-License-Identifier: CC-BY-4.0
-->

# Advent of Code 2022 via Zig

This repo contains my attempt at Advent of Code 2023
(<https://adventofcode.com/2023>).

## Running

Requires Zig v0.12.0-dev.1767, 2023-11-30 (or later): <https://ziglang.org/download/>

```console
$ zig build run
info: Usage: adventofcode-2023-zig <day> [part]

Arguments:
  day    Advent calendar day. Number between 1 and 25
  part   Part of day, 1 or 2 (default 1)
```

```console
$ zig build run -- 1
info: Running day 01 part 1
day01 part1 :)
```

The code to run the different days are a bit overkill, but I wanted to try
how far I could get with Zig's type system.

On the plus side, very far! On the down side, the LSP starts failing to
understand quite quickly once you do some inline switches and comptime.

## License

This repository is licensed under multiple licenses, following the
[REUSE](https://reuse.software/) specification (version 3.0).

- All Zig files uses MIT
- Some documentation uses CC-BY-4.0
- Other miscellaneous files uses CC0-1.0

See the file header or accompanying `.license` file on a per-file basis
for a more exact answer.
