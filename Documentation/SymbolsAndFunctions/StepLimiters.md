### Step Limiters

The standard numeric argument to `WolframModel` specifies the number of generations:

```wl
In[] := WolframModel[{{1, 2, 3}, {4, 5, 6}, {2, 5}, {5, 2}} ->
  {{7, 1, 8}, {9, 3, 10}, {11, 4, 12}, {13, 6, 14}, {7, 13}, {13,
    7}, {8, 10}, {10, 8}, {9, 11}, {11, 9}, {12, 14}, {14, 12}},
 {{1, 2, 3}, {4, 5, 6}, {1, 4}, {4, 1}, {2, 5}, {5, 2}, {3, 6}, {6,
   3}}, 6, "FinalStatePlot"]
```

<img src="DocsImages/MaxGenerationsFinalStatePlot.png" width="478">

Alternatively, an [`Association`](https://reference.wolfram.com/language/ref/Association.html) can be used to specify a more elaborate limiting condition:

```wl
In[] := WolframModel[{{1, 2, 3}, {4, 5, 6}, {2, 5}, {5, 2}} ->
  {{7, 1, 8}, {9, 3, 10}, {11, 4, 12}, {13, 6, 14}, {7, 13}, {13,
    7}, {8, 10}, {10, 8}, {9, 11}, {11, 9}, {12, 14}, {14, 12}},
 {{1, 2, 3}, {4, 5, 6}, {1, 4}, {4, 1}, {2, 5}, {5, 2}, {3, 6}, {6,
   3}},
 <|"MaxVertices" -> 300, "MaxEvents" -> 200|>, "FinalStatePlot"]
```

<img src="DocsImages/MaxVerticesFinalStatePlot.png" width="478">

Note that the final state here is "less symmetric" because its last generation is incomplete (more on that [later](#hypergraphautomorphismgroup)). Such incomplete generations can be automatically trimmed by setting [`"IncludePartialGenerations" -> False`](Properties.md#includepartialgenerations).

One can also see the presence of an incomplete generation by looking at the evolution object (note `5...6` which means 5 generations are complete, and 1 is not). Expanding the object's information, one can also see that in this particular case the evolution was terminated because `"MaxVertices"` (not `"MaxEvents"`) condition was reached:

```wl
In[] := WolframModel[{{1, 2, 3}, {4, 5, 6}, {2, 5}, {5, 2}} ->
  {{7, 1, 8}, {9, 3, 10}, {11, 4, 12}, {13, 6, 14}, {7, 13}, {13,
    7}, {8, 10}, {10, 8}, {9, 11}, {11, 9}, {12, 14}, {14, 12}},
 {{1, 2, 3}, {4, 5, 6}, {1, 4}, {4, 1}, {2, 5}, {5, 2}, {3, 6}, {6,
   3}},
 <|"MaxVertices" -> 300, "MaxEvents" -> 200|>]
```

<img src="DocsImages/MaxVerticesEvolutionObject.png" width="753">

All possible keys in that association are:

* `"MaxEvents"`: limit the number of individual replacements (in the [`SetReplace`](SetReplace*.md#setreplace) function meaning).
* `"MaxGenerations"`: limit the number of generations (steps in [`SetReplaceAll`](SetReplace*.md#setreplace) meaning), same as specifying steps directly as a number in `WolframModel`.
* `"MaxVertices"`: limit the number of vertices in the *final* state only (the total count throughout evolution might be larger). This limit stops evolution if the next event, if applied, would put the state over the limit. Note once such an event is encountered, the evolution stops immediately even if other matches exist that would not put the vertex count over the limit.
* `"MaxVertexDegree"`: limit the number of final state edges in which any particular vertex is involved. Works in a similar way to `"MaxVertices"`.
* `"MaxEdges"`: limit the number of edges (set elements) in the final state. Works similarly to `"MaxVertices"`.

Any combination of these can be used, in which case the earliest triggered condition stops the evolution.

Note also that `"MaxGenerations"` works differently from the other limiters, as the matching algorithm would not even attempt to match edges with generations over the limit. Therefore unlike, i.e., `"MaxVertices"`, which would terminate the evolution immediately once the limit-violating event is attempted, `"MaxGenerations"` would keep "filling in" events for as long as possible until no further matches within allowed generations are possible.

It is also possible to set the step count to `Automatic`, in which case `WolframModel` tries to automatically pick a number of steps that showcases the evolution without taking too long. It stops the evolution sooner if the state grows quickly:

```wl
In[] := WolframModel[{{1, 2, 3}, {2, 4, 5}} -> {{5, 6, 1}, {6, 4, 2}, {4, 5,
    3}},
 {{1, 2, 3}, {2, 4, 5}, {4, 6, 7}}, Automatic]
```

<img src="DocsImages/AutomaticStepsGrowing.png" width="491">

But evolves the rule much longer if it does not grow:

```wl
In[] := WolframModel[<|"PatternRules" -> {{a_, b_}} :> {{a + b, a - b}}|>,
 {{1, 1}}, Automatic]
```

<img src="DocsImages/AutomaticStepsNotGrowing.png" width="565">

Currently, it's equivalent to `<|"MaxEvents" -> 5000, "MaxVertices" -> 200|>`, setting `TimeConstraint -> 5` (it still returns values for all properties even if terminated due to time constraint), and `"IncludePartialGenerations" -> False`, but it may be adjusted in future updates.