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
    return concept.all(.{
        concept.decl(Self, "next", fn (*Self) T),
        concept.decl(Self, "current", fn (Self) T),
    }).with_name(concept.fnlike_name("Iterator", .{ Self, T }));
}

test "Iterator concept test" {
    concept.requires(Iterator(i32iter, i32));
    concept.requires(concept.not(Iterator(i32iter, bool)));
}
