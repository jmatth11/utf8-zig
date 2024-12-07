.PHONY: all
all:
	zig build

.PHONY: test
test:
	zig build test

.PHONY: clean
clean:
	@rm -rf zig-out
