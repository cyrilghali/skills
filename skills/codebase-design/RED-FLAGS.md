# Red Flags

Screen a candidate design against these before committing to it, whether it's the only design on the table or one of several from [DESIGN-IT-TWICE.md](DESIGN-IT-TWICE.md). Each is a shape that looks fine locally and only shows its cost once callers or maintainers hit it. A hit here is a reason to revise or reject the shape, not a style nit.

## Shallow module

The interface is nearly as large as what it hides. See [SKILL.md](SKILL.md#deep-vs-shallow) for the definition; the tells:

- Callers coordinate several calls to complete one operation that should be one call.
- Public options expose internal stages or implementation choices rather than outcomes.
- Learning the interface doesn't save the caller from learning the implementation anyway.

Don't confuse this with a deep call chain: a long chain scatters understanding across layers, while a shallow module fails to concentrate it in the first place.

## Information leakage

Two or more modules depend on the same internal decision: a representation, a policy, or a protocol detail that appears in more than one place, so changing it means coordinated edits across modules that shouldn't need to know about each other.

The common case is re-exporting a transport or storage type through the public surface instead of parsing it into a domain type at the seam. Keep wire formats, ORM structs, and framework payloads private to the module that owns the adapter.

## Temporal decomposition

Modules organized by execution order (load, then validate, then transform, then save) instead of by the domain knowledge they own. Each stage often repeats the same representation and the same invariants, so a rule change means editing every stage instead of one module.

Group by what the code protects, not by when it runs. Steps that execute at different times can still belong to one module if they guard the same invariant.

## Pass-through method

A method that forwards the same arguments to another method with the same shape, adding a layer without hiding anything. The [deletion test](SKILL.md#principles) catches this directly: delete the method, and if nothing downstream gets harder, it wasn't earning its keep.

Keep a forwarding layer only when it adds policy, adapts a shape, or introduces a genuinely distinct abstraction — never as a bare rename.
