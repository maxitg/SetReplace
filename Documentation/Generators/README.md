# Generators

The purpose of *SetReplace* is the evaluation of nondeterministic computational systems. We have a unified framework to
support multiple such systems. In this framework, we split the states of these systems into components which we call
tokens. Rewrites (which we call events) replace some of these tokens with others.

[`MultisetSubstitutionSystem`](/Documentation/Systems/MultisetSubstitutionSystem.md) is one of the simplest examples. In
it, states are just sets of arbitrary expressions (tokens), and events replace subsets of tokens with other subsets. For
example, a system `{a_, b_} :> {a + b}` would add pairs of numbers until only one number remains. In the
[`Graph`](https://reference.wolfram.com/language/ref/Graph.html) below, tokens and events are shown in light blue and
orange:

```wl
In[] := #["ExpressionsEventsGraph", VertexLabels -> Placed[Automatic, After]] & @
  SetReplaceTypeConvert[{WolframModelEvolutionObject, 2}] @
    GenerateMultihistory[MultisetSubstitutionSystem[{a_, b_} /; a < b :> {a + b}],
                         {"MaxDestroyerEvents" -> 1, "MaxEventInputs" -> 2},
                         None,
                         EventOrderingFunctions[MultisetSubstitutionSystem],
                         {}] @ {1, 2, 3, 4}
```

<img src="/Documentation/Images/MultisetSubstitutionSystemExample.png" width="444.6">

Even though the system above is nondeterministic (it can choose any pair of numbers at each step), the graph is not: it
shows only a single possible evaluation. We can, however, generate graphs showing multiple possible evaluations
simultaneously as well:

```wl
In[] := #["ExpressionsEventsGraph", VertexLabels -> Placed[Automatic, After]] & @
  SetReplaceTypeConvert[{WolframModelEvolutionObject, 2}] @
    GenerateMultihistory[MultisetSubstitutionSystem[{a_, b_} /; a < b :> {a + b}],
                         {"MaxDestroyerEvents" -> 2, "MaxEventInputs" -> 2},
                         None,
                         EventOrderingFunctions[MultisetSubstitutionSystem],
                         {}] @ {1, 2, 3, 4}
```

<img src="/Documentation/Images/MultisetSubstitutionSystemPartialMultihistory.png" width="478.2">

[`MultisetSubstitutionSystem`](/Documentation/Systems/MultisetSubstitutionSystem.md) above is what defines the
kind of system we were using (other examples are `HypergraphSubstitutionSystem`, `StringSubstitutionSystem`, etc.).
However, the evaluation parameters of these systems have many similarities (e.g., all of them have
`"MaxDestroyerEvents"` parameter and support both single- (deterministic) and multi- (nondeterministic) histories). To
separate the specific systems from the specification of evaluation parameters, we use another function,
[`GenerateMultihistory`](GenerateMultihistory.md) to specify these parameters. This function is an example of a
**generator**.

[`GenerateMultihistory`](GenerateMultihistory.md) is the universal generator. It can generate everything that the
specialized `GenerateSingleHistory` and `GenerateFullMultihistory` can produce. However, it is more verbose, which can
make the code harder to read.

* Introspection:
  * [`$SetReplaceSystems`]($SetReplaceSystems.md) &mdash; yields the list of all implemented systems
* Generators:
  * [`GenerateMultihistory`](GenerateMultihistory.md) &mdash; the most customizable and explicit generator
* Parameters:
  * [`EventSelectionParameters`](EventSelectionParameters.md) &mdash; determine which events to include
  * [`EventOrderingFunctions`](EventOrderingFunctions.md) &mdash; determines the order of events
  * [`StoppingConditionParameters`](StoppingConditionParameters.md) &mdash; determines when the stop evaluation
