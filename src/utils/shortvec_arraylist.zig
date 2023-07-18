const std = @import("std");
const bincode = @import("bincode-zig");
const serialize_short_u16 = @import("varint.zig").serialize_short_u16;
const deserialize_short_u16 = @import("varint.zig").deserialize_short_u16;

pub fn ShortVecArrayListConfig(comptime Child: type) bincode.FieldConfig {
    const S = struct {
        pub fn serialize(writer: anytype, data: anytype, params: bincode.Params) !void {
            var list: std.ArrayList(Child) = data;
            var len = std.math.cast(u16, list.items.len) orelse return error.DataTooLarge;
            try serialize_short_u16(writer, len, params);
            for (list.items) |item| {
                try bincode.write(writer, item, params);
            }
            return;
        }

        pub fn deserialize(allocator: std.mem.Allocator, comptime T: type, reader: anytype, params: bincode.Params) !T {
            var len = try deserialize_short_u16(allocator, u16, reader, params);
            var list = try std.ArrayList(Child).initCapacity(allocator, @as(usize, len));
            for (0..len) |_| {
                var item = try bincode.read(allocator, Child, reader, params);
                try list.append(item);
            }
            return list;
        }
    };

    return bincode.FieldConfig{
        .serializer = S.serialize,
        .deserializer = S.deserialize,
    };
}