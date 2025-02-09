# Generators

Generators are functions that create [`Multihistory`](/Documentation/Types/Multihistory/README.md) objects. They take
rules for a [computational system](/Documentation/Systems/README.md) and additional parameters specifying how to perform
the evaluation.

In *SetReplace*, we split the states of [computational systems](/Documentation/Systems/README.md) into components which
we call tokens. Rewrites (which we call events) replace some of these tokens with others. *SetReplace* can evaluate
multiple branches of nondeterministic systems simultaneously. That is done by applying different events to the same
tokens and keeping events and tokens instead of states in [`Multihistory`](/Documentation/Types/Multihistory/README.md)
objects. We can reconstruct the states from that information afterward.

There are parameters that control how this evaluation is done. Some of them control which events to select. Other
parameters might control how to deduplicate identical tokens, etc. Different generators correspond to different settings
of parameters. Additional parameters can be specified with a syntax similar to options.

Note that if the system does not terminate, it is necessary to specify some parameters, such as
[`MaxEvents`](MaxEvents.md) or [`MaxGeneration`](MaxGeneration.md).

For example, [`GenerateSingleHistory`](GenerateSingleHistory.md) corresponds to
[`MaxDestroyerEvents -> 1`](MaxDestroyerEvents.md) and thus does not produce nondeterministic branching:

```wl
In[] := #["ExpressionsEventsGraph", VertexLabels -> Placed[Automatic, After]] & @
  SetReplaceTypeConvert[WolframModelEvolutionObject] @
    GenerateSingleHistory[MultisetSubstitutionSystem[{a_, b_} /; a < b :> {a + b}]] @ {1, 2, 3, 4}
```

<img src="/Documentation/Images/MultisetSubstitutionSystemExample.png"
     width="444.6"
     alt="Out[] = Graph[... {1, 2} -> {3 (* gen 1 *)}, {3 (* init *), 4} -> {7}, {3 (* gen 1 *), 7} -> {10} ...]">

We can also use a more general [`GenerateMultihistory`](GenerateMultihistory.md) and specify
[`MaxDestroyerEvents`](MaxDestroyerEvents.md) manually.

```wl
In[] := #["ExpressionsEventsGraph", VertexLabels -> Placed[Automatic, After]] & @
  SetReplaceTypeConvert[WolframModelEvolutionObject] @
    GenerateMultihistory[
      MultisetSubstitutionSystem[{a_, b_} /; a < b :> {a + b}], MaxDestroyerEvents -> 2] @ {1, 2, 3, 4}
```

<img src="/Documentation/Images/MultisetSubstitutionSystemPartialMultihistory.png"
     width="478.2"
     alt="Out[] = Graph[...
       {1, 2} -> {3 (* gen 1 *)},
       {1, 3 (* init *)} -> {4 (* gen 1 *)},
       {2, 3 (* init *)} -> {5},
       {3 (* gen 1 *), 4 (* init *)} -> {7},
       {4 (* init *), 5} -> {9}
     ...]">

The same generators support multiple systems. In addition to
[`MultisetSubstitutionSystem`](/Documentation/Systems/MultisetSubstitutionSystem.md), other examples include
`HypergraphSubstitutionSystem`, `StringSubstitutionSystem`, etc. Many of these systems have shared parameters.

All generators take the form

```wl
Generator[System[rules], parameters...] @ init
```

`parameters` can be specified either as a [`Sequence`](https://reference.wolfram.com/language/ref/Sequence.html) of
[`Rule`](https://reference.wolfram.com/language/ref/Rule.html)s, a
[`List`](https://reference.wolfram.com/language/ref/List.html) of
[`Rule`](https://reference.wolfram.com/language/ref/Rule.html)s or an
[`Association`](https://reference.wolfram.com/language/ref/Association.html). Keys supported
in such [`Rule`](https://reference.wolfram.com/language/ref/Rule.html)s depend on the system and can be looked up with
[`SetReplaceSystemParameters`](SetReplaceSystemParameters.md).

* Introspection:
  * [`$SetReplaceSystems`]($SetReplaceSystems.md) &mdash; yields the list of all implemented systems
  * [`$SetReplaceGenerators`]($SetReplaceGenerators.md) &mdash; yields the list of all generators
  * [`SetReplaceSystemParameters`](SetReplaceSystemParameters.md) &mdash; yields the list of parameters for a system
* Generators:
  * [`GenerateMultihistory`](GenerateMultihistory.md) &mdash; the universal generator for multihistories
  * [`GenerateSingleHistory`](GenerateSingleHistory.md) &mdash; sets `MaxDestroyerEvents -> 1`
* Parameters:
  * [`MaxDestroyerEvents`](MaxDestroyerEvents.md) &mdash; allows one to switch between single and multihistories
  * [`MinEventInputs`](MinEventInputs.md)
  * [`MaxEventInputs`](MaxEventInputs.md)
  * [`MaxEvents`](MaxEvents.md)
  * [`MaxGeneration`](MaxGeneration.md) &mdash; controls the depth of the evaluation
