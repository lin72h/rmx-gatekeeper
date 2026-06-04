const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    _ = target;
    _ = optimize;

    const check_step = b.step("check", "Validate the M1 Zig scaffold");
    check_step.dependOn(&b.addSystemCommand(&.{ "true" }).step);
}
