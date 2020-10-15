#### Events

**`"AllEventsList"`** (aka `"EventsList"`) and **`"GenerationEventsList"`** both return all replacement events throughout the evolution. The only difference is how the events are arranged. `"AllEventsList"` returns the flat list of all events, whereas `"GenerationEventsList"` splits them into sublists for each generation:

```wl
In[] := WolframModel[{{1, 2}} -> {{3, 4}, {3, 1}, {4, 1}, {2, 4}},
 {{1, 1}}, 2, "AllEventsList"]
Out[] = {{1, {1} -> {2, 3, 4, 5}}, {1, {2} -> {6, 7, 8, 9}},
 {1, {3} -> {10, 11, 12, 13}}, {1, {4} -> {14, 15, 16, 17}},
 {1, {5} -> {18, 19, 20, 21}}}
```

```wl
In[] := WolframModel[{{1, 2}} -> {{3, 4}, {3, 1}, {4, 1}, {2, 4}},
 {{1, 1}}, 2, "GenerationEventsList"]
Out[] = {{{1, {1} -> {2, 3, 4, 5}}},
 {{1, {2} -> {6, 7, 8, 9}}, {1, {3} -> {10, 11, 12, 13}},
  {1, {4} -> {14, 15, 16, 17}}, {1, {5} -> {18, 19, 20, 21}}}}
```

The format for the events is

```wl
{ruleIndex, {inputEdgeIndices} -> {outputEdgeIndices}}
```

where the edge indices refer to expressions from [`"AllEventsEdgesList"`](AllEdgesThroughoutEvolution.md).
