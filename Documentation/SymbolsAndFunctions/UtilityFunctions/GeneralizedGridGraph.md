###### [Symbols and Functions](/README.md#symbols-and-functions) > Utility Functions >

# GeneralizedGridGraph

**`GeneralizedGridGraph`** is similar to [`GridGraph`](https://reference.wolfram.com/language/ref/GridGraph.html), but
it allows for additional specifiers in each direction of the grid:

```wl
In[] := GeneralizedGridGraph[{5 -> "Directed", 5 -> "Circular"}]
```

<img src="/Documentation/Images/GridGraph.png"
     width="478"
     alt="Out[] = Graph[... five undirected pentagonal rings of five vertices. Arrows point from each ring to the
       next along the cylinder ...]">

Possible specifiers are `"Directed"` and `"Circular"`, and they can be combined:

```wl
In[] := GeneralizedGridGraph[{3 -> {"Directed", "Circular"}, 6}]
```

<img src="/Documentation/Images/DirectedCircularGridGraph.png"
     width="478"
     alt="Out[] = Graph[... six directed triangles connected in a row. Arrows cycle around each triangle, and
       undirected edges join corresponding vertices of adjacent triangles ...]">

The same options as [`GridGraph`](https://reference.wolfram.com/language/ref/GridGraph.html) are supported. In
addition `"VertexNamingFunction" -> "Coordinates"` names vertices according to their position in a grid:

```wl
In[] := GeneralizedGridGraph[{4, 5, 2},
 "VertexNamingFunction" -> "Coordinates", VertexLabels -> Automatic]
```

<img src="/Documentation/Images/GridGraphWithCoordinateNamedVertices.png"
     width="478"
     alt="Out[] = Graph[... two 4-by-5 grids joined at corresponding vertices. Each label is a coordinate triple
       such as {1, 1, 1} or {1, 1, 2} ...]">

Finally, it's possible to use different `EdgeStyle` in different directions by specifying it as a list:

```wl
In[] := GeneralizedGridGraph[{4 -> "Directed", 5, 2},
 "VertexNamingFunction" -> "Coordinates",
 EdgeStyle -> Darker /@ {Red, Green, Blue}]
```

<img src="/Documentation/Images/GridGraphWithDifferentEdgeStyles.png"
     width="478"
     alt="Out[] = Graph[... red arrows follow the first coordinate, green edges follow the second, and blue edges
       join the two layers along the third ...]">
