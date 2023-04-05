const std = @import("std");
const combinator = @import("combinator.zig");
pub usingnamespace combinator;
test {
    _ = @import("test.zig");
    _ = @import("combinator.zig");
}

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
    pub fn with_name(orig: Concept, newname: []const u8) Concept {
        if (orig.err) |err| {
            return fail(newname, err);
        } else {
            return ok(newname);
        }
    }
};
pub const AlwaysValid = Concept.ok("AlwaysValid");
pub const AlwaysInvalid = Concept.fail("AlwaysInvalid", "This concept always errors");

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

pub fn decl(comptime Container: type, comptime method_name: []const u8, comptime ExpectedT: type) Concept {
    const concept_name = fnlike_name("hasMethod", .{ Container, method_name, ExpectedT });
    const info = @typeInfo(Container);
    const decls = switch (info) {
        .Struct => |s| s.decls,
        .Enum => |e| e.decls,
        .Union => |e| e.decls,
        else => @compileError("hasMethod expects a struct, union or enum"),
    };

    for (decls) |each_decl| {
        const name = each_decl.name;
        if (std.mem.eql(u8, name, method_name)) {
            return combinator.sameas(ExpectedT, @TypeOf(@field(Container, name))).with_name(concept_name);
        }
    }

    return Concept.fail(
        concept_name,
        comptime std.fmt.comptimePrint("Type '{}' must implement the method '{s}' for it to qualify", .{ Container, method_name }),
    );
}
