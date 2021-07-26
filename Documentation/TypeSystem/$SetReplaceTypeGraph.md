# $SetReplaceTypeGraph

**`$SetReplaceTypeGraph`** gives the [`Graph`](https://reference.wolfram.com/language/ref/Graph.html) showing
[types](/Documentation/Types/README.md) and [properties](/Documentation/Properties/README.md) defined in *SetReplace*
(including internal ones) and possible computation paths between them:

```wl
In[] := $SetReplaceTypeGraph
```

<img src="/Documentation/Images/$SetReplaceTypeGraph.png" width="787.8">

It is a [`Graph`](https://reference.wolfram.com/language/ref/Graph.html) representation of a directed hypergraph with
types and properties as vertices and implementations of translations and properties as edges.

Vertex heads are either [`SetReplaceType`](SetReplaceType.md), [`SetReplaceProperty`](SetReplaceProperty.md) or
[`SetReplaceMethodImplementation`](SetReplaceMethodImplementation.md).
