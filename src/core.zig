const std = @import("std");

/// A Concept
pub const Concept = struct {
    /// The name of the concept
    name: []const u8,
    /// The error. Set if the concept fails
    err: ?[]const u8 = null,

    /// Returns a concept which succeeds
    pub fn ok(name: []const u8) Concept {
        return .{ .name = name };
    }
    /// Returns a concept which fails
    pub fn fail(name: []const u8, err: []const u8) Concept {
        return .{
            .name = name,
            .err = err,
        };
    }
    /// Change the name of a concept
    pub fn with_name(orig: Concept, newname: []const u8) Concept {
        if (orig.err) |err| {
            return fail(newname, err);
        } else {
            return ok(newname);
        }
    }
};
/// A concept which always succeeds
pub const AlwaysValid = Concept.ok("AlwaysValid");
/// A concept which always fails
pub const AlwaysInvalid = Concept.fail("AlwaysInvalid", "This concept always errors");

/// Assert a concept is true at compile time
pub fn requires(comptime concept: Concept) void {
    if (concept.err) |err| {
        @compileError("Failed to assert concept: " ++ concept.name ++ "\n" ++ err);
    }
}

fn concept_to_str(comptime val: anytype) []const u8 {
    return switch (@TypeOf(val)) {
        type => @typeName(val),
        Concept => val.name,
        else => std.fmt.comptimePrint("{s}", .{val}),
    };
}

/// Generates a name that looks like a function
pub fn fnlike_name(comptime basename: []const u8, comptime parts: anytype) []const u8 {
    comptime var seperated_args: []const u8 = "";
    for (parts) |part, i| {
        const part_name = concept_to_str(part);
        if (i == 0) {
            seperated_args = part_name;
        } else {
            seperated_args = seperated_args ++ "," ++ part_name;
        }
    }
    return basename ++ "(" ++ seperated_args ++ ")";
}
