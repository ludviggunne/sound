
const std = @import("std");
const AudioBuffer = @import("AudioBuffer.zig");
const Signal = @import("Signal.zig");
const pitch = @import("pitch.zig");
const temp = @import("temp.zig");

const sample_rate: u32 = 44100;
const bps:         u16 = 16;
const channels:    u16 = 1;

fn envelope(t: f32) f32 {
//    return if (t == 0.0) 0.0 else std.math.sin(std.math.pi * t) /
//        std.math.pow(f32, std.math.pi * t, 0.5);
    return 1.0 - std.math.pow(f32, 2.0 * std.math.pow(f32, t, 0.5) - 1.0, 6.0);
}

fn niceSig(class: pitch.Class) !Signal {

    const f: f32 = 16384.0 / 10935.0;
    const freq = pitch.freq(class, 0, .{ .temp = temp.fifths(f), });
    return Signal.fromProfile(
        &[_] f32 {
            1.0,
            1.0,
            1.0,
            1.0,
        }, freq
    );
}

fn playNote(ab: *AudioBuffer, class: pitch.Class, length: f32, amp: f32) !void {

    const f_sr: f32 = @floatFromInt(sample_rate);

    const sig = try niceSig(class);
    std.debug.print("{e}\n", .{ sig.amp_sum, });

    for (0..@intFromFloat(length * f_sr)) |i| {

        const f_i: f32 = @floatFromInt(i);
        const t = f_i / f_sr;
        const et = t / length;

        try ab.pushSample(sig.sample(i16, t, amp * envelope(et)));
    }
}

pub fn main() !void {

    var gpa = std.heap.GeneralPurposeAllocator(.{}) {};
    defer _ = gpa.deinit();
    var alloc = gpa.allocator();

    var file = try std.fs.cwd().createFile("output.wav", .{});
    defer file.close();

    var ab = AudioBuffer.init(sample_rate, bps, alloc);
    defer ab.deinit();

    const Note = struct { class: pitch.Class, length: f32, amp: f32, };

    const notes = &[_] Note {
        // IRON MAN
        .{ .class = .c,  .length = 1.0,  .amp = 0.5, },
        .{ .class = .eb, .length = 1.0,  .amp = 0.7, },

        .{ .class = .eb, .length = 0.5,  .amp = 0.8, },
        .{ .class = .f,  .length = 0.5,  .amp = 0.5, },
        .{ .class = .f,  .length = 1.0,  .amp = 0.8, },

        .{ .class = .ab, .length = 0.25, .amp = 1.0, },
        .{ .class = .g,  .length = 0.25, .amp = 0.7, },
        .{ .class = .ab, .length = 0.25, .amp = 1.0, },
        .{ .class = .g,  .length = 0.25, .amp = 0.7, },

        .{ .class = .ab, .length = 0.25, .amp = 1.0, },
        .{ .class = .g,  .length = 0.25, .amp = 0.7, },
        .{ .class = .eb, .length = 0.5,  .amp = 0.7, },

        .{ .class = .eb, .length = 0.5,  .amp = 0.7, },
        .{ .class = .f,  .length = 0.5,  .amp = 0.5, },
        .{ .class = .f,  .length = 1.0,  .amp = 0.7, },
    };

    for (notes) |note| {
        try playNote(&ab, note.class, 0.7 * note.length, note.amp);
    }

    try ab.renderWav(file.writer());
}
