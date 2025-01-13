# MinEventInputs

`MinEventInputs` and [`MaxEventInputs`](MaxEventInputs.md) are event-selection parameters that control the min and max
numbers of input tokens allowed per event. These parameters are useful in systems where rules with variable numbers of
inputs are possible, such as [`MultisetSubstitutionSystem`](/Documentation/Systems/MultisetSubstitutionSystem.md).
Compare, for example, `MinEventInputs -> 0` (default):

```wl
In[] := #["ExpressionsEventsGraph", VertexLabels -> Placed[Automatic, After]] & @
  SetReplaceTypeConvert[WolframModelEvolutionObject] @
    GenerateMultihistory[
      MultisetSubstitutionSystem[{a___} :> {Total[{a}]}], MinEventInputs -> 0, MaxEvents -> 10] @ {1, 2, 3}
```

<img src="/Documentation/Images/MinEventInputs0.png"
     width="367.8"
     alt="Out[] = ... {} -> {0}, {1 (* init *)} -> {1 (* gen 1 *)}, {2 (* init *)} -> {2 (* gen 1 *)}, ... ...">

and `MinEventInputs -> 2`:

```wl
In[] := #["ExpressionsEventsGraph", VertexLabels -> Placed[Automatic, After]] & @
  SetReplaceTypeConvert[WolframModelEvolutionObject] @
    GenerateMultihistory[
      MultisetSubstitutionSystem[{a___} :> {Total[{a}]}], MinEventInputs -> 2, MaxEvents -> 10] @ {1, 2, 3}
```

<img src="/Documentation/Images/MinEventInputs2.png"
     width="478.2"
     alt="Out[] = ... {1, 2} -> {3 (* 1 + 2 *)}, {2, 1} -> {3 (* 2 + 1 *)}, {1, 3 (* init *)} -> {4} ...">
