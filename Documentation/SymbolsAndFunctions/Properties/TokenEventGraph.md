###### [Symbols and Functions](/README.md#symbols-and-functions) > Properties

# TokenEventGraph

**`TokenEventGraph`** is a [`Graph`](TODO) demostrating causal relationships between [tokens](TODO) and [events](TODO).

Fundamentally, a token-event graph is a [directed hypergraph](TODO) in which vertices correspond to tokens and edges to
events. The inputs and outputs of the edges correspond to the inputs and outputs of the corresponding rule.

As a simple example, consider a multiset substitution system that adds two numbers at each event:

```wl
MultisetSubstitutionSystem[{a_, b_} :> a + b]
```

If we start from an initial multiset `{3, 8, 8, 8, 2, 10, 0, 9, 7}`, we can get a token-event graph that quite clearly
describes what's going on:

```wl
In[] := TokenEventGraph[VertexLabels -> "ExpressionContents"] @
  GenerateSingleHistory[MultisetSubstitutionSystem[{a_, b_} :> a + b], "RuleOrdering"] @
    {3, 8, 8, 8, 2, 10, 0, 9, 7}
```

<img src="../../Images/ArithmeticModelExpressionsEventsGraph.png" width="478">

Notice that every event (orange vertex here) corresponds to an addition of two numbers, yielding to the final result of
`55` at the very bottom. In fact, we can draw lines through that graph to obtain the intermediate states (depending on
the slope of the lines, the states would be different corresponding to different event orderings). Pay attention to
intersections of the slices with edges as well, as they correspond to unused expressions from previous generations that
remain in the state:

<img src="../../Images/FoliatedExpressionsEventsGraph.png" width="478">

In the graphs above, each token has exactly one input and one output, which is always the case in single
[histories](TODO). However, we can also construct token-event graphs for [multihistories](TODO).

Here is an example where we allow upto two events to use each of the tokens:

```wl
In[] := TokenEventGraph[VertexLabels -> "ExpressionContents"] @
  GenerateMultihistory[
      MultisetSubstitutionSystem[{a_, b_} :> a + b], <|"MaxDestroyerEvents" -> 2|>, All, "RuleOrdering"] @
    {3, 8, 8, 8, 2, 10, 0, 9, 7}
```

<!-- TODO: Show past+future lightcones on mouseover -->
