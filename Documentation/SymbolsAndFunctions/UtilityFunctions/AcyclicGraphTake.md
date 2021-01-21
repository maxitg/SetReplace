###### [Symbols and Functions](/README.md#symbols-and-functions) > Utility Functions >

# AcyclicGraphTake

**`AcyclicGraphTake`** gives the subgraph of a graph between two vertices.

```wl
In[]:= AcyclicGraphTake[DirectedGraph[CycleGraph[10], "Acyclic"], {1, 4}]
Out[]= Graph[1 -> 2, 2 -> 3, 3 -> 4]
```