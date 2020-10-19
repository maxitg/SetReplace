###### [Symbols and Functions](/README.md#symbols-and-functions) > [WolframModel and WolframModelEvolutionObject](../WolframModelAndWolframModelEvolutionObject.md) > [Properties](../WolframModelAndWolframModelEvolutionObject.md#properties) >

# All Edges throughout Evolution

**`"AllEventsEdgesList"`** (aka `"AllExpressions"`) returns the list of edges throughout evolution. This is distinct from a catenated [`"StateList"`](States.md), as the edge does not appear twice if it moved from one generation to the next without being involved in an event.

Compare for instance the output of [`"StatesList"`](States.md) for a system where only one replacement is made per generation:

```wl
In[] := WolframModel[<|"PatternRules" -> {x_?OddQ, y_} :> x + y|>,
 {1, 2, 4, 6}, Infinity, "StatesList"]
Out[] = {{1, 2, 4, 6}, {4, 6, 3}, {6, 7}, {13}}
```

to the output of `"AllEventsEdgesList"`:

```wl
In[] := WolframModel[<|"PatternRules" -> {x_?OddQ, y_} :> x + y|>,
 {1, 2, 4, 6}, Infinity, "AllEventsEdgesList"]
Out[] = {1, 2, 4, 6, 3, 7, 13}
```

Note how 4 and 6 only appear once in the list.

Edge indices from `"AllEventsEdgesList"` are used in various other properties such as [`"AllEventsList"`](Events.md) and [`"EventsStatesList"`](EventsAndStates.md).
