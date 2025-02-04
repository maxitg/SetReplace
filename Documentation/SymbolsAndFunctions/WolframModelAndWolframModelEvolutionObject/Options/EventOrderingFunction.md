###### [Symbols and Functions](/README.md#symbols-and-functions) > [WolframModel and WolframModelEvolutionObject](../WolframModelAndWolframModelEvolutionObject.md) > [Options](../WolframModelAndWolframModelEvolutionObject.md#options) >

# "EventOrderingFunction"

In many `WolframModel` systems multiple matches are possible at any given step. As an example, two possible replacements
are possible in the system below from the initial condition:

```wl
In[] := WolframModel[{{1, 2}} -> {{1, 3}, {3, 2}},
 {{1, 2}, {2, 2}}, <|"MaxEvents" -> 1|>, "EventsStatesPlotsList"]
```

<img src="/Documentation/Images/NonoverlappingEvolutionWithAutomaticOrdering.png"
     width="513"
     alt="Out[] = {... {{1, 2}, {2, 2}} -> {{2, 2}, {1, 3}, {3, 2}} ...}">

```wl
In[] := WolframModel[{{1, 2}} -> {{1, 3}, {3, 2}},
 {{1, 2}, {2, 2}}, <|"MaxEvents" -> 1|>, "EventsStatesPlotsList",
 "EventOrderingFunction" -> "NewestEdge"]
```

<img src="/Documentation/Images/NonoverlappingEvolutionWithNewestEdgeOrdering.png"
     width="513"
     alt="Out[] = {... {{1, 2}, {2, 2}} -> {{1, 2}, {2, 3}, {3, 2}} ...}">

In this particular so-called non-overlapping system, the order of replacements does not matter. Regardless of order, the
same final state (up to renaming of vertices) is produced for the same fixed number of generations. This will always be
the case if there is only a single edge on the left-hand side of the rule:

```wl
In[] := WolframModel[{{1, 2}} -> {{1, 3}, {1, 3}, {3, 2}},
   {{1, 2}, {2, 2}}, 3, "FinalStatePlot",
   "EventOrderingFunction" -> #] & /@ {Automatic, "Random"}
```

<img src="/Documentation/Images/NonoverlappingRandomEvolutionComparison.png"
     width="513"
     alt="Out[] = ... list of two isomorphic graphs with 54 edges ...">

For some systems, however, the order of replacements does matter, and non-equivalent final states would be produced for
different orders even if a fixed number of generations is requested:

```wl
In[] := WolframModel[{{1, 2}, {2, 3}} -> {{4, 2}, {4, 1}, {2, 1}, {3, 4}},
 {{1, 2}, {2, 3}, {3, 4}, {4, 1}}, 5, "FinalStatePlot"]
```

<img src="/Documentation/Images/OverlappingEvolutionAutomaticOrdering.png"
     width="478"
     alt="Out[] = ... a graph with 128 edges ...">

```wl
In[] := WolframModel[{{1, 2}, {2, 3}} -> {{4, 2}, {4, 1}, {2, 1}, {3, 4}},
 {{1, 2}, {2, 3}, {3, 4}, {4, 1}}, 5, "FinalStatePlot",
 "EventOrderingFunction" -> "RuleOrdering"]
```

<img src="/Documentation/Images/OverlappingEvolutionRuleOrderingOrdering.png"
     width="478"
     alt="Out[] = ... a graph with 96 edges ...">

In a case like that, it is important to be able to specify the desired evolution order, which is the purpose of
the **`"EventOrderingFunction"`** option. `"EventOrderingFunction"` is specified as a list of sorting criteria such as
the default `{"LeastRecentEdge", "RuleOrdering", "RuleIndex"}`. Note that most individual sorting criteria are
insufficient to distinguish between all available matches. If multiple matches remain after exhausting all sorting
criteria, one is chosen uniformly at random (which is why `{}` works as a shorthand for `"Random"`).

Possible sorting criteria are:

- `"OldestEdge"`: greedily select the edge closest to the beginning of the list (which would typically correspond to the
  oldest edge). Note, the edges within a single-event output are assumed oldest-to-newest left-to-right as written on
  the right-hand side of the rule. After this criterion, a fixed **_subset_** of edges is guaranteed to be chosen, but
  different orderings of that subset might be possible (which could allow for multiple non-equivalent matches).

- `"NewestEdge"`: similar to `"OldestEdge"` except edges are chosen from the end of the list rather than from the
  beginning.

