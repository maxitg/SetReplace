###### [Symbols and Functions](/README.md#symbols-and-functions) > [WolframModel and WolframModelEvolutionObject](../WolframModelAndWolframModelEvolutionObject.md) > [Properties](../WolframModelAndWolframModelEvolutionObject.md#properties) >

# Plots of Events

The plotting function corresponding to [`"AllEventsStatesList"`](States.md) is more interesting than the other
ones. **`"EventsStatesPlotsList"`** plots not only the states, but also the events that produced them:

```wl
In[] := WolframModel[{{1, 2, 3}, {4, 5, 6}, {1, 4}} ->
  {{2, 7, 8}, {3, 9, 10}, {5, 11, 12}, {6, 13, 14}, {8, 12}, {11,
    10}, {13, 7}, {14, 9}},
 {{1, 1, 1}, {1, 1, 1}, {1, 1}, {1, 1}, {1, 1}},
 3, "EventsStatesPlotsList"]
```

<img src="/Documentation/Images/EventsStatesPlotsList.png" width="746">

Here the dotted gray edges are the ones about to be deleted, whereas the red ones have just been created.
