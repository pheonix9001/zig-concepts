# Zig concepts
Extensible concepts for the zig language
This library contains functions to implement c++-like concepts for the zig language

# Introduction
A concept is essencially a predicate on one or more types at compile time. Most importantly,
concepts are named, and when they return false, they also return a nice error message.

The type `Concept` looks like this
```zig
pub const Concept = struct {
	name: []const u8,
	err: ?[]const u8 = null,
    pub fn ok(name: []const u8) Concept {
        return .{ .name = name };
    }
    pub fn fail(name: []const u8, err: []const u8) Concept {
        return .{
            .name = name,
            .err = err,
        };
    }
    ...
};
```
If `err` is set, then it is interpreted that the concept has failed

You can use `requires` to assert a concept.
```zig
pub fn requires(comptime concept: Concept) void {
    if (concept.err) |err| {
        @compileError("Failed to assert concept: " ++ concept.name ++ "\n" ++ err);
    }
}

test "Concept" {
	requires(Concept.ok("Ok")) // This concept always succeeds
	requires(Concept.fail("Fail", "Always fails")) // Error: Failed to assert concept: Fail
	                                               //		 Always fails
}
```

You can compose concepts with `all`,`either`,`not` etc.

```zig
fn Iterator(comptime Self: type, comptime T: type) concept.Concept {
    return concept.all(.{
        concept.decl(Self, "next", fn (*Self) T), // decl checks for a decl under a container
        concept.decl(Self, "current", fn (Self) T),
    }) // .with_name() changes the name of a concept
    .with_name(concept.fnlike_name("Iterator", .{Self, T})); // fnlike_name creates a name like a function

}
```

# Future work
- [ ] Extractors to extract information from types
- [ ] `Send` and `Sync` concepts
- [ ] Builtin concepts like `Iterator`, `Allocator` .etc
- [ ] `std.concept`?
