###### [Symbols and Functions](/README.md#symbols-and-functions) > [WolframModel and WolframModelEvolutionObject](../WolframModelAndWolframModelEvolutionObject.md) > [Properties](../WolframModelAndWolframModelEvolutionObject.md#properties) >

# States

These are the properties used to extract states at a particular moment in the evolution. They always return lists, but
in the examples below, we plot them for clarity.

**`"FinalState"`** (aka -1) yields the state obtained after all replacements of the evolution have been made:

```wl
In[] := HypergraphPlot @ WolframModel[{{1, 2, 3}, {4, 5, 6}, {1, 4}} ->
   {{2, 7, 8}, {3, 9, 10}, {5, 11, 12}, {6, 13, 14}, {8, 12}, {11,
     10}, {13, 7}, {14, 9}},
  {{1, 1, 1}, {1, 1, 1}, {1, 1}, {1, 1}, {1, 1}}, 6, "FinalState"]
```

<img src="/Documentation/Images/FinalStatePlot.png"
     width="478"
     alt="Out[] = Graphics[...
       320 hyperedges form a roughly symmetric mesh with large openings on the left and right and smaller openings in
       the center
     ...]">

**`"StatesList"`** yields the list of states at each generation:

```wl
In[] := HypergraphPlot /@ WolframModel[{{1, 2, 3}, {4, 5, 6}, {1, 4}} ->
   {{2, 7, 8}, {3, 9, 10}, {5, 11, 12}, {6, 13, 14}, {8, 12}, {11,
     10}, {13, 7}, {14, 9}},
  {{1, 1, 1}, {1, 1, 1}, {1, 1}, {1, 1}, {1, 1}}, 6, "StatesList"]
```

<img src="/Documentation/Images/StatesListPlot.png"
     width="746"
     alt="Out[] = {
       Graphics[... generation 0, five hyperedges at one vertex ...],
       <<5>>,
       Graphics[... generation 6, a symmetric mesh of 320 hyperedges, seven states including the initial state ...]
     }">

This is identical to using the **`"Generation"`** property mapped over all generations:

```wl
In[] := HypergraphPlot /@ (WolframModel[{{1, 2, 3}, {4, 5, 6}, {1, 4}} ->
       {{2, 7, 8}, {3, 9, 10}, {5, 11, 12}, {6, 13, 14}, {8, 12}, {11,
          10}, {13, 7}, {14, 9}},
      {{1, 1, 1}, {1, 1, 1}, {1, 1}, {1, 1}, {1, 1}}, 6][
     "Generation", #] &) /@ Range[0, 6]
```

<img src="/Documentation/Images/StatesListPlot.png"
     width="746"
     alt="Out[] = {
       Graphics[... generation 0, five hyperedges at one vertex ...],
       <<5>>,
       Graphics[... generation 6, a symmetric mesh of 320 hyperedges, seven states including the initial state ...]
     }">

In fact, the `"Generation"` property can be omitted and the index of the generation can be used directly:

```wl
In[] := HypergraphPlot /@ WolframModel[{{1, 2, 3}, {4, 5, 6}, {1, 4}} ->
    {{2, 7, 8}, {3, 9, 10}, {5, 11, 12}, {6, 13, 14}, {8, 12}, {11,
      10}, {13, 7}, {14, 9}},
   {{1, 1, 1}, {1, 1, 1}, {1, 1}, {1, 1}, {1, 1}}, 6] /@ Range[0, 6]
```

<img src="/Documentation/Images/StatesListPlot.png"
     width="746"
     alt="Out[] = {
       Graphics[... generation 0, five hyperedges at one vertex ...],
       <<5>>,
       Graphics[... generation 6, a symmetric mesh of 320 hyperedges, seven states including the initial state ...]
     }">

`"StatesList"` shows a compressed version of the evolution. To see how the state changes with each applied replacement,
use **`"AllEventsStatesList"`**:

```wl
In[] := HypergraphPlot /@ WolframModel[{{1, 2, 3}, {4, 5, 6}, {1, 4}} ->
   {{2, 7, 8}, {3, 9, 10}, {5, 11, 12}, {6, 13, 14}, {8, 12}, {11,
     10}, {13, 7}, {14, 9}},
  {{1, 1, 1}, {1, 1, 1}, {1, 1}, {1, 1}, {1, 1}}, 3,
  "AllEventsStatesList"]
```

<img src="/Documentation/Images/AllEventsStatesListPlot.png"
     width="746"
     alt="Out[] = {
       Graphics[... initial state with five hyperedges at one vertex ...],
       <<6>>,
       Graphics[... state after event 7 with 40 hyperedges. Each successive plot shows one replacement ...]
     }">

Finally, to see a state after a specific event, use **`"StateAfterEvent"`** (aka `"SetAfterEvent"`):

```wl
In[] := HypergraphPlot @ WolframModel[{{1, 2, 3}, {4, 5, 6}, {1, 4}} ->
    {{2, 7, 8}, {3, 9, 10}, {5, 11, 12}, {6, 13, 14}, {8, 12}, {11,
      10}, {13, 7}, {14, 9}},
   {{1, 1, 1}, {1, 1, 1}, {1, 1}, {1, 1}, {1, 1}}, 6][
  "StateAfterEvent", 42]
```

<img src="/Documentation/Images/StateAfterEventPlot.png"
     width="478"
     alt="Out[] = Graphics[...
       215 hyperedges after event 42 form an uneven mesh, with larger openings on one side than in the
       complete-generation plots
     ...]">

`"StateAfterEvent"` is equivalent to taking a corresponding part in `"AllEventsStatesList"`, but it is much faster to
compute than the entire list.
