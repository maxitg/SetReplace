# MinEventInputs

`MinEventInputs` and [`MaxEventInputs`](MaxEventInputs.md) are event-selection parameters that control the min and max
numbers of input tokens allowed per event. These parameters are useful in systems where rules with variable numbers of
inputs are possible, such as [`MultisetSubstitutionSystem`](/Documentation/Systems/MultisetSubstitutionSystem.md).
Compare, for example, `MinEventInputs -> 0` (default):

```wl
In[] := #["ExpressionsEventsGraph", VertexLabels -> Placed[Automatic, After]] & @
  SetReplaceTypeConvert[{WolframModelEvolutionObject, 2}] @
    GenerateMultihistory[
      MultisetSubstitutionSystem[{a___} :> {Total[{a}]}], {1, 2, 3}, MinEventInputs -> 0, MaxEvents -> 10]
```

<img src="/Documentation/Images/MinEventInputs0.png" width="367.8">

and `MinEventInputs -> 2`:

```wl
In[] := #["ExpressionsEventsGraph", VertexLabels -> Placed[Automatic, After]] & @
  SetReplaceTypeConvert[{WolframModelEvolutionObject, 2}] @
    GenerateMultihistory[
      MultisetSubstitutionSystem[{a___} :> {Total[{a}]}], {1, 2, 3}, MinEventInputs -> 2, MaxEvents -> 10]
```

<img src="/Documentation/Images/MinEventInputs2.png" width="478.2">
