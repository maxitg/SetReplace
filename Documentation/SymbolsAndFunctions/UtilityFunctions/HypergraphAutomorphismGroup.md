###### [Symbols and Functions](/README.md#symbols-and-functions) > Utility Functions >

# HypergraphAutomorphismGroup

**`HypergraphAutomorphismGroup`** does the same thing as [`GraphAutomorphismGroup`](https://reference.wolfram.com/language/ref/GraphAutomorphismGroup.html), but for ordered hypergraphs:

```wl
In[] := HypergraphAutomorphismGroup[{{1, 2, 3}, {1, 2, 4}}]
Out[] = PermutationGroup[{Cycles[{{3, 4}}]}]
```

A more complicated example:

```wl
In[] := GroupOrder[
 HypergraphAutomorphismGroup[
  EchoFunction[
    HypergraphPlot] @ {{1, 2, 3}, {3, 4, 5}, {5, 6, 1}, {1, 7, 3}, {3,
      8, 5}, {5, 9, 1}}]]
```

<img src="/Documentation/Images/SymmetricHypergraphPlot.png" width="451">

```wl
Out[] = 24
```
