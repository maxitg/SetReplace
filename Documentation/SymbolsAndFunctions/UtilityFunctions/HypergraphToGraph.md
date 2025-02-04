###### [Symbols and Functions](/README.md#symbols-and-functions) > Utility Functions >

# HypergraphToGraph

**`HypergraphToGraph`** converts a hypergraph to a [`Graph`](https://reference.wolfram.com/language/ref/Graph.html)
object. There are (currently) 3 ways to perform this transformation:

## **"DirectedDistancePreserving"**

Converts a hypergraph to a directed graph with the same distance matrix, where distance between two vertices `v1`
and `v2` in a hypergraph is defined as the minimum length of a path which connects `v1` and `v2` (i.e. 1 if both
vertices belong to the same hyperedge):

```wl
In[]:= HypergraphToGraph[
  {{x, x, y, z}, {z, w}},
  "DirectedDistancePreserving",
  VertexLabels -> Automatic,
  GraphLayout -> "SpringElectricalEmbedding"]
```

<img src="/Documentation/Images/HypergraphToGraphDirectedDistancePreserving.png"
     width="478"
     alt="Out[] = Graph[{x -> x, x -> y, x -> z, x -> y, x -> z, y -> z, z -> w}, ...]">

## **"UndirectedDistancePreserving"**

Converts a hypergraph to an undirected graph with the same distance matrix, that is, each hyperedge is mapped to a
complete subgraph:

```wl
In[]:= HypergraphToGraph[
  {{x, x, y, z}, {z, w}},
  "UndirectedDistancePreserving",
  VertexLabels -> Automatic,
  GraphLayout -> "SpringElectricalEmbedding"]
```

<img src="/Documentation/Images/HypergraphToGraphUndirectedDistancePreserving.png"
     width="478"
     alt="Out[] = Graph[{x <-> x, x <-> y, x <-> z, x <-> y, x <-> z, y <-> z, z <-> w}, ...]">

## **"StructurePreserving"**

Converts a hypergraph to a graph by preserving its structure. This is achieved by a one-to-one correspondence between
  vertices and hyperedges in the hypergraph and 2 different kind of
  vertices - `{"Hyperedge", hyperedgeIndex_, vertexIndex_}` and `{"Vertex", vertexName_}` - in the graph:

```wl
In[]:= HypergraphToGraph[
  {{x, x, y, z}, {z, w}},
  "StructurePreserving",
  VertexLabels -> Automatic]
```

<img src="/Documentation/Images/HypergraphToGraphStructurePreserving.png"
     width="352"
     alt='Out[] = Graph[
       {{"Hyperedge", 1, 1} -> {"Vertex", x}, {"Hyperedge", 1, 1} -> {"Hyperedge", 1, 2},
       {"Hyperedge", 1, 2} -> {"Vertex", x}, {"Hyperedge", 1, 2} -> {"Hyperedge", 1, 3},
       {"Hyperedge", 1, 3} -> {"Vertex", y}, {"Hyperedge", 1, 3} -> {"Hyperedge", 1, 4},
       {"Hyperedge", 1, 4} -> {"Vertex", z}, {"Hyperedge", 2, 1} -> {"Vertex", z},
       {"Hyperedge", 2, 1} -> {"Hyperedge", 2, 2}, {"Hyperedge", 2, 2} -> {"Vertex", w}}, ...]'>

It is important to mention that this conversion does not lose any information, and it is possible to unambiguously
retrieve the original hypergraph from the resulting [`Graph`](https://reference.wolfram.com/language/ref/Graph.html):

```wl
fromStructurePreserving[graph_Graph] := Values @ KeySort @ Join[
  GroupBy[Sort @ EdgeList[graph, DirectedEdge[_, {"Vertex", _}]], #[[1, 2]] & -> (#[[2, 2]] &)],
  AssociationMap[{} &, VertexList[graph, {"Hyperedge", _, 0}][[All, 2]]]]

In[]:= {{x, x, y, z}, {}, {z, w}} === fromStructurePreserving @ HypergraphToGraph[
  {{x, x, y, z}, {}, {z, w}}, "StructurePreserving"]
Out[]= True
```
