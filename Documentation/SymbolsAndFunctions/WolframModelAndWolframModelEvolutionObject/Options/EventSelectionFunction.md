###### [Symbols and Functions](/README.md#symbols-and-functions) > [WolframModel and WolframModelEvolutionObject](../WolframModelAndWolframModelEvolutionObject.md) > [Options](../WolframModelAndWolframModelEvolutionObject.md#options) >

# "EventSelectionFunction"

**`EventSelectionFunction`** allows one to evaluate multiway systems.
Currently, three values are supported, `"GlobalSpacelike"`, `"MultiwaySpacelike"` and `None`.

`"GlobalSpacelike"` is the default, and is the single-way evolution.
"Spacelike" refers to relationships between expressions, and "global" means each expression is only used once in an
event, so there is always a global state in which all expressions are pairwise spacelike.
Note that one can obtain different evolutions in this case depending on [the ordering function](EventOrderingFunction.md).

`"MultiwaySpacelike"` evolution is the multiway version of `"GlobalSpacelike"`.
Essentially, it evolves it for all possible ordering functions and combines the result to a single evolution object.
It achieves that by not disabling expressions after they were used.
Only spacelike separated expressions are matched for any given event, however, so every individual expression of the
`"MultiwaySpacelike"` evolution can be obtained with a particular choice of the event ordering function.
(It does not imply that it can actually be done in *SetReplace* as only few ordering functions are implemented at this
time.)

For example, consider a system

```wl
In[] := WolframModel[{{1, 2}, {2, 3}} -> {{1, 3}}, {{1, 2}, {2, 3}, {2, 4}},
  Infinity]["ExpressionsEventsGraph", VertexLabels -> Automatic]
```

<img src="/Documentation/Images/GlobalSpacelikeEvolution.png" width="419">

In this example we used the default `"GlobalSpacelike"` selection function, and the evolution terminated after a single
event, because the expression `{1, 2}` was used, and it could not be reused to be matched with `{2, 4}`.
However, let's look at what `"EventSelectionFunction" -> "MultiwaySpacelike"` will do:

```wl
In[] := WolframModel[{{1, 2}, {2, 3}} -> {{1, 3}}, {{1, 2}, {2, 3}, {2, 4}},
  Infinity,
  "EventSelectionFunction" -> "MultiwaySpacelike"]["ExpressionsEventsGraph",
 VertexLabels -> Automatic]
```

<img src="/Documentation/Images/SpacelikeMatching.png" width="478">

In this case, the expression `{1, 2}` was matched twice, which we can also see by looking at its list of destroyer
events:

```wl
In[] := WolframModel[{{1, 2}, {2, 3}} -> {{1, 3}},
 {{1, 2}, {2, 3}, {2, 4}}, Infinity, "EdgeDestroyerEventsIndices",
 "EventSelectionFunction" -> "MultiwaySpacelike"]
Out[] = {{1, 2}, {1}, {2}, {}, {}}
```

In the previous example, we matched the same expression twice, but every match's inputs were spacelike with each other.
The `"MultiwaySpacelike"` selection function will not match branchlike or timelike separated expressions, like
`{1, 2, 3}` and `{1, 2, 4}` here:

```wl
In[] := WolframModel[{{{1, 2}, {2, 3}} -> {{1, 2, 3}},
   {{1, 2, 3}, {1, 2, 4}} -> {{1, 2, 3, 4}}},
  {{1, 2}, {2, 3}, {2, 4}}, Infinity,
  "EventSelectionFunction" -> "MultiwaySpacelike"]["ExpressionsEventsGraph",
 VertexLabels -> Placed[Automatic, After]]
```

<img src="/Documentation/Images/NoBranchlikeMatching.png" width="478">

However, `"EventSelectionFunction" -> None` also matches expressions that are branchlike and timelike.
So, further evolution will be generated in the previous example:

```wl
In[] := WolframModel[{{{1, 2}, {2, 3}} -> {{1, 2, 3}},
   {{1, 2, 3}, {1, 2, 4}} -> {{1, 2, 3, 4}}},
  {{1, 2}, {2, 3}, {2, 4}}, Infinity,
  "EventSelectionFunction" -> None]["ExpressionsEventsGraph",
 VertexLabels -> Placed[Automatic, After]]
```

<img src="/Documentation/Images/BranchlikeMatching.png" width="373">

Similarly, it matches timelike expressions `{1, 2}` and `{1, 2, 3}` below:

```wl
In[] := WolframModel[{{{1, 2}, {2, 3}} -> {{1, 2, 3}},
   {{1, 2}, {1, 2, 3}} -> {{1, 2, 3, 4}}},
  {{1, 2}, {2, 3}}, Infinity,
  "EventSelectionFunction" -> None]["ExpressionsEventsGraph",
 VertexLabels -> Placed[Automatic, After]]
```

<img src="/Documentation/Images/TimelikeMatching.png" width="247">

Because of this branchlike and timelike matching, branches in `"EventSelectionFunction" -> None` evolution are not
separated but can "interfere" with one another.
