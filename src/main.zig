const std = @import("std");
test {
    _ = @import("test.zig");
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
        return if (orig.err) |err| {
            fail(newname, err);
        } else {
            ok(newname);
        };
    }
};
pub const AlwaysValid = Concept.ok();
pub const AlwaysInvalid = Concept.fail("Concept.AlwaysInvalid", "This concept always errors");

pub fn requires(comptime concept: Concept) void {
    if (concept.err) |err| {
        @compileError("Failed to assert concept: " ++ concept.name ++ "\n" ++ err);
    }
}

pub fn decl(comptime Container: type, comptime method_name: []const u8, comptime ExpectedT: type) Concept {
    const info = @typeInfo(Container);
    const decls = switch (info) {
        .Struct => |s| s.decls,
        .Enum => |e| e.decls,
        else => @compileError("hasMethod expects a struct, union or enum"),
    };

    for (decls) |each_decl| {
        if (std.mem.eql(u8, each_decl.name, method_name)) {
            const decl_type =
                @TypeOf(@field(Container, each_decl.name));
            if (decl_type != ExpectedT) {
                return sameas(ExpectedT, decl_type);
            }

            return Concept.ok("hasMethod");
        }
    }

    return Concept.fail(
        "hasMethod",
        comptime std.fmt.comptimePrint("Type '{}' must implement the method '{s}' for it to qualify", .{ Container, method_name }),
    );
}

pub fn all(name: []const u8, concepts: anytype) Concept {
    inline for (concepts) |concept| {
        if (concept.err) |err| {
            return Concept.fail(name, err);
        }
    }
    return Concept.ok(name);
}

pub fn either(name: []const u8, concepts: anytype) Concept {
    comptime var errmsg: []const u8 = "It must implement one of";
    inline for (concepts) |concept| {
        errmsg = errmsg ++ "\n\t" ++ concept.name;
        if (concept.err) |err| {
            _ = err;
        } else {
            return Concept.ok(name);
        }
    }
    return Concept.fail(name, errmsg);
}

pub fn sameas(comptime Expect: type, comptime Got: type) Concept {
    const concept_name = "sameas(" ++ @typeName(Expect) ++ ")";
    if (Expect == Got) {
        return Concept.ok(concept_name);
    } else {
        return Concept.fail(
            concept_name,
            comptime std.fmt.comptimePrint(
                \\Got wrong type
                \\Compare		{}
                \\with expected	{}
            , .{ Got, Expect }),
        );
    }
}
