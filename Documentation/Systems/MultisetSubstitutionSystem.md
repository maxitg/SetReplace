# MultisetSubstitutionSystem

States of the **`MultisetSubstitutionSystem`** are unordered multisets of tokens, which are arbitrary Wolfram Language
expressions. Events take submultisets of these and replace them with other multisets.
[`SubsetReplace`](https://reference.wolfram.com/language/ref/SubsetReplace.html) evaluates this system, for example.

The left-hand sides of rules are written as Wolfram Language patterns. The first level of these patterns should match to
a [`List`](https://reference.wolfram.com/language/ref/List.html), and is matched to a multiset of tokens, so
`{n__Integer, s_String}` and `{s_String, n__Integer}` are equivalent aside from their effect on the event order and can
match, e.g., `{1, 2, "s"}`, `{2, "x", 3}` and `{"q", 1}`.

The right-hand sides determine the result of the replacement similar to
[`Replace`](https://reference.wolfram.com/language/ref/Replace.html). The top level of the output must be a
[`List`](https://reference.wolfram.com/language/ref/List.html), and it is converted to a multiset of tokens to be
inserted into the output state.

For example, to make a system that adds pairs of numbers:

```wl
In[] := #["ExpressionsEventsGraph", VertexLabels -> Placed[Automatic, After]] & @
  SetReplaceTypeConvert[WolframModelEvolutionObject] @
    GenerateSingleHistory[MultisetSubstitutionSystem[{a_, b_} /; a < b :> {a + b}]] @ {1, 2, 3, 4}
```

<img src="/Documentation/Images/MultisetSubstitutionSystemExample.png"
     width="444.6"
     alt="Out[] = ... {1, 2} -> {3 (* gen 1 *)}, {3 (* init *), 4} -> {7}, {3 (* gen 1 *), 7} -> {10} ...">

Arbitrary Wolfram Language patterns are supported including
[conditions](https://reference.wolfram.com/language/ref/Condition.html) such as `{a_ /; a > 0, b_}` and
`{a_, b_} /; a + b == 3` and [sequences](https://reference.wolfram.com/language/ref/BlankSequence.html) that match
multiple tokens at once in any order, e.g., `{a__}`. Any code is supported on the right-hand side as long as it always
generates a list. For example:

```wl
In[] := #["ExpressionsEventsGraph", VertexLabels -> Placed[Automatic, After]] & @
  SetReplaceTypeConvert[WolframModelEvolutionObject] @
    GenerateMultihistory[
      MultisetSubstitutionSystem[{a__} /; OrderedQ[{a}] && PrimeQ[Plus[a]] :> First /@ FactorInteger[Plus[a]]],
      MinEventInputs -> 2, MaxEventInputs -> 4] @ {1, 2, 3, 4}
```

<img src="/Documentation/Images/MultisetSubstitutionSystemConditionsAndSequences.png"
     width="478.2"
     alt="Out[] = ...
       generation 1: {1, 2} -> {3}, {1, 4} -> {5}, {2, 3} -> {5}, {3, 4} -> {7}, {1, 2, 4} -> {7},
       generation 2: {2, 5} -> {7}, {3 (* gen 1 *), 4} -> {7}
     ...">

Note, however, that the system cannot recognize if the code on the right-hand side is nondeterministic, so only the
first output will be used for each assignment of pattern variables.

`MultisetSubstitutionSystem` supports
[`MaxGeneration`](/Documentation/Generators/MaxGeneration.md),
[`MaxDestroyerEvents`](/Documentation/Generators/MaxDestroyerEvents.md),
[`MinEventInputs`](/Documentation/Generators/MinEventInputs.md) and
[`MaxEventInputs`](/Documentation/Generators/MaxEventInputs.md)
for event selection. It supports
[`MaxEvents`](/Documentation/Generators/MaxEvents.md) as a stopping condition. Only a single event order
`{"InputCount", "SortedInputTokenIndices", "InputTokenIndices", "RuleIndex", "InstantiationIndex"}` is implemented at
the moment.
