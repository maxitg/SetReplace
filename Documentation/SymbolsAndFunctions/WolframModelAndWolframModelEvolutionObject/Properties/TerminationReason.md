###### [Symbols and Functions](/README.md#symbols-and-functions) > [WolframModel and WolframModelEvolutionObject](../WolframModelAndWolframModelEvolutionObject.md) > [Properties](../WolframModelAndWolframModelEvolutionObject.md#properties) >

# Termination Reason

**`"TerminationReason"`** shows why the evaluation of the model was stopped. It's particularly useful if multiple [stopping conditions](../WolframModelAndWolframModelEvolutionObject.md#wolframmodel-step-limiters) are specified.

All possible values are:

* `"MaxEvents"`, `"MaxGenerations"`, `"MaxVertices"`, `"MaxVertexDegree"` and `"MaxEdges"` correspond directly to [step limiters](../WolframModelAndWolframModelEvolutionObject.md#wolframmodel-step-limiters).
* `"FixedPoint"` means there were no more matches possible to rule inputs.
* `"TimeConstraint"` could occur if a [`"TimeConstraint"`](../Options/TimeConstraint.md) option is used.
* `"Aborted"` would occur if the evaluation was manually interrupted (i.e., by pressing ⌘. on a Mac). In that case, a partially computed evolution object is returned.

As an example, in our arithmetic model a `"FixedPoint"` is reached (which is why we can use [`Infinity`](https://reference.wolfram.com/language/ref/Infinity.html) as the number of steps):

```wl
In[] := WolframModel[<|"PatternRules" -> {a_, b_} :> a + b|>,
  {3, 8, 8, 8, 2, 10, 0, 9, 7}, Infinity]["TerminationReason"]
Out[] = "FixedPoint"
```

And if we manually abort the evolution, we could get something like this:

```wl
In[] := WolframModel[{{1, 2, 3}, {4, 5, 6}, {1, 4}} ->
  {{2, 7, 8}, {5, 9, 10}, {6, 11, 12}, {13, 3, 14}, {8, 13}, {9,
    7}, {10, 12}, {14, 11}},
 {{1, 1, 1}, {1, 1, 1}, {1, 1}, {1, 1}, {1, 1}}, 100]
⌘.
```

<img src="/Documentation/Images/AbortedEvolutionObject.png" width="760">
