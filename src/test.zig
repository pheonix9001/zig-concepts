const concept = @import("main.zig");

const i32iter = struct {
    const Self = @This();
    current: i32 = 0,
    pub fn next(self: *Self) i32 {
        self.current += 1;
        return self.current;
    }
    pub fn current(self: Self) i32 {
	    return self.current;
    }
};

fn Iterator(comptime Self: type, comptime T: type) concept.Concept {
    return concept.all("Iterator", .{
        concept.hasMethod(Self, "next", fn (*Self) T),
        concept.hasMethod(Self, "current", fn (Self) T),
    });
}

test "Iterator concept test" {
    concept.requires(Iterator(i32iter, i32));
}
