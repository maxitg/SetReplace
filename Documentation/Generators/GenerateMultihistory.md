###### [Generators](README.md)

# GenerateMultihistory

## Ordering Functions

Given a state of a computational system, multiple matches can often be possible simultaneously. For example, in the
system below one can match `1 + 2`, `1 + 3` or `2 + 3`:

```wl
In[] := #["ExpressionsEventsGraph", VertexLabels -> Automatic] & @
  SetReplaceTypeConvert[{WolframModelEvolutionObject, 2}] @
    GenerateMultihistory[
          MultisetSubstitutionSystem[{a_, b_} /; a < b :> {a + b}],
          {"MaxGeneration" -> 1, "MaxEventInputs" -> 2},
          None,
          EventOrderingFunctions[MultisetSubstitutionSystem],
          {}] @
       {1, 2, 3}
```

<img src="/Documentation/Images/MultipleMatches.png" width="478.2">

Event ordering functions control the order in which these matches will be instantiated.
