#### Creator and Destroyer Events

An event is said to *destroy* the edges in its input, and *create* the edges in its output. Creator and destroyer events for each edge can be obtained with **`"EdgeCreatorEventIndices"`** (aka `"CreatorEvents"`) and **`"EdgeDestroyerEventsIndices"`** properties.

As an example, for a simple rule that splits each edge in two, one can see that edges are created in pairs:

```wl
In[] := WolframModel[{{1, 2}} -> {{1, 3}, {3, 2}},
 {{1, 1}}, 4, "EdgeCreatorEventIndices"]
Out[] = {0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10, 10, 11,
   11, 12, 12, 13, 13, 14, 14, 15, 15}
```

and destroyed one-by-one:

```wl
In[] := WolframModel[{{1, 2}} -> {{1, 3}, {3, 2}},
 {{1, 1}}, 4, "EdgeDestroyerEventsIndices"]
Out[] = {{1}, {2}, {3}, {4}, {5}, {6}, {7}, {8}, {9}, {10}, {11}, {12},
   {13}, {14}, {15}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {},
   {}, {}, {}, {}}
```

Here 0 refers to the initial state. Note the format is different for creator and destroyer events. That is because each edge has a unique creator event, but can have multiple destroyer events in [multiway systems](../Options/EventSelectionFunction.md).

There is another property, **`"EdgeDestroyerEventIndices"`** (aka `"DestroyerEvents"`), left for compatibility reasons, which has the same format as **`"EdgeCreatorEventIndices"`**. However, it does not work for [multiway systems](../Options/EventSelectionFunction).

```wl
In[] := WolframModel[{{1, 2}} -> {{1, 3}, {3, 2}},
 {{1, 1}}, 4, "EdgeDestroyerEventIndices"]
Out[] = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, Infinity,
  Infinity, Infinity, Infinity, Infinity, Infinity, Infinity,
  Infinity, Infinity, Infinity, Infinity, Infinity, Infinity,
  Infinity, Infinity, Infinity}
```
