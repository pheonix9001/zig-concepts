//! Combinators for concepts

const main = @import("main.zig");
const Concept = main.Concept;
const std = @import("std");

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
        either(.{ main.AlwaysInvalid, main.AlwaysInvalid }).with_name("EitherConcept"),
    ));
    requires(
        either(.{ main.AlwaysValid, main.AlwaysInvalid }).with_name("EitherConcept"),
    );
}

test "Sameas" {
    const requires = main.requires;
    requires(sameas(i32, i32));
    requires(not(sameas(i32, bool)));
}
