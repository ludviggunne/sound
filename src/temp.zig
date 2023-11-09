
const std = @import("std");

pub const Temperament = [12] f32;

pub const equal = blk: {
    var temp: [12] f32 = undefined;
    for (0..12) |i| {
        const f_i: f32 = @floatFromInt(i);
        temp[i] = std.math.pow(f32, 2.0, f_i / 12.0);
    }
    break :blk temp;
};

pub fn fifths(f: f32) Temperament {
    var temp: [12] f32 = undefined;
    for (0..12) |i| {
        var f_i: f32 = @floatFromInt(i);
        var x: f32 = std.math.pow(f32, f, f_i);
        var k: usize = 7 * i;
        while (k >= 12)
        {
            k -= 12;
            x /= 2.0;
        }
        temp[k] = x;
        //@compileLog("{e}\n", .{ x, });
    }
    return temp;
}

//pub const fifths = blk: {
//    var temp: [12] f32 = undefined;
//    for (0..12) |i| {
//        var f_i: f32 = @floatFromInt(i);
//        const fifth: f32 = 16384.0 / 10935.0;
//        var x: f32 = std.math.pow(f32, fifth, f_i);
//        var k: usize = 7 * i;
//        while (k >= 12)
//        {
//            k -= 12;
//            x /= 2.0;
//        }
//        temp[k] = x;
//        //@compileLog("{e}\n", .{ x, });
//    }
//    break :blk temp;
//};
