.PHONY: all
all:
	zig build -Doptimize=ReleaseFast

.PHONY: test
test:
	zig build test

.PHONY: clean
clean:
	@rm -rf zig-out
