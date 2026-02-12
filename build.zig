const std = @import("std");
const zon = @import("build.zig.zon");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const upstream = b.dependency("benchmark", .{});

    const benchmark = b.addLibrary(.{
        .name = "benchmark",
        .root_module = b.createModule(.{ .target = target, .optimize = optimize }),
    });
    benchmark.root_module.addCSourceFiles(.{
        .root = upstream.path("src"),
        .files = &.{
            "benchmark.cc",
            "benchmark_api_internal.cc",
            "benchmark_name.cc",
            "benchmark_register.cc",
            "benchmark_runner.cc",
            "check.cc",
            "colorprint.cc",
            "commandlineflags.cc",
            "complexity.cc",
            "console_reporter.cc",
            "counter.cc",
            "csv_reporter.cc",
            "json_reporter.cc",
            "perf_counters.cc",
            "reporter.cc",
            "statistics.cc",
            "string_util.cc",
            "sysinfo.cc",
            "timers.cc",
        },
        .flags = &.{ "-std=c++17", "-fstrict-aliasing" },
    });
    switch (target.result.os.tag) {
        .wasi => {},
        .windows => benchmark.linkSystemLibrary("shlwapi"),
        .linux => {
            benchmark.linkSystemLibrary("pthread");
            benchmark.linkSystemLibrary("rt");
            benchmark.root_module.addCMacro("BENCHMARK_HAS_PTHREAD_AFFINITY", "1");
        },
        .solaris => benchmark.linkSystemLibrary("kstat"),
        else => benchmark.linkSystemLibrary("pthread"),
    }
    if (target.result.os.tag != .windows) {
        benchmark.root_module.addCMacro("_FILE_OFFSET_BITS", "64");
        benchmark.root_module.addCMacro("_LARGEFILE64_SOURCE", "1");
        benchmark.root_module.addCMacro("_LARGEFILE_SOURCE", "1");
    }
    benchmark.root_module.addCMacro("BENCHMARK_STATIC_DEFINE", "1");
    benchmark.root_module.addCMacro("BENCHMARK_VERSION", "\"" ++ zon.version ++ "\"");
    benchmark.root_module.addIncludePath(upstream.path("include"));
    benchmark.installHeadersDirectory(upstream.path("include"), ".", .{});
    benchmark.linkLibCpp();
    b.installArtifact(benchmark);

    const benchmark_main = b.addLibrary(.{
        .name = "benchmark_main",
        .root_module = b.createModule(.{ .target = target, .optimize = optimize }),
    });
    benchmark_main.root_module.addCSourceFiles(.{
        .root = upstream.path("src"),
        .files = &.{"benchmark_main.cc"},
        .flags = &.{"-std=c++17"},
    });
    benchmark_main.root_module.addIncludePath(upstream.path("include"));
    benchmark_main.installHeadersDirectory(upstream.path("include"), ".", .{});
    benchmark_main.linkLibCpp();
    b.installArtifact(benchmark_main);

    const sample_exe = b.addExecutable(.{
        .name = "sample",
        .root_module = b.createModule(.{ .target = target, .optimize = optimize }),
    });
    sample_exe.root_module.addCSourceFiles(.{ .files = &.{"src/bm.cpp"} });
    sample_exe.linkLibrary(benchmark);
    sample_exe.linkLibrary(benchmark_main);

    const sample_step = b.step("sample", "Run sample benchmark");
    const sample_cmd = b.addRunArtifact(sample_exe);
    sample_cmd.addArgs(&.{"--benchmark_min_time=0s"}); // run the benchmark only once
    sample_step.dependOn(&sample_cmd.step);
}
