# SPDX-FileCopyrightText: 2023 Kalle Fagerberg
#
# SPDX-License-Identifier: CC0-1.0

ZIG_FILES=$(shell git ls-files '*.zig')

.PHONY: build
build:
	zig build

.PHONY: clean
clean:
	rm -fv zig-out

.PHONY: test
test:
	zig build test

.PHONY: deps
deps: deps-zig deps-npm

.PHONY: deps-zig
deps-zig:
	zig build --fetch

.PHONY: deps-npm
deps-npm: node_modules

node_modules:
	npm install

.PHONY: lint
lint: lint-md lint-zig lint-license

.PHONY: lint-fix
lint-fix: lint-md-fix lint-zig-fix

.PHONY: lint-md
lint-md: node_modules
	npx markdownlint-cli2

.PHONY: lint-md-fix
lint-md-fix: node_modules
	npx markdownlint-cli2 --fix

.PHONY: lint-zig
lint-zig:
	@echo zig fmt --check '**/*.zig'
	@zig fmt --check $(ZIG_FILES)

.PHONY: lint-zig-fix
lint-zig-fix:
	@echo zig fmt '**/*.zig'
	@zig fmt $(ZIG_FILES)

.PHONY: lint-license
lint-license:
	reuse lint
