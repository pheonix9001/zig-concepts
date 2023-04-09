//! Combinators for concepts

const main = @import("main.zig");
const Concept = main.Concept;
const fnlike_name = main.fnlike_name;
const std = @import("std");

pub fn all(concepts: anytype) Concept {
    const concept_name = fnlike_name("all", concepts);
    inline for (concepts) |concept| {
        if (concept.err) |err| {
            return Concept.fail(concept_name, err);
        }
    }
    return Concept.ok(concept_name);
}

pub fn either(concepts: anytype) Concept {
    const concept_name = fnlike_name("either", concepts);
    comptime var errmsg: []const u8 = "It must implement one of";
    inline for (concepts) |concept| {
        errmsg = errmsg ++ "\n\t" ++ concept.name;
        if (concept.err) |err| {
            _ = err;
        } else {
            return Concept.ok(concept_name);
        }
    }
    return Concept.fail(concept_name, errmsg);
}

pub fn eq(comptime Expect: type, comptime Got: type) Concept {
    const concept_name = fnlike_name("eq", .{ Expect, Got });
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
    if (in.err) |err| {
        _ = err;
        return Concept.ok(concept_name);
    } else {
        return Concept.fail(concept_name, "The concept " ++ in.name ++ " Should not be implemented");
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
