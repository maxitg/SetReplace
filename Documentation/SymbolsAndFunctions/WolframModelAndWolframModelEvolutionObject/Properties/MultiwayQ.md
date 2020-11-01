###### [Symbols and Functions](/README.md#symbols-and-functions) > [WolframModel and WolframModelEvolutionObject](../WolframModelAndWolframModelEvolutionObject.md) > [Properties](../WolframModelAndWolframModelEvolutionObject.md#properties) >

# MultiwayQ

**`"MultiwayQ"`** checks if a given evolution contains multiway branching, i.e., there is an expression used in multiple events.

```wl
In[] := WolframModel[{{1, 2}, {2, 3}} -> {{1, 2}, {2, 3}, {3, 4}},
                     {{1, 2}, {2, 3}, {3, 4}},
                     1,
                     "EventSelectionFunction" -> "MultiwaySpacelike"]["MultiwayQ"]
Out[] = True
```

Note that even if [`"EventSelectionFunction"`](../Options/EventSelectionFunction.md) is set to allow multiway branching, the system might still be singleway if no overlapping matches occured:


```wl
In[] := WolframModel[
  {{1, 2}} -> {{1, 3}, {3, 2}}, {{1, 1}}, 2, "EventSelectionFunction" -> "MultiwaySpacelike"]["MultiwayQ"]
Out[] = False
```
