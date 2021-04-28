# Types

The basis of *SetReplace* is a [type system](/Documentation/TypeSystem/README.md) which allows one to separate
generation of data (such as the data about the evaluation of a
[non-deterministic system](/Documentation/Systems/README.md)) and computation of
[properties](/Documentation/Properties/README.md) from that data.

Types are usually named with a list with the second element representing the version, e.g.,
`{MultisetSubstitutionSystem, 0}`.

* [`Multihistory`](Multihistory/README.md) &mdash; a generic kind of types for computational systems:
  * [`{MultisetSubstitutionSystem, 0}`](Multihistory/MultisetSubstitutionSystem0.md)
