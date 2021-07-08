# MaxDestroyerEvents

`MaxDestroyerEvents` is an event-selection parameter that controls the number of (inconsistent) events that are allowed
to take the same token as an input. [`GenerateSingleHistory`](GenerateSingleHistory.md) limits the evaluation to a
single history by setting `MaxDestroyerEvents` to one.

```wl
In[] := #["ExpressionsEventsGraph", VertexLabels -> Placed[Automatic, After]] & @
  SetReplaceTypeConvert[{WolframModelEvolutionObject, 2}] @
    GenerateMultihistory[MultisetSubstitutionSystem[{a_, b_} :> {a + b}], {1, 2, 3}, MaxDestroyerEvents -> 1]
```

<img src="/Documentation/Images/MaxDestroyerEvents1.png" width="322.2">

If unset (which defaults to [`Infinity`](https://reference.wolfram.com/language/ref/Infinity.html)), it will generate a
full multihistory subject to other selection and stopping parameters:

```wl
In[] := #["ExpressionsEventsGraph", VertexLabels -> Placed[Automatic, After]] & @
  SetReplaceTypeConvert[{WolframModelEvolutionObject, 2}] @
    GenerateMultihistory[
      MultisetSubstitutionSystem[{a_, b_} :> {a + b}], {1, 2, 3}, MaxDestroyerEvents -> Infinity, MaxGeneration -> 1]
```

<img src="/Documentation/Images/MaxDestroyerEventsInfinity.png" width="478.2">

If set to a finite number, it will generate a partial multihistory:

```wl
In[] := #["ExpressionsEventsGraph", VertexLabels -> Placed[Automatic, After]] & @
  SetReplaceTypeConvert[{WolframModelEvolutionObject, 2}] @
    GenerateMultihistory[MultisetSubstitutionSystem[{a_, b_} :> {a + b}], {1, 2, 3}, MaxDestroyerEvents -> 5]
```

<img src="/Documentation/Images/MaxDestroyerEvents5.png" width="478.2">

Note that in this case, like in the case of a single history, the result depends on the event order.
