###### [Symbols and Functions](/README.md#symbols-and-functions) > [WolframModel and WolframModelEvolutionObject](../WolframModelAndWolframModelEvolutionObject.md) > [Properties](../WolframModelAndWolframModelEvolutionObject.md#properties) >

# Element Count Lists

**`"VertexCountList"`** and **`"EdgeCountList"`** return counts of vertices and edges respectively in each state
of [`"StatesList"`](States.md). They are useful to see how quickly a particular system grows:

```wl
In[] := WolframModel[{{1, 2, 3}, {2, 4, 5}} ->
  {{6, 6, 3}, {2, 6, 2}, {6, 4, 2}, {5, 3, 6}},
 {{1, 1, 1}, {1, 1, 1}}, 10, "VertexCountList"]
Out[] = {1, 2, 4, 8, 14, 27, 49, 92, 171, 324, 622}
```

```wl
In[] := WolframModel[{{1, 2, 3}, {2, 4, 5}} ->
  {{6, 6, 3}, {2, 6, 2}, {6, 4, 2}, {5, 3, 6}},
 {{1, 1, 1}, {1, 1, 1}}, 10, "EdgeCountList"]
Out[] = {2, 4, 8, 16, 28, 54, 98, 184, 342, 648, 1244}
```
