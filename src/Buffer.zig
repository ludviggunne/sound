
const std = @import("std");

const Sample = f32;
const Self = @This();

const fscale: f32 = @floatFromInt(1 << 15 - 1);

sample_rate: u32,
samples: std.ArrayList(Sample),

pub fn init(sample_rate: u16, allocator: std.mem.Allocator) Self {
    return .{
        .sample_rate = sample_rate,
        .samples = std.ArrayList(Sample).init(allocator),
    };
}

pub fn deinit(self: *Self) void {
    self.samples.deinit();
}

pub fn pushSample(self: *Self, sample: Sample) !void {
    try self.samples.append(sample);
}

pub fn pushSamples(self: *Self, samples: [] Sample) !void {
    try self.samples.appendSlice(samples);
}

pub fn compress(self: *Self, threshold: f32, gain_reduce: f32) void {
    for (self.samples.items) |*sample| {
        if (sample.* > threshold) {
            sample.* = gain_reduce * (sample.* - threshold) + threshold;
        }
    }
}

pub fn outputWav(self: Self, outfile: std.fs.File.Writer) !void {

    const datasize: u32 = @truncate(2 * self.samples.items.len);
    const filesize: u32 = datasize + 32;

    _ = try outfile.write("RIFF");                             // FILE HEADER
    _ = try outfile.writeIntLittle(u32, filesize);             // file size
    _ = try outfile.write("WAVE");                             // WAVE format
    _ = try outfile.write("fmt ");                             // FORMAT CHUNK
    _ = try outfile.writeIntLittle(u32, 16);                   // format data length
    _ = try outfile.writeIntLittle(u16, 1);                    // pcm
    _ = try outfile.writeIntLittle(u16, 1);                    // channels
    _ = try outfile.writeIntLittle(u32, self.sample_rate);     // sample rate
    _ = try outfile.writeIntLittle(u32, self.sample_rate * 2); // byte rate
    _ = try outfile.writeIntLittle(u16, 2);                    // block align
    _ = try outfile.writeIntLittle(u16, 16);                   // bit per sample
    _ = try outfile.write("data");                             // DATA CHUNK
    _ = try outfile.writeIntLittle(u32, datasize);             // data length
    for (self.samples.items) |sample| {
        var s = std.math.clamp(sample, -1.0, 1.0);
        s *= fscale;
        try outfile.writeIntLittle(i16, @intFromFloat(s));
    }
}
