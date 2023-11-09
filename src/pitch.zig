
const std = @import("std");
const Signal = @import("Signal.zig");
const Context = @import("Context.zig");

pub const Class = enum { c, db, d, eb, e, f, gb, g, ab, a, bb, b, };

pub fn transpose(class: Class, by: i32) Class {
    const i: i32 = @enumFromInt(class);
    i += by;
    return @enumFromInt(@rem(12 + @rem(i, 12), 12));
}

pub fn freq(class: Class, oct: usize, context: Context) f32 {
    var f: f32 = 1.0;
    f *= context.temp[@intFromEnum(class)];
    f *= std.math.pow(f32, 2.0, @floatFromInt(oct));
    f *= context.tuning;
    return f;
}
