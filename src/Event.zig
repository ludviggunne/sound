
const Self = @This();
const Note = @import("Note.zig");
const Envelope = @import("sound.zig").Envelope;

note:  Note,
amp:   f32,
len:   f32,
begin: f32,
timb:  usize,
env:   Envelope,
