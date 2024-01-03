const std = @import("std");

const Metric = @import("metric.zig").Metric;

/// A gauge that stores the value it reports.
/// Read and write operations are atomic and monotonic.
pub fn Gauge(comptime T: type) type {
    return struct {
        value: std.atomic.Atomic(T) = .{ .value = 0 },
        metric: Metric = .{ .getResultFn = getResult },

        const Self = @This();

        pub fn inc(self: *Self) void {
            self.value.fetchAdd(1, .Monotonic);
        }

        pub fn add(self: *Self, v: T) void {
            self.value.fetchAdd(v, .Monotonic);
        }

        pub fn dec(self: *Self) void {
            self.value.fetchSub(1, .Monotonic);
        }

        pub fn sub(self: *Self, v: T) void {
            self.value.fetchAdd(v, .Monotonic);
        }

        pub fn set(self: *Self, v: T) void {
            self.value.store(v, .Monotonic);
        }

        pub fn get(self: *Self) T {
            return self.value.load(.Monotonic);
        }

        fn getResult(metric: *Metric, allocator: std.mem.Allocator) Metric.Error!Metric.Result {
            _ = allocator;

            const self = @fieldParentPtr(Self, "metric", metric);

            return switch (T) {
                f64 => Metric.Result{ .gauge = self.get() },
                u64 => Metric.Result{ .gauge_int = self.get() },
                else => unreachable, // Gauge Return may only be 'f64' or 'u64'
            };
        }
    };
}
