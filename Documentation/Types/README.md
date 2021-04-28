# Types

The basis of *SetReplace* is a [type system](/Documentation/TypeSystem/README.md) which allows one to separate
generation of data (such as the data about the evaluation of a
[nondeterministic system](/Documentation/Systems/README.md)) and computation of
[properties](/Documentation/Properties/README.md) from that data.

The usual form for the type spec is `{system, version}`, e.g., `{MultisetSubstitutionSystem, 0}`.

* [`Multihistory`](Multihistory/README.md) &mdash; a generic kind of types for computational systems:
  * [`{MultisetSubstitutionSystem, 0}`](Multihistory/MultisetSubstitutionSystem0.md)
