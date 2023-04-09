const std = @import("std");
pub const combinator = @import("combinator.zig");
pub const core = @import("core.zig");
pub usingnamespace combinator;
pub usingnamespace core;
test {
    _ = @import("test.zig");
    _ = @import("combinator.zig");
}

pub fn decl(comptime Container: type, comptime decl_name: []const u8, comptime ExpectedT: type) core.Concept {
    const concept_name = core.fnlike_name("hasMethod", .{ Container, decl_name, ExpectedT });

    if (@hasDecl(Container, decl_name)) {
        return combinator.eq(ExpectedT, @TypeOf(@field(Container, decl_name))).with_name(concept_name);
    }

    return core.Concept.fail(
        concept_name,
        comptime std.fmt.comptimePrint("Type '{}' must implement the method '{s}' for it to qualify", .{ Container, decl_name }),
    );
}
