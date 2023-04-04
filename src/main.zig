const std = @import("std");
test {
    _ = @import("test.zig");
}

pub const Concept = union(enum) {
    Ok,
    Err: struct {
        src: []const u8,
        err: []const u8,
    },
    pub fn ok() Concept {
        return Concept.Ok;
    }
    pub fn err(src: []const u8, _err: []const u8) Concept {
        return Concept{ .Err = .{
            .err = _err,
            .src = src,
        } };
    }
};
pub const AlwaysValid = Concept.ok();
pub const AlwaysInvalid = Concept.err("Concept.AlwaysInvalid", "This concept always errors");

pub fn requires(comptime concept: Concept) void {
    switch (concept) {
        .Ok => {},
        .Err => |err| @compileError("Failed to assert concept: " ++ err.src ++ "\n" ++ err.err),
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
                return Concept.err(
                    "hasMethod",
                    comptime std.fmt.comptimePrint(
                        \\method {s} is implemented in {} but has the wrong type
                        \\Compare		{}
                        \\with expected	{}
                    , .{ method_name, Container, decl_type, ExpectedT }),
                );
            }

            return Concept.ok();
        }
    }

    return Concept.err(
        "hasMethod",
        comptime std.fmt.comptimePrint("Type '{}' must implement the method '{s}' for it to qualify", .{ Container, method_name }),
    );
}

pub fn all(name: []const u8, concepts: anytype) Concept {
    inline for (concepts) |concept| {
        switch (concept) {
            .Ok => {},
            .Err => |err| {
                return Concept.err(name, err.err);
            },
        }
    }
    return Concept.ok();
}

pub fn either(name: []const u8, concepts: anytype) Concept {
    comptime var errmsg: []const u8 = "It must implement one of";
    inline for (concepts) |concept| {
        switch (concept) {
            .Ok => return Concept.ok(),
            .Err => |err| errmsg = errmsg ++ "\n\t" ++ err.src,
        }
    }
    return Concept.err(name, errmsg);
}
