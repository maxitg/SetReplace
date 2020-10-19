###### [Symbols and Functions](/README.md#symbols-and-functions) > [WolframModel and WolframModelEvolutionObject](../WolframModelAndWolframModelEvolutionObject.md) > [Properties](../WolframModelAndWolframModelEvolutionObject.md#properties) >

# Plots of States

Instead of explicitly calling [`WolframModelPlot`](../../WolframModelPlot.md), one can use short-hand properties **`"FinalStatePlot"`** and **`"StatesPlotsList"`**:

```wl
In[] := WolframModel[{{1, 2, 3}, {4, 5, 6}, {1, 4}} ->
  {{2, 7, 8}, {3, 9, 10}, {5, 11, 12}, {6, 13, 14}, {8, 12}, {11,
    10}, {13, 7}, {14, 9}},
 {{1, 1, 1}, {1, 1, 1}, {1, 1}, {1, 1}, {1, 1}}, 6, "FinalStatePlot"]
```

<img src="../../../Images/FinalStatePlot.png" width="478">

```wl
In[] := WolframModel[{{1, 2, 3}, {4, 5, 6}, {1, 4}} ->
  {{2, 7, 8}, {3, 9, 10}, {5, 11, 12}, {6, 13, 14}, {8, 12}, {11,
    10}, {13, 7}, {14, 9}},
 {{1, 1, 1}, {1, 1, 1}, {1, 1}, {1, 1}, {1, 1}}, 6, "StatesPlotsList"]
```

<img src="../../../Images/StatesListPlot.png" width="746">

These properties take the same options as [`WolframModelPlot`](../../WolframModelPlot.md) (but one has to specify them in a call to the evolution object, not `WolframModel`):

```wl
In[] := WolframModel[{{1, 2, 3}, {4, 5, 6}, {1, 4}} ->
   {{2, 7, 8}, {3, 9, 10}, {5, 11, 12}, {6, 13, 14}, {8, 12}, {11,
     10}, {13, 7}, {14, 9}},
  {{1, 1, 1}, {1, 1, 1}, {1, 1}, {1, 1}, {1, 1}}, 3]["FinalStatePlot",
  VertexLabels -> Automatic]
```

<img src="../../../Images/FinalStatePlotWithVertexLabels.png" width="478">
