###### [Symbols and Functions](/README.md#symbols-and-functions) > [WolframModel and WolframModelEvolutionObject](../WolframModelAndWolframModelEvolutionObject.md) > [Properties](../WolframModelAndWolframModelEvolutionObject.md#properties) >

# Final Element Counts

**`FinalDistinctElementsCount`** (aka `"AtomsCountFinal"`) and **`FinalEdgeCount`** (aka `"ExpressionsCountFinal"`) are
similar to corresponding [`*List`](ElementCountLists.md) properties, except we don't have `"FinalVertexCount"` (we
should have it and also `"DistinctElementsCountList"`, but they are not currently implemented).

The difference is that [`"VertexCountList"`](ElementCountLists.md) counts expressions on level 2 in the states
whereas `"FinalDistinctElementsCount"` counts all expressions matching `_ ? AtomQ` (on any level). The difference
becomes apparent for edges that contain non-trivially nested lists.

For example, consider a rule that performs non-trivial nesting:

```wl
In[] := WolframModel[<|
  "PatternRules" -> {{a_}} :> {{a + 1}, {a - 1}, {{a + 2, a - 2}}}|>,
 {{1}}, 7, "VertexCountList"]
Out[] = {1, 3, 6, 10, 15, 21, 28, 36}
```

```wl
In[] := WolframModel[<|"PatternRules" ->
     {{a_}} :> {{a + 1}, {a - 1}, {{a + 2, a - 2}}}|>,
   {{1}}, #, "FinalDistinctElementsCount"] & /@ Range[0, 7]
Out[] = {1, 4, 9, 13, 17, 21, 25, 29}
```

To understand why this is happening, consider the state after one step:

```wl
In[] := WolframModel[<|
  "PatternRules" -> {{a_}} :> {{a + 1}, {a - 1}, {{a + 2, a - 2}}}|>,
 {{1}}, 1, "FinalState"]
Out[] = {{2}, {0}, {{3, -1}}}
```

This state has 3 vertices (distinct level-2 expressions): `2`, `0`, and `{3, -1}`, but 4 atoms: `2`, `0`, `3`, and `-1`.
This distinction does not usually come up in our models since vertices and atoms are usually the same things, but it is
significant in exotic cases like this.
