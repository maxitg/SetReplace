###### >

# Type System

The basis of *SetReplace* is the type system used for objects describing evolutions of various computational systems.

We have just started working on this new system as part of *SetReplace 0.4 Yellowstone*, and no specific types have been
implemented yet.

In the future we will have multiple functions that generate these objects, such as `HypergraphSubstitutionSystem`,
`MultisetSubstitutionSystem` and `StringSubstitutionSystem`.

We will also have properties that are implemented for some of these objects, e.g., `TokenEvenGraph`. These properties
can transparently convert objects to the type required to evaluate them.

Most of the time, it is sufficient to rely on these automatic conversions, however, sometimes it might be useful to
convert an object to a different type manually for persistence or optimization, in which case one can use the
**`SetReplaceTypeConvert`** function:

```wl
SetReplaceTypeConvert[newType][object]
```
