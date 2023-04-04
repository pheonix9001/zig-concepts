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
    }).with_name("Iterator(" ++ @typeName(T) ++ ")");
}

test "Iterator concept test" {
    concept.requires(Iterator(i32iter, i32));
    concept.requires(concept.not(Iterator(i32iter, bool)));
}

test "Either concept test" {
    concept.requires(concept.not(
        concept.either(.{ concept.AlwaysInvalid, concept.AlwaysInvalid }).with_name("EitherConcept"),
    ));
    concept.requires(
        concept.either(.{ concept.AlwaysValid, concept.AlwaysInvalid }).with_name("EitherConcept"),
    );
}

test "Sameas" {
    concept.requires(concept.sameas(i32, i32));
    concept.requires(concept.not(concept.sameas(i32, bool)));
}
