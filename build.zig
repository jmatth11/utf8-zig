const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const linkage = b.option(std.builtin.LinkMode, "linkage", "Link mode for utf8-zig library") orelse .static;
    const unicodeMod = b.addModule("utf8-zig", .{
        .root_source_file = b.path("src/unicode.zig"),
        .pic = true,
        .target = target,
        .optimize = optimize,
    });
    const utf8Mod = b.addModule("utf8-zig", .{
        .root_source_file = b.path("src/utf8.zig"),
        .pic = true,
        .target = target,
        .optimize = optimize,
    });
    // create zig lib
    const ziglib = b.addLibrary(.{
        .name = "unicode-zig",
        .root_module = unicodeMod,
        .linkage = linkage,
    });

    // This declares intent for the library to be installed into the standard
    // location when the user invokes the "install" step (the default step when
    // running `zig build`).
    b.installArtifact(ziglib);

    // create c-only lib
    const clib = b.addLibrary(.{
        .name = "utf8-zig",
        .root_module = utf8Mod,
        .linkage = linkage,
    });
    // bundle zig compiler runtime
    clib.bundle_compiler_rt = true;
    b.installArtifact(clib);

    const webMod = b.addModule("webutf8-zig", .{
        .root_source_file = b.path("src/utf8.zig"),
        .pic = true,
        .target = b.resolveTargetQuery(.{ .cpu_arch = .wasm32, .os_tag = .freestanding }),
        .optimize = optimize,
    });
    const weblib = b.addLibrary(.{
        .name = "webutf8-zig",
        .root_module = webMod,
        .linkage = linkage,
        .use_llvm = true,
    });
    // bundle zig compiler runtime
    weblib.bundle_compiler_rt = true;
    b.installArtifact(weblib);

    const test_mod = b.createModule(.{
        .root_source_file = b.path("src/utf8.test.zig"),
        .optimize = optimize,
        .target = target,
    });
    const lib_public_func_unit_tests = b.addTest(.{
        .root_module = test_mod,
        .name = "utf8-tests",
    });

    const run_public_func_lib_unit_tests = b.addRunArtifact(lib_public_func_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_public_func_lib_unit_tests.step);
}
