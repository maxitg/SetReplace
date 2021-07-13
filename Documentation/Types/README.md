# Types

The basis of *SetReplace* is a [type system](/Documentation/TypeSystem/README.md) which allows one to separate
generation of data (such as the data about the evaluation of a
[nondeterministic system](/Documentation/Systems/README.md)) and computation of
[properties](/Documentation/Properties/README.md) from that data.

Multihistory types are named after systems that produce them, e.g., `SetReplaceType[MultisetSubstitutionSystem, 1]`.

* [`Multihistory`](Multihistory/README.md) &mdash; a generic kind of types for computational systems:
  * [`AtomicStateSystem`](Multihistory/AtomicStateSystem0.md)
  * [`MultisetSubstitutionSystem`](Multihistory/MultisetSubstitutionSystem0.md)
