###### [Symbols and Functions](/README.md#symbols-and-functions) > [WolframModel and WolframModelEvolutionObject](../WolframModelAndWolframModelEvolutionObject.md) > [Properties](../WolframModelAndWolframModelEvolutionObject.md#properties) >

# Token Deduplication

Multihistories often contain multiple tokens (expressions) that are equivalent in the sense that using any one of them
in place of another can never change the possible evolution. **`"TokenDeduplicationClasses"`** finds classes of such
tokens, and **`"DeduplicatedExpressionsEventsGraph"`** displays the
[`"ExpressionsEventsGraph"`](CausalGraphs.md) with each class merged into a single vertex. Edge multiplicities always
match event arities: an event consuming multiple tokens of the same class keeps an input edge per token.

Two tokens are merged if the multihistories obtained by deleting their causal pasts are isomorphic, the isomorphism
maps one token to the other, the tokens can never coexist in a single state (they are not spacelike separated: states
are multisets, so the number of identical tokens matters for matching), and every atom renaming performed by the
isomorphism is between *independent* atoms. Atoms are independent if they never occur together in a spacelike set of
tokens, so identifying them cannot change the contents of any state. Both conditions are facets of a single
requirement: every state must map injectively into the quotient. Deduplication merges timelike and branchlike
separated tokens only: it works between branches (merging identical tokens produced in different multiway branches)
and in time. In particular, evolutions that are periodic (up to renaming of atoms) collapse into cycles:

```wl
In[] := WolframModel[{{1, 2}} -> {{2, 3}}, {{1, 2}}, <|"MaxEvents" -> 6|>][
 "DeduplicatedExpressionsEventsGraph", VertexLabels -> Placed[Automatic, After]]
```

Note that the minimal period here is two rather than one, because consecutive tokens share an atom, and renaming an
atom into another atom of the same token is not allowed.

`"TokenDeduplicationClasses"` returns the underlying equivalence classes. Each class is named by its smallest member.
`"ExpressionClasses"` are indexed the same way as [`"AllEventsEdgesList"`](AllEdgesThroughoutEvolution.md),
`"EventClasses"` start with the initial (`0`) event, and `"AtomClasses"` only contain atoms that required renaming:

```wl
In[] := WolframModel[{{1, 2}} -> {{2, 3}}, {{1, 2}}, <|"MaxEvents" -> 6|>]["TokenDeduplicationClasses"]
Out[] = <|"ExpressionClasses" -> {1, 2, 1, 2, 1, 2, 1},
 "EventClasses" -> {0, 1, 2, 1, 2, 1, 2},
 "AtomClasses" -> <|3 -> 1, 4 -> 2, 5 -> 1, 6 -> 2, 7 -> 1, 8 -> 2|>|>
```

*Named* atoms — the atoms of the initial condition — are never identified with each other, since they are part of the
problem specification (although this is also implied by independence: initial tokens are all spacelike). Created atoms
can still be identified with named ones, in which case the named atom represents the class. For rules specified as
`"PatternRules"`, tokens are arbitrary expressions which the rules can reference directly, so all of their
subexpressions are treated as named: tokens are then only merged when their contents are literally identical, which is
still sufficient to, e.g., roll periodic pattern-rules evolutions into cycles:

```wl
In[] := WolframModel[<|"PatternRules" -> {{0} -> {1}, {0} -> {2}, {1} -> {3}, {2} -> {4}, {3} -> {2}, {4} -> {1}}|>,
  {0}, 10]["DeduplicatedExpressionsEventsGraph", VertexLabels -> Placed[Automatic, After]]
```

Tokens in generations that were not completely evolved (past
[`"CompleteGenerationsCount"`](GenerationCounts.md)) have incompletely known futures. The correspondence between
merged tokens is verified exactly within completely evolved generations (shifted by the generation difference of the
tokens). The parts of the correspondence beyond them cannot be verified directly, but since the future of a multiway
system is determined by its tokens, they are reproduced automatically once the evolution is continued. This is what
makes cycles appear in evolutions truncated by, e.g., `"MaxEvents"`. For evolutions that terminated on their own
(reached a [`"FixedPoint"`](TerminationReason.md)), the result is exact.
