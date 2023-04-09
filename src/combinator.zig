//! Combinators for concepts

const core = @import("core.zig");
const std = @import("std");

/// Succeeds when all the child concepts succeed
pub fn all(concepts: anytype) core.Concept {
    const concept_name = core.fnlike_name("all", concepts);
    inline for (concepts) |concept| {
        if (concept.err) |err| {
            return core.Concept.fail(concept_name, err);
        }
    }
    return core.Concept.ok(concept_name);
}

/// Succeeds when any one of the concepts succeeds
pub fn either(concepts: anytype) core.Concept {
    const concept_name = core.fnlike_name("either", concepts);
    comptime var errmsg: []const u8 = "It must implement one of";
    inline for (concepts) |concept| {
        errmsg = errmsg ++ "\n\t" ++ concept.name;
        if (concept.err) |err| {
            _ = err;
        } else {
            return core.Concept.ok(concept_name);
        }
    }
    return core.Concept.fail(concept_name, errmsg);
}

/// Succeeds when Expect == Got
pub fn eq(comptime Expect: type, comptime Got: type) core.Concept {
    const concept_name = core.fnlike_name("eq", .{ Expect, Got });
    if (Expect == Got) {
        return core.Concept.ok(concept_name);
    } else {
        return core.Concept.fail(
            concept_name,
            comptime std.fmt.comptimePrint(
                \\Got wrong type
                \\Compare		{}
                \\with expected	{}
            , .{ Got, Expect }),
        );
    }
}

/// Succeeds when the child concept fails
pub fn not(comptime in: core.Concept) core.Concept {
    const concept_name = "!" ++ in.name;
    if (in.err) |err| {
        _ = err;
        return core.Concept.ok(concept_name);
    } else {
        return core.Concept.fail(concept_name, "The concept " ++ in.name ++ " Should not be implemented");
    }
}

test "Either concept test" {
    const requires = main.requires;
    requires(not(
        either(.{ main.AlwaysInvalid, main.AlwaysInvalid }),
    ));
    requires(
        either(.{ main.AlwaysValid, main.AlwaysInvalid }),
    );
}

test "Eq concept" {
    const requires = main.requires;
    requires(eq(i32, i32));
    requires(not(eq(i32, bool)));
}
