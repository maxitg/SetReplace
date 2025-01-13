###### [Symbols and Functions](/README.md#symbols-and-functions) > [WolframModel and WolframModelEvolutionObject](../WolframModelAndWolframModelEvolutionObject.md) > [Properties](../WolframModelAndWolframModelEvolutionObject.md#properties) >

# Rule Indices for Events

**`"AllEventsRuleIndices"`** returns which rule was used for each event (the same can be obtained by
mapping [`First`](https://reference.wolfram.com/language/ref/First.html) over [`"AllEventsList"`](Events.md)):

```wl
In[] := WolframModel[{{{1, 1, 2}} -> {{2, 2, 1}, {2, 3, 2}, {1, 2, 3}},
  {{1, 2, 1}, {3, 4, 2}} -> {{4, 3, 2}}},
 {{1, 1, 1}}, 4, "AllEventsRuleIndices"]
Out[] = {1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 2, 1, 2}
```

A neat example of using `"AllEventsRuleIndices"` is coloring events in a causal graph according to the rule index. With
this visualization, one can see, for instance, that the outputs of the second rule in the example above are never used
in any further inputs:

```wl
In[] := With[{
  evolution =
   WolframModel[{{{1, 1, 2}} -> {{2, 2, 1}, {2, 3, 2}, {1, 2, 3}},
     {{1, 2, 1}, {3, 4, 2}} -> {{4, 3, 2}}}, {{1, 1, 1}}, 6]}, With[{
   causalGraph = evolution["LayeredCausalGraph"]},
  Graph[causalGraph,
   VertexStyle ->
    Thread[VertexList[causalGraph] ->
      Replace[evolution["AllEventsRuleIndices"], {1 -> Black,
        2 -> White}, {1}]], VertexSize -> Medium]]]
```

<img src="/Documentation/Images/ColoredCausalGraph.png"
     width="478"
     alt="Out[] = ... causal graph with event vertices shown in 2 colors corresponding to their rule ...">
