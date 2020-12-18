###### [Symbols and Functions](/README.md#symbols-and-functions) > [WolframModel and WolframModelEvolutionObject](../WolframModelAndWolframModelEvolutionObject.md) > [Properties](../WolframModelAndWolframModelEvolutionObject.md#properties) >

# Total Element Counts

**`"AllEventsDistinctElementsCount"`** (aka `"AtomsCountTotal"`) and **`"AllEventsEdgesCount"`** (
aka `"ExpressionsCountTotal"`) are similar to [`"FinalDistinctElementsCount"`](FinalElementCounts.md)
and [`"FinalEdgeCount"`](FinalElementCounts.md), except they count atoms and edges throughout the entire evolution
instead of just in the final step.

For instance,

```wl
In[] := WolframModel[{{1, 2, 3}, {2, 4, 5}} ->
  {{6, 6, 3}, {2, 6, 2}, {6, 4, 2}, {5, 3, 6}},
 {{1, 1, 1}, {1, 1, 1}}, 10,
 {"AllEventsDistinctElementsCount", "AllEventsEdgesCount"}]
Out[] = {622, 2486}
```
