# Google Benchmark

This is [Google Benchmark](https://github.com/google/benchmark), packaged for
[Zig](https://ziglang.org/).

## How to use it

First, update your `build.zig.zon`:

```
zig fetch --save git+https://github.com/allyourcodebase/benchmark
```

Next, in `build.zig`, declare the dependency and link your benchmarks with the static libraries:

```zig
const benchmark_dep = b.dependency("benchmark", .{
    .target = target,
    .optimize = optimize,
});

const benchmarks_exe = b.addExecutable(.{
    .name = "benchmarks",
    .root_module = b.createModule(.{ .target = target, .optimize = optimize }),
});
benchmarks_exe.addCSourceFiles(.{ .files = &.{"src/bm.cpp"} }); // your benchmark files
benchmarks_exe.linkLibrary(googletest_dep.artifact("benchmark"));
// Unless you define your an entry point (i.e. `BENCHMARK_MAIN()`), you need `benchmark_main` too.
benchmarks_exe.linkLibrary(googletest_dep.artifact("benchmark_main"));
```
