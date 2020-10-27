###### [Symbols and Functions](/README.md#symbols-and-functions) > Utility Functions >

# HypergraphUnifications

When considering which matches could potentially exist to a given set of rule inputs, it is often useful to see all possible ways hypergraphs can overlap. **`HypergraphUnifications`** constructs all possible hypergraphs that contain subgraphs matching both of its arguments. The argument-hypergraphs must overlap by at least a single edge. `HypergraphUnifications` identifies vertices to the least extent possible, but it makes some identifications if necessary for matching.

The output format is a list of triples `{unified hypergraph, first argument edge matches, second argument edge matches}`, where the last two elements are associations mapping the edge indices in the input hypergraphs to the edge indices in the unified hypergraph.

As an example, consider a simple case of two adjacent binary edges:

```wl
In[] := HypergraphUnifications[{{1, 2}, {2, 3}}, {{1, 2}, {2, 3}}]
Out[] = {{{{3, 1}, {3, 4}, {2, 3}}, <|1 -> 3, 2 -> 1|>, <|1 -> 3, 2 -> 2|>},
 {{{2, 3}, {3, 1}}, <|1 -> 1, 2 -> 2|>, <|1 -> 1, 2 -> 2|>},
 {{{4, 1}, {2, 3}, {3, 4}}, <|1 -> 3, 2 -> 1|>, <|1 -> 2, 2 -> 3|>},
 {{{1, 2}, {2, 1}}, <|1 -> 1, 2 -> 2|>, <|1 -> 2, 2 -> 1|>},
 {{{1, 2}, {3, 4}, {2, 3}}, <|1 -> 1, 2 -> 3|>, <|1 -> 3, 2 -> 2|>},
 {{{1, 3}, {2, 3}, {3, 4}}, <|1 -> 1, 2 -> 3|>, <|1 -> 2, 2 -> 3|>}}
```

In the first output here `{{{3, 1}, {3, 4}, {2, 3}}, <|1 -> 3, 2 -> 1|>, <|1 -> 3, 2 -> 2|>}`, the graphs are overlapping by a shared edge `{2, 3}`, and two inputs are matched respectively to `{{2, 3}, {3, 1}}` and `{{2, 3}, {3, 4}}`.

All unifications can be visualized with **`HypergraphUnificationsPlot`**:

```wl
In[] := HypergraphUnificationsPlot[{{1, 2}, {2, 3}}, {{1, 2}, {2, 3}}]
```

<img src="/Documentation/Images/HypergraphUnificationsPlot.png" width="745">

Vertex labels here show the vertex names in the input graphs to which the unification is matched.

A more complicated example with edges of various arities is

```wl
In[] := HypergraphUnificationsPlot[{{1, 2, 3}, {4, 5, 6}, {1, 4}},
 {{1, 2, 3}, {4, 5, 6}, {1, 4}}, VertexLabels -> Automatic]
```

<img src="/Documentation/Images/HypergraphUnificationsPlotWithMultipleArities.png" width="746">
