# SetReplaceSystemParameters

**`SetReplaceSystemParameters`** gives the list of parameters that can be used as keys in generators such as
[`GenerateMultihistory`](GenerateMultihistory.md):

```wl
In[] := SetReplaceSystemParameters[MultisetSubstitutionSystem]
Out[] = {MaxGeneration, MaxDestroyerEvents, MinEventInputs, MaxEventInputs, MaxEvents}
```

The entire system spec including the rules can be passed as well (although the rules don't affect the result):

```wl
In[] := SetReplaceSystemParameters[AtomicStateSystem[a_ :> a + 1]]
Out[] = {MaxGeneration, MaxDestroyerEvents, MaxEvents}
```