- `"LeastRecentEdge"`: this is similar to `"OldestEdge"`, but instead of greedily choosing the oldest edges, it instead
  avoids choosing newest ones. The difference is best demonstrated in an example:

  ```wl
  In[] := WolframModel[{{x, y}, {y, z}} -> {},
     {{1, 2}, {a, b}, {b, c}, {2, 3}},
     <|"MaxEvents" -> 1|>, "AllEventsList",
     "EventOrderingFunction" -> #] & /@ {"OldestEdge",
    "LeastRecentEdge"}
  Out[] = {{{1, {1, 4} -> {}}}, {{1, {2, 3} -> {}}}}
  ```

  Note that in this example `"OldestEdge"` has selected the first and the last edge, whereas `"LeastRecentEdge"`, in an
  attempt to avoid the most "recent" last edge, has selected the second and the third ones. In this case, similarly
  to `"OldestEdge"`, a fixed set of edges is guaranteed to be chosen, but potentially in multiple orders.

- `"LeastOldEdge"`: similar to `"LeastRecentEdge"`, but avoids old edges instead of new ones.

  Note that counterintuitively `"OldestEdge"` sorting is not equivalent to the reverse of `"NewestEdge"` sorting, it is
  equivalent to the reverse of `"LeastOldEdge"`. Similarly, `"NewestEdge"` is the reverse of `"LeastRecentEdge"`.

- `"RuleOrdering"`: similarly to `"OldestEdge"` greedily chooses edges from the beginning of the list, however
  unlike `"OldestEdge"` which would pick the oldest edge with _any_ available matches, it chooses edges in the order the
  left-hand side of (any) rule is written. The difference is best demonstrated in an example:

  ```wl
  In[] := WolframModel[{{x, y}, {y, z}} -> {},
     {{b, c}, {1, 2}, {a, b}, {2, 3}},
     <|"MaxEvents" -> 1|>, "AllEventsList",
     "EventOrderingFunction" -> #] & /@ {"OldestEdge", "RuleOrdering"}
  Out[] = {{{1, {1, 3} -> {}}}, {{1, {2, 4} -> {}}}}
  ```

  Note how `"RuleOrdering"` has selected the second edge first because it matches the first rule input while the first
  edge does not.

  In this case, a specific ordered sequence of edges is guaranteed to be matched (including its permutation). However,
  multiple matches might still be possible if multiple rules exist which match that sequence.

- `"ReverseRuleOrdering"`: as the name suggests, this is just the reverse of `"RuleOrdering"`.

- `"RuleIndex"`: this simply means it attempts to match the first rule first, and only if no matches to the first rule
  are possible, it goes to the second rule, and so on.

- `"ReverseRuleIndex"`: similar to `"RuleIndex"`, but reversed as the name suggests.

- `"Random"`: selects a single match uniformly at random. It is possible to do that efficiently because the C++
  implementation of `WolframModel` (the only one that supports `"EventOrderingFunction"`) keeps track of all possible
  matches at any point during the evolution. `"Random"` is guaranteed to select a single match, so the remaining sorting
  criteria are ignored. It can also be omitted because the random event is always chosen if provided sorting criteria
  are insufficient. The seeding can be controlled
  with [`SeedRandom`](https://reference.wolfram.com/language/ref/SeedRandom.html). However, the result does depend on
  your platform (Mac/Linux/Windows) and the specific build (version) of _SetReplace_.

- `"Any"`: the chosen match is undefined. It can select any match, leading to nondeterministic and undefined evolution
  order. In some cases, it has better performance than "Random".

As a neat example, here is the output of all individual sorting criteria (default sorting criteria are appended to
disambiguate):

```wl
In[] := WolframModel[{{{1, 2}, {1, 3}, {1, 4}} -> {{5, 6}, {6, 7}, {7, 5}, {5,
         7}, {7, 6}, {6, 5}, {5, 2}, {6, 3}, {7, 4}, {2, 7}, {4, 5}},
     {{1, 2}, {1, 3}, {1, 4}, {1, 5}} -> {{2, 3}, {3, 4}}},
    {{1, 1}, {1, 1}, {1, 1}},
    <|"MaxEvents" -> 30|>,
    "EventOrderingFunction" -> {#, "LeastRecentEdge", "RuleOrdering",
      "RuleIndex"}]["FinalStatePlot",
   PlotLabel -> #] & /@
 {"OldestEdge", "LeastOldEdge",
  "LeastRecentEdge", "NewestEdge", "RuleOrdering",
  "ReverseRuleOrdering", "RuleIndex", "ReverseRuleIndex", "Random", "Any"}
```

<img src="/Documentation/Images/AllEventOrderingFunctionPlots.png"
     width="1209"
     alt="Out[] = {... 10 graphs with variable complexity and edge count, one of which disconnected ...}">
