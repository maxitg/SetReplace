###### [Symbols and Functions](/README.md#symbols-and-functions) > Utility Functions >

# SetReplaceStyleData

**`SetReplaceStyleData`** allows one to lookup styles used in various *SetReplace* functions and properties such as
[`HypergraphPlot`](../HypergraphPlot.md)
and [`"CausalGraph"`](../WolframModelAndWolframModelEvolutionObject/Properties/CausalGraphs.md).

For example, here is the default style used to draw polygons in [`HypergraphPlot`](../HypergraphPlot.md):

```wl
In[] := SetReplaceStyleData["SpatialGraph", "EdgePolygonStyle"]
```

<img src="/Documentation/Images/SpatialGraphEdgePolygonStyle.png"
     width="437"
     alt="Out[] = Directive[Hue[0.63, 0.66, 0.81], Opacity[0.1], EdgeForm[None]]">

The full specification is `SetReplaceStyleData[theme, plot type, style element]`, however either the last or
the last two elements can be omitted to obtain a
full [`Association`](https://reference.wolfram.com/language/ref/Association.html) of styles. The `theme` argument can be
omitted to get the result for the default plot theme (only `"Light"` theme is supported at the moment). Here are all
styles used in [`"CausalGraph"`](../WolframModelAndWolframModelEvolutionObject/Properties/CausalGraphs.md) for example:

```wl
In[] := SetReplaceStyleData["CausalGraph"]
```

<img src="/Documentation/Images/CausalGraphStyles.png"
     width="747"
     alt='<|
       "Background" -> None, "EdgeStyle" -> Hue[0, 1, 0.56],
       "FinalVertexStyle" -> Directive[GrayLevel[1], EdgeForm[{Hue[0.11, 1, 0.97], Opacity[1]}]],
       ...,
       "VertexStyle" -> Directive[Hue[0.11, 1, 0.97], EdgeForm[{Hue[0.11, 1, 0.97], Opacity[1]}]]
     |>'>

This function is useful if one needs to produce "fake" example plots using styles consistent with *SetReplace*.

For graphs composed of only a single type of vertices and edges, there is a short-hand syntax. One can get the list of
all options that needs to be passed using an `"Options"` property:

```wl
In[] := SetReplaceStyleData["SpatialGraph3D", "Options"]
```

<img src="/Documentation/Images/SpatialGraph3DOptions.png"
     width="625"
     alt="{
       VertexStyle -> Directive[Hue[0.65, 0.64, 0.68], Specularity[Hue[0.71, 0.6, 0.64], 10]],
       EdgeStyle -> Hue[0.61, 0.3, 0.85]
     }">

Alternatively, one can use the `"Function"` property, which would give a function that takes a graph and produces a
correctly styled graph:

```wl
In[] := SetReplaceStyleData["SpatialGraph3D", "Function"][
 Graph3D[{1 -> 2, 2 -> 3, 3 -> 1, 3 -> 4, 4 -> 1}]]
```

<img src="/Documentation/Images/FakeStyledSpatialGraph3D.png"
     width="478"
     alt="Out[] = Graph3D[
       ...,
       VertexStyle -> Directive[Hue[0.65, 0.64, 0.68], Specularity[Hue[0.71, 0.6, 0.64], 10]],
       EdgeStyle -> Hue[0.61, 0.3, 0.85]
     ]">
