# Systems

*SetReplace* supports multiple computational systems. The system-specific functions such as
[`MultisetSubstitutionSystem`](MultisetSubstitutionSystem.md) do not perform the evaluation themselves. Instead, one
uses them to specify the rules for the [generators](/Documentation/Generators/README.md).

These functions typically take a single argument for the system-specific rules:

* [`AtomicStateSystem`](AtomicStateSystem.md)
* [`MultisetSubstitutionSystem`](MultisetSubstitutionSystem.md)
