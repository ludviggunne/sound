
const Self = @This();
const std = @import("std");

const max_components: usize = 16;

amp: [max_components] f32  = undefined,
freq: [max_components] f32 = undefined,
components: usize          = 0,
amp_sum: f32               = 0,

// A profile is a list of amplitudes for each corresponding harmonic,
//  scaled by 1/N^2
pub fn fromProfile(profile: [] const f32, base: f32) !Self {
    var self: Self = .{};
    for (profile, 0..) |amp, i| {
        const s: f32 = @floatFromInt(i + 1);
        try self.addComponent(amp * 1.0 / s * s, base * s);
    }
    return self;
}

pub fn fromHarmonics(comptime N: usize, base: f32) !Self {
    const profile: [N] f32 = [N] f32 { 1.0, } ** N;
    return fromProfile(profile[0..], base);
}

pub fn addComponent(self: *Self, amp: f32, freq: f32) !void {
    if (self.components == max_components) return error.MaxComponents;
    self.amp[self.components] = amp;
    self.freq[self.components] = freq;
    self.components += 1;
    self.amp_sum += amp;
}

pub fn sample(self: Self, comptime T: type, t: f32, scale: f32) T {
    var acc: f32 = 0.0;
    for (0..self.components) |c| {
        acc += self.amp[c] * std.math.sin(self.freq[c] * t * 2.0 * std.math.pi);
    }
    acc /= self.amp_sum;
    acc *= scale;
    // TODO: Adjust for other bit-widths
    acc *= @as(f32, @floatFromInt((1 << 15)));
    const samp: T = @intFromFloat(acc);
    return samp;
}
