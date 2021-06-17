# Generators

Generators are functions that create [`Multihistory`](/Documentation/Types/Multihistory/README.md) objects. They take
rules for a [computational system](/Documentation/Systems/README.md) and additional parameters specifying how to perform
the evaluation.

In *SetReplace*, we split the states of [computational systems](/Documentation/Systems/README.md) into components which
we call tokens. Rewrites (which we call events) replace some of these tokens with others. Crucially, *SetReplace* can
evaluate multiple branches of nondeterministic systems simultaneously. That is done by applying different events to the
same tokens and keeping events and tokens instead of states in
[`Multihistory`](/Documentation/Types/Multihistory/README.md) objects. We can reconstruct the states from that
information afterwards.

Most systems, however, cannot be evaluated completely. And there are multiple groups of parameters to control how to
perform a partial evaluation. One needs to decide [which events to include](EventSelectionParameters.md), in
[which order](EventOrderingFunctions.md), and [when to terminate the evaluation](StoppingConditionParameters.md).

For example, in a [`MultisetSubstitutionSystem`](/Documentation/Systems/MultisetSubstitutionSystem.md) we can generate
a single history (no nondeterministic branching):

```wl
In[] := #["ExpressionsEventsGraph", VertexLabels -> Placed[Automatic, After]] & @
  SetReplaceTypeConvert[{WolframModelEvolutionObject, 2}] @
    GenerateMultihistory[MultisetSubstitutionSystem[{a_, b_} /; a < b :> {a + b}],
                         "MaxDestroyerEvents" -> 1,
                         None,
                         EventOrderingFunctions[MultisetSubstitutionSystem],
                         {}] @ {1, 2, 3, 4}
```

<img src="/Documentation/Images/MultisetSubstitutionSystemExample.png" width="444.6">

or multiple histories. Note different events (orange) using the same tokens (light blue):

```wl
In[] := #["ExpressionsEventsGraph", VertexLabels -> Placed[Automatic, After]] & @
  SetReplaceTypeConvert[{WolframModelEvolutionObject, 2}] @
    GenerateMultihistory[MultisetSubstitutionSystem[{a_, b_} /; a < b :> {a + b}],
                         "MaxDestroyerEvents" -> 2,
                         None,
                         EventOrderingFunctions[MultisetSubstitutionSystem],
                         {}] @ {1, 2, 3, 4}
```

<img src="/Documentation/Images/MultisetSubstitutionSystemPartialMultihistory.png" width="478.2">

The same generators support multiple systems. In addition to
[`MultisetSubstitutionSystem`](/Documentation/Systems/MultisetSubstitutionSystem.md), other examples include
`HypergraphSubstitutionSystem`, `StringSubstitutionSystem`, etc. Many of these systems have shared evaluation
parameters.

[`GenerateMultihistory`](GenerateMultihistory.md) is the universal generator. It can generate everything that the
specialized `GenerateSingleHistory` and `GenerateAllHistories` can produce. However, it is more verbose, which can
make the code harder to read.

* Introspection:
  * [`$SetReplaceSystems`]($SetReplaceSystems.md) &mdash; yields the list of all implemented systems
* Generators:
  * [`GenerateMultihistory`](GenerateMultihistory.md) &mdash; the most customizable and explicit generator
* Parameters:
  * [`EventSelectionParameters`](EventSelectionParameters.md) &mdash; determines which events to include
  * [`EventOrderingFunctions`](EventOrderingFunctions.md) &mdash; determines the order of events
  * [`StoppingConditionParameters`](StoppingConditionParameters.md) &mdash; determines when to stop evaluation
