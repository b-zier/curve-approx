const std = @import("std");

const Target = struct { name: []const u8, query: std.Target.Query };

const STATIC_ONLY_TARGETS = [_]Target{
    .{ .name = "aarch64-freestanding", .query = .{ .cpu_arch = .aarch64, .os_tag = .freestanding } },
    .{ .name = "x86_64-freestanding", .query = .{ .cpu_arch = .x86_64, .os_tag = .freestanding } },
    .{ .name = "wasm64-freestanding", .query = .{ .cpu_arch = .wasm64, .os_tag = .freestanding } },
};
const TARGETS = [_]Target{
    .{ .name = "aarch64-linux", .query = .{ .cpu_arch = .aarch64, .os_tag = .linux } },
    .{ .name = "aarch64-macos", .query = .{ .cpu_arch = .aarch64, .os_tag = .macos } },
    .{ .name = "x86_64-linux", .query = .{ .cpu_arch = .x86_64, .os_tag = .linux } },
    .{ .name = "x86_64-macos", .query = .{ .cpu_arch = .x86_64, .os_tag = .macos } },
    .{ .name = "x86_64-windows", .query = .{ .cpu_arch = .x86_64, .os_tag = .windows } },
};

pub fn build(b: *std.Build) !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const optimize = b.standardOptimizeOption(.{ .preferred_optimize_mode = .ReleaseFast });
    const root_source_file: std.Build.LazyPath = .{ .src_path = .{ .owner = b, .sub_path = "src/root.zig" } };

    const lib_step = b.step("lib", "Install executable for all targets");

    for (STATIC_ONLY_TARGETS ++ TARGETS) |TARGET| {
        const name = try std.fmt.allocPrint(allocator, "b_zier_curve_approx-{s}", .{TARGET.name});
        const lib = b.addStaticLibrary(.{
            .name = name,
            .target = b.resolveTargetQuery(TARGET.query),
            .optimize = optimize,
            .root_source_file = root_source_file,
        });

        const lib_install = b.addInstallArtifact(lib, .{});
        lib_step.dependOn(&lib_install.step);
    }

    for (TARGETS) |TARGET| {
        const name = try std.fmt.allocPrint(allocator, "b_zier_curve_approx-{s}", .{TARGET.name});
        const lib = b.addSharedLibrary(.{
            .name = name,
            .target = b.resolveTargetQuery(TARGET.query),
            .optimize = optimize,
            .root_source_file = root_source_file,
        });

        const lib_install = b.addInstallArtifact(lib, .{});
        lib_step.dependOn(&lib_install.step);
    }

    b.default_step.dependOn(lib_step);
}
