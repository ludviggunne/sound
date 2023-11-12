
const Self = @This();

const Context  = @import("Context.zig");
const Event    = @import("Event.zig");
const sound    = @import("sound.zig");
const Envelope = sound.Envelope;
const Timbre   = sound.Timbre;
const Buffer   = @import("Buffer.zig");

const std = @import("std");

const voices: usize = 16;

const EventIterator = struct {

    slice: [] const Event,
    index: usize,

    pub fn init(slice: [] const Event) EventIterator {
        return .{
            .slice = slice,
            .index = 0,
        };
    }

    pub fn next(self: *EventIterator) ?Event {
        if (self.index < self.slice.len) {
            defer self.index += 1;
            return self.slice[self.index];
        } else return null;
    }
};

events:       std.ArrayList(Event),
active:       [voices] ?Event,
active_count: usize,
context:      Context,
timbs:        std.ArrayList(Timbre),

pub fn init(allocator: std.mem.Allocator, context: Context) Self {
    return .{
        .events       = std.ArrayList(Event).init(allocator),
        .active       = [_] ?Event { null, } ** voices,
        .active_count = 0,
        .context      = context,
        .timbs        = std.ArrayList(Timbre).init(allocator),
    };
}

pub fn deinit(self: *Self) void {
    self.events.deinit();
    self.timbs.deinit();
}

pub fn registerTimbre(self: *Self, timb: Timbre) !usize {
    const index = self.timbs.items.len;
    try self.timbs.append(timb);
    return index;
}

pub fn registerEvent(self: *Self, event: Event) !void {
    try self.events.append(event);
}

pub fn render(self: *Self, buffer: *Buffer) !void {

    var iter = EventIterator.init(self.events.items);
    var next_event_opt = iter.next();
    var t: f32 = 0.0;
    var i: usize = 0;
    const f_sr: f32 = @floatFromInt(buffer.sample_rate);
    var first = true;

    while (self.active_count > 0 or first) {

        if (next_event_opt) |next_event| {

            if (next_event.begin <= t) {
                for (&self.active) |*slot| {
                    if (slot.* == null) {
                        slot.* = next_event;
                        next_event_opt = iter.next();
                        self.active_count += 1;
                        first = false;
                        break;
                    }
                } else return error.ActiveEventsExhausted;
            }
        }

        var acc: f32 = 0.0;

        for (&self.active) |*slot| {
            if (slot.*) |active| {
                if (active.begin + active.len < t) {
                    slot.* = null;
                    self.active_count -= 1;
                } else {
                    acc += self.sampleEvent(t - active.begin, active);
                }
            }
        }

        try buffer.pushSample(acc);

        i += 1;
        const f_i: f32 = @floatFromInt(i);
        t = f_i / f_sr;
    }
}

fn sampleEvent(self: *Self, t: f32, event: Event) f32 {

    var t_ = t - event.begin;
    var acc: f32 = 0.0;

    const freq: f32 =
        self.context.tuning *
        std.math.pow(f32, 2.0, @floatFromInt(event.note.oct)) *
        self.context.temp[@intFromEnum(event.note.cls)];


    for (0..self.timbs.items[event.timb].size) |comp_id| {

        const c: f32 = @floatFromInt(comp_id + 1);
        acc +=
            event.env(t, event.len) *
            event.amp *
            std.math.sin(
                t_ *
                freq *
                c *
                2.0 *
                std.math.pi
            ) / (c * c);
    }

    return acc;
}
