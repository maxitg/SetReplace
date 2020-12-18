###### [Symbols and Functions](/README.md#symbols-and-functions) > [WolframModel and WolframModelEvolutionObject](../WolframModelAndWolframModelEvolutionObject.md) > [Properties](../WolframModelAndWolframModelEvolutionObject.md#properties) >

# Expression Separations

Expressions can be related in different ways to one another depending on the causal structure of the expressions-events
graph.

There are three fundamental cases, the separation between two expressions can be:

* spacelike -- the expressions were produced (directly or indirectly) by a single event;
* branchlike -- the expressions were produced (directly or indirectly) by multiple events that matched the same
  expression;
* timelike -- the expressions are causally related, one produced or was produced by another.

The expressions `{2, 3}` and `{3, 4}` here are spacelike, branchlike and timelike separated respectively:

```wl
In[] := Framed[WolframModel[<|"PatternRules" -> #|>, {{1, 2}}, Infinity,
     "EventSelectionFunction" -> None]["ExpressionsEventsGraph",
    VertexLabels -> Placed[Automatic, After],
    GraphHighlight -> Thread[{"Expression", {2, 3}}]],
   FrameStyle -> LightGray] & /@ {{{1, 2}} -> {{2, 3}, {3, 4}},
  {{{1, 2}} -> {{2, 3}}, {{1, 2}} -> {{3, 4}}},
  {{{1, 2}} -> {{2, 3}}, {{2, 3}} -> {{3, 4}}}}
```

<img src="/Documentation/Images/SeparationComparison.png" width="512">

One might be tempted to assume that spacelike separated expressions can always be 'assembled' to produce a possible
history for a singleway system. For match-all evolution, however, this is not the case. Match-all rules can match two
branchlike separated expressions, something that is never possible for singleway systems. If such events produce
spacelike separated results, then we will obtain spacelike separated expressions that can be assembled into global
states which *do not* correspond to any singleway evolution state. See expressions `{4, 5}` and `{5, 6}` in the
following picture:

```wl
In[] := WolframModel[<|
   "PatternRules" -> {{{1, 2}} -> {{2, 3}}, {{1, 2}} -> {{3, 4}},
     {{2, 3}, {3, 4}} -> {{4, 5}, {5, 6}}}|>, {{1, 2}}, Infinity,
  "EventSelectionFunction" -> None]["ExpressionsEventsGraph",
 VertexLabels -> Placed[Automatic, After]]
```

<img src="/Documentation/Images/MatchAllQuantumSpacelikeMatching.png" width="351">

Further, branchlike separation takes precedence over spacelike separation, and timelike separation takes precedence over
both. As such, expressions `{v, f, 1}` and `{v, f, 2}` here are branchlike separated because one of their common
ancestors is an expression even though the other one is an event:

```wl
In[] := WolframModel[<|"PatternRules" -> {{{v, i}} -> {{v, 1}, {v, 2}},
     {{v, 1}} -> {{v, 1, 1}, {v, 1, 2}},
     {{v, 1, 1}, {v, 2}} -> {{v, f, 1}},
     {{v, 1, 2}, {v, 2}} -> {{v, f, 2}}}|>, {{v, i}}, Infinity,
  "EventSelectionFunction" -> None]["ExpressionsEventsGraph",
 VertexLabels -> Placed[Automatic, After]]
```

<img src="/Documentation/Images/MatchAllSpacelikeBranchlikeMixed.png" width="352">

Specifically, the general algorithm for computing the separation between two expressions `A` and `B` in an
expressions-events graph is:

1. Compute the past causal cones of both `A` and `B`.
2. Compute the intersection between the causal cones.
3. Take all vertices with out-degree zero (the future boundary of the intersection).
4. If the boundary contains either `A` and `B`, they are timelike separated.
5. If any vertices on the boundary are expression-vertices, they are branchlike separated.
6. Otherwise, if all vertices on the boundary are event-vertices, they are spacelike separated.

One can compute that separation using **`"ExpressionsSeparation"`** property. It takes two arguments, which are the
indices of expressions from [`"AllEventsEdgesList"`](AllEdgesThroughoutEvolution.md):

```wl
In[] := WolframModel[<|"PatternRules" -> {{{v, i}} -> {{v, 1}, {v, 2}},
     {{v, 1}} -> {{v, 1, 1}, {v, 1, 2}},
     {{v, 1, 1}, {v, 2}} -> {{v, f, 1}},
     {{v, 1, 2}, {v, 2}} -> {{v, f, 2}}}|>, {{v, i}}, Infinity,
  "EventSelectionFunction" -> None]["ExpressionsSeparation", 6, 7]
Out[] = "Branchlike"
```

It is also possible to use negative indices, in which case expressions are counted backwards:

```wl
In[] := WolframModel[<|
   "PatternRules" -> {{{1, 2}} -> {{2, 3}}, {{1, 2}} -> {{3, 4}},
     {{2, 3}, {3, 4}} -> {{4, 5}, {5, 6}}}|>, {{1, 2}}, Infinity,
  "EventSelectionFunction" -> None]["ExpressionsSeparation", -1, -2]
Out[] = "Spacelike"
```
