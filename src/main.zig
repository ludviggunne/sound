
const std = @import("std");
const pitch = @import("pitch.zig");
const temp = @import("temp.zig");
const Context = @import("Context.zig");
const Buffer = @import("Buffer.zig");
const Track = @import("Track.zig");
const Event = @import("Event.zig");
const sound = @import("sound.zig");

pub fn main() !void {

    var gpa = std.heap.GeneralPurposeAllocator(.{}) {};
    defer _ = gpa.deinit();
    var alloc = gpa.allocator();

    var buf = Buffer.init(44100, alloc);
    defer buf.deinit();

    var track = Track.init(alloc, .{});
    defer track.deinit();

    var timb1 = try track.registerTimbre(sound.Timbre.fromComponents(&[_] f32 { 1.0, 1.0, 1.0, 1.0, }));
    var timb2 = try track.registerTimbre(sound.Timbre.fromComponents(&[_] f32 { 1.0, 2.0, 3.0, }));

    _ = timb2;

    const env1 = sound.EnvelopeFromParams(.{
        .attack_duration = 0.051,
        .attack_peak = 0.9,
        .decay_duration = 0.071,
        .sustain_level = 0.1,
        .release_duration = 0.5,
    });

    const env2 = sound.EnvelopeFromParams(.{
        .attack_duration = 0.05,
        .attack_peak = 1.0,
        .decay_duration = 0.1,
        .sustain_level = 0.1,
        .release_duration = 1.0,
    });

    _ = env2;

    var t: f32 = 0.0;
    for (&[_] pitch.Class { .c, .d, .e, .f, .g, .a, .b, }) |cls| {

        try track.registerEvent(
            .{
                .begin = t,
                .len = 1.8,
                .note = .{
                    .cls = cls,
                    .oct = 1,
                },
                .amp = 0.8,
                .timb = timb1,
                .env = env1,
            }
        );

        t += 0.5;
    }

    try track.registerEvent(
        .{
            .begin = t,
            .len = 1.8,
            .note = .{
                .cls = .c,
                .oct = 2,
            },
            .amp = 0.8,
            .timb = timb1,
            .env = env1,
        }
    );

    try track.render(&buf);
    //buf.compress(0.2, 0.02);

    var file = try std.fs.cwd().createFile("output.wav", .{});
    defer file.close();

    try buf.outputWav(file.writer());
}
