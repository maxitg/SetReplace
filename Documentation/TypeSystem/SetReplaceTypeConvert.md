# SetReplaceTypeConvert

**`SetReplaceTypeConvert`** allows one to convert one [type](/Documentation/Types/README.md) (of, e.g.,
[`Multihistory`](/Documentation/Types/Multihistory/README.md)) into another:

```wl
SetReplaceTypeConvert[newType][object]
```

For example, one can convert an
[`AtomicStateSystem` multihistory](/Documentation/Types/Multihistory/AtomicStateSystem0.md) to a
[`MultisetSubstitutionSystem` multihistory](/Documentation/Types/Multihistory/MultisetSubstitutionSystem0.md):

<img src="/Documentation/Images/AtomicStateToMultisetMultihistory.png"
     width="517.8"
     alt="
       In[] := SetReplaceTypeConvert[MultisetSubstitutionSystem] @ Multihistory[... AtomicStateSystem v0 ...]
       Out[] = Multihistory[... MultisetSubstitutionSystem v0 ...]
     ">

To convert to a specific version of a type, one can use the full type specification:

<img src="/Documentation/Images/AtomicStateToMultisetMultihistoryVersioned.png"
     width="693.0"
     alt="
       In[] := SetReplaceTypeConvert[
         SetReplaceType[MultisetSubstitutionSystem, 0]
       ] @ Multihistory[... AtomicStateSystem v0 ...]
       Out[] = Multihistory[... MultisetSubstitutionSystem v0 ...]
     ">
