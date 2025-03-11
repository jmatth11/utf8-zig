.PHONY: all
all:
	zig build

.PHONY: web
web:
	zig build -Dtarget=wasm32-freestanding

.PHONY: test
test:
	zig build test

.PHONY: clean
clean:
	@rm -rf zig-out
