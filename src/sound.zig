
const std = @import("std");

pub const timbre_max_components: usize = 12;

pub const Timbre = struct {

    const Self = @This();

    components: [timbre_max_components] f32 = undefined,
    size: usize = 0,

    pub fn fromComponents(components: [] const f32) Self {
        var self: Self = undefined;
        std.mem.copy(f32, self.components[0..components.len], components);
        self.size = components.len;
        return self;
    }

    pub fn addComponent(self: *Self, component: f32) !void {
        if (self.size == timbre_max_components) return error.MaxComponents;
        self.components[self.size] = component;
        self.size += 1;
    }
};

pub const Envelope = *const fn (f32, f32) f32;

pub const EnvelopeParams = struct {
    attack_duration:  f32,
    attack_peak:      f32,
    decay_duration:   f32,
    sustain_level:    f32,
    release_duration: f32,
};

pub fn EnvelopeFromParams(comptime P: EnvelopeParams) Envelope {

    const a = P.attack_duration;
    const A = P.attack_peak;
    const d = P.decay_duration;
    const S = P.sustain_level;
    const r = P.release_duration;

    const L = struct {
        fn env(t: f32, l: f32) f32 {
            if (t < a) {
                return A / a * t;
            } else if (t < a + d) {
                return (S - A) / d * (t - a) + A;
            } else if (t > l - r) {
                return S / r * (l - t);
            } else return S;
        }
    };

    return L.env;
}
