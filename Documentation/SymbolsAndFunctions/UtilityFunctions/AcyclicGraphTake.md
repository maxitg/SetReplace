###### [Symbols and Functions](/README.md#symbols-and-functions) > Utility Functions >

# AcyclicGraphTake

**`AcyclicGraphTake`** gives the intersection of the out-component of the first vertex
with the in-component of the second vertex:

```wl
In[] := graph = BlockRandom[
  DirectedGraph[RandomGraph[{10, 10}], "Acyclic", VertexLabels -> Automatic],
  RandomSeeding -> 2
]
```

<img src="/Documentation/Images/AcyclicGraphTakeInput.png"
     width="478.2"
     alt="Out[] = ... directed acyclic graph with 10 vertices and multiple branches ...">

```wl
In[] := AcyclicGraphTake[graph, {1, 9}]
```

<img src="/Documentation/Images/AcyclicGraphTakeOutput.png"
     width="232.2"
     alt="Out[] = ... subgraph of the input graph with only vertices between 1 and 9 remaining ...">
