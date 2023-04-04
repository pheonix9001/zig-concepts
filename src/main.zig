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

pub fn decl(comptime Container: type, comptime method_name: []const u8, comptime ExpectedT: type) Concept {
	const concept_name = "hasMethod(" ++ method_name ++ ", " ++ @typeName(ExpectedT) ++ ")";
    const info = @typeInfo(Container);
    const decls = switch (info) {
        .Struct => |s| s.decls,
        .Enum => |e| e.decls,
        .Union => |e| e.decls,
        else => @compileError("hasMethod expects a struct, union or enum"),
    };

    for (decls) |each_decl| {
        if (std.mem.eql(u8, each_decl.name, method_name)) {
            const decl_type =
                @TypeOf(@field(Container, each_decl.name));
            if (decl_type != ExpectedT) {
                return sameas(ExpectedT, decl_type).with_name(concept_name);
            }

            return Concept.ok(concept_name);
        }
    }

    return Concept.fail(
        concept_name,
        comptime std.fmt.comptimePrint("Type '{}' must implement the method '{s}' for it to qualify", .{ Container, method_name }),
    );
}

pub fn all(concepts: anytype) Concept {
    inline for (concepts) |concept| {
        if (concept.err) |err| {
            return Concept.fail("all", err);
        }
    }
    return Concept.ok("all");
}

pub fn either(concepts: anytype) Concept {
    comptime var errmsg: []const u8 = "It must implement one of";
    inline for (concepts) |concept| {
        errmsg = errmsg ++ "\n\t" ++ concept.name;
        if (concept.err) |err| {
            _ = err;
        } else {
            return Concept.ok("either");
        }
    }
    return Concept.fail("either", errmsg);
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

pub fn not(comptime in: Concept) Concept {
	const concept_name = "!" ++ in.name;
	if(in.err) |err| {
		_ = err;
		return Concept.ok(concept_name);
	} else {
		return Concept.fail(concept_name, "The concept " ++ in.name ++ " Should not be implemented");
	}
}
