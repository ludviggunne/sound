
const Self = @This();
const std = @import("std");

sample_rate: u32,
bps: u16,
buffer: std.ArrayList(u8),

pub fn init(sample_rate: u32, bps: u16, allocator: std.mem.Allocator) Self {

    return .{
        .sample_rate = sample_rate,
        .bps = bps,
        .buffer = std.ArrayList(u8).init(allocator),
    };
}

pub fn deinit(self: Self) void {
    self.buffer.deinit();
}

pub fn pushSample(self: *Self, sample: i16) !void {
    try self.buffer.writer().writeIntLittle(i16, sample);
}

pub fn renderWav(self: Self, outfile: std.fs.File.Writer) !void {

    const datasize: u32 = @truncate(self.buffer.items.len);
    const filesize: u32 = datasize + 32;

    _ = try outfile.write("RIFF");                                        // FILE HEADER
    _ = try outfile.writeIntLittle(u32, filesize);                        // file size
    _ = try outfile.write("WAVE");                                        // WAVE format
    _ = try outfile.write("fmt ");                                        // FORMAT CHUNK
    _ = try outfile.writeIntLittle(u32, 16);                              // format data length
    _ = try outfile.writeIntLittle(u16, 1);                               // pcm
    _ = try outfile.writeIntLittle(u16, 1);                               // channels
    _ = try outfile.writeIntLittle(u32, self.sample_rate);                // sample rate
    _ = try outfile.writeIntLittle(u32, self.sample_rate * self.bps / 8); // byte rate
    _ = try outfile.writeIntLittle(u16, self.bps / 8);                    // block align
    _ = try outfile.writeIntLittle(u16, self.bps);                        // bit per sample
    _ = try outfile.write("data");                                        // DATA CHUNK
    _ = try outfile.writeIntLittle(u32, datasize);                        // data length
    _ = try outfile.write(self.buffer.items);                             // data
}
