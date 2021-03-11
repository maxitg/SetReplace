###### [Symbols and Functions](/README.md#symbols-and-functions) > [Type System](README.md)

# $SetReplaceTypeGraph

**`$SetReplaceTypeGraph`** gives the [`Graph`](https://reference.wolfram.com/language/ref/Graph.html) showing
[types]($SetReplaceTypes.md) and [properties]($SetReplaceProperties.md) defined in *SetReplace* (including internal
ones) and possible computation paths between them:

```wl
In[] := $SetReplaceTypeGraph
```

<img src="/Documentation/Images/$SetReplaceTypeGraph.png" width="478.2">

It is a [`Graph`](https://reference.wolfram.com/language/ref/Graph.html) representation of a directed hypergraph with
types and properties as vertices and implementations of translations and properties as edges.

All vertices have the form `kind[name]`, where `kind` can be either [`SetReplaceType`](SetReplaceType.md),
[`SetReplaceProperty`](SetReplaceProperty.md) or [`SetReplaceMethodImplementation`](SetReplaceMethodImplementation.md),
and `name` is either a type specification or a symbol.
