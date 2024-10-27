const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addSharedLibrary(.{
        .name = "trace",
        .optimize = optimize,
        .link_libc = true,
        .target = target,
        .root_source_file = b.path("src/trace.zig"),
    });
    b.installArtifact(lib);

    const lib_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/trace.zig"),
        .target = target,
        .link_libc = true,
    });
    lib_unit_tests.linkSystemLibrary("sqlite3");
    b.step("test", "Run unit tests").dependOn(&b.addRunArtifact(lib_unit_tests).step);
}
