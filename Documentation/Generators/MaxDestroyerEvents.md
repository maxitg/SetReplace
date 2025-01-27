# MaxDestroyerEvents

`MaxDestroyerEvents` is an event-selection parameter that controls the number of inconsistent events allowed to take the
same token as an input. [`GenerateSingleHistory`](GenerateSingleHistory.md) limits the evaluation to a single history by
setting `MaxDestroyerEvents` to one.

```wl
In[] := #["ExpressionsEventsGraph", VertexLabels -> Placed[Automatic, After]] & @
  SetReplaceTypeConvert[WolframModelEvolutionObject] @
    GenerateMultihistory[MultisetSubstitutionSystem[{a_, b_} :> {a + b}], MaxDestroyerEvents -> 1] @ {1, 2, 3}
```

<img src="/Documentation/Images/MaxDestroyerEvents1.png"
     width="322.2"
     alt="Out[] = ... {1, 2} -> {3 (* gen 1 *)}, {3 (* init *), 3 (* gen 1 *)} -> 6 ...">

If unset (which defaults to [`Infinity`](https://reference.wolfram.com/language/ref/Infinity.html)), it will generate a
full multihistory object subject to other selection and stopping parameters:

```wl
In[] := #["ExpressionsEventsGraph", VertexLabels -> Placed[Automatic, After]] & @
  SetReplaceTypeConvert[WolframModelEvolutionObject] @
    GenerateMultihistory[
      MultisetSubstitutionSystem[{a_, b_} :> {a + b}], MaxDestroyerEvents -> Infinity, MaxGeneration -> 1] @ {1, 2, 3}
```

<img src="/Documentation/Images/MaxDestroyerEventsInfinity.png"
     width="478.2"
     alt="Out[] = ... {1, 2} -> {3 (* 1 + 2 *)}, {2, 1} -> {3 (* 2 + 1 *)}, {1, 3 (* init *)} -> {4}, <<3>> ...">

If set to a finite number, it will generate a partial multihistory:

```wl
In[] := #["ExpressionsEventsGraph", VertexLabels -> Placed[Automatic, After]] & @
  SetReplaceTypeConvert[WolframModelEvolutionObject] @
    GenerateMultihistory[MultisetSubstitutionSystem[{a_, b_} :> {a + b}], MaxDestroyerEvents -> 5] @ {1, 2, 3}
```

<img src="/Documentation/Images/MaxDestroyerEvents5.png"
     width="478.2"
     alt="Out[] = ... token-event graph containing tokens with out degrees up to 5 ...">

Note that results generally depend on the event order in this case, similar to single histories.
