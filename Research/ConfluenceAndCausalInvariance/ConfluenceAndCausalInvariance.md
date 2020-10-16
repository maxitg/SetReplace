# Confluence and Causal Invariance

## Introduction

There are claims made in the [Wolfram Physics Project](https://www.wolframphysics.org) about the equivalence of
confluence and causal invariance.
For example, consider
[the glossary](http://web.archive.org/web/20201010194129/https://www.wolframphysics.org/glossary/#CausalInvariance) on
the [Wolfram Physics website](https://www.wolframphysics.org):

> Causal Invariance: A property of multiway graphs whereby all possible paths yield the isomorphic causal graphs.
> When causal invariance exists, every branch in the multiway system must eventually merge.
> Causal invariance is a core property associated with relativistic invariance, quantum objectivity, etc.
> In the theory of term rewriting, a closely related property is confluence.
> In a terminating system, causal invariance implies that whatever path is taken, the "answer" will always be the same.

> Confluence: A simplified form of causal invariance considered in term rewriting systems such as ones that reach fixed
> points.

In turn, the standard definition of
[confluence](https://en.wikipedia.org/wiki/Confluence_%28abstract_rewriting%29#General_case_and_theory) is

> A state `a` is deemed confluent if, for all pairs of states `b`, `c` that can be reached from `a`, there exists a
> state `d` that can be reached from both `b` and `c`.
> If every state in the system is confluent, the system itself is confluent.

We can summarize the statements above with the following definitions:

> A Wolfram model evolution is called *causal invariant* if and only if the
> [causal graphs](https://github.com/maxitg/SetReplace/blob/master/README.md#causal-graphs) for singleway evolutions
> with any possible
> [event ordering functions](https://github.com/maxitg/SetReplace/blob/master/README.md#eventorderingfunction) are
> isomorphic.

Note that the definition above is only meaningful for terminating systems (i.e., the systems which always reach a
[`"FixedPoint"`](https://github.com/maxitg/SetReplace/blob/master/README.md#termination-reason), a state during the
evolution where no more matches can be made to its expressions).

We can then define confluence as:

> A Wolfram model evolution is called *confluent* if any pair of partial singleway evolutions starting from a particular
> state can be continued in such a way as to reach isomorphic final states.

In what follows, we will demonstrate that causal invariance is *not* equivalent to confluence, neither of them implies the other, and the two statements made above are false:

> When causal invariance exists, every branch in the multiway system must eventually merge.

> In a terminating system, causal invariance implies that whatever path is taken, the "answer" will always be the same.

We will not make any comments in this note about the physics claims made above.

## Confluence !=> Causal Invariance

Consider the following confluent system:

```wl
confluentRule = {{{1, 2, 3, 4, 5}} -> {{1, 2, 3, 4}},
                 {{1, 2, 3, 4}} -> {{1}},
                 {{1, 2, 3, 4, 5}} -> {{1, 2, 3}},
                 {{1, 2, 3}} -> {{1, 2}},
                 {{1, 2}} -> {{1}}};
confluentInit = {{1, 2, 3, 4, 5}};
```

The system is confluent, as any partial evolution, if continued, will always terminate at the final state `{{1}}`:

```wl
In[] := ResourceFunction["MultiwaySystem"][
  "WolframModel" -> confluentRule, {confluentInit}, 3, "StatesGraphStructure", VertexLabels -> Automatic]
```

<img src="Images/ConfluentStatesGraph.png" width="274">

However, it is not causal invariant.
We can generate two non-isomorphic causal graphs by using different event ordering functions, which contradicts the
definition above:

```wl
In[] := WolframModel[confluentRule, confluentInit, Infinity, "EventOrderingFunction" -> #]["CausalGraph"] & /@
  {"RuleIndex", "ReverseRuleIndex"}
```

<img src="Images/ConfluentCausalGraphs.png" width="513">

Therefore, confluence *does not imply* causal invariance.

## Causal Invariance !=> Confluence

Consider the following causal invariant system:

```wl
causalInvariantRule = {{{1}} -> {{1, 1}}, {{1}} -> {{1, 2}}};
causalInvariantInit = {{1}};
```

To see that it's causal invariant, first note that there are only two singleway evolutions possible.
Each of them contains just a single event which is created using either the first or the second rule:

```wl
In[] := WolframModel[causalInvariantRule, causalInvariantInit, Infinity, "EventOrderingFunction" -> #][
  "ExpressionsEventsGraph", VertexLabels -> Placed[Automatic, After]] & /@
    {"RuleIndex", "ReverseRuleIndex"}
```

<img src="Images/CausalInvariantEvolutions.png" width="175">

These evolutions yield isomorphic causal graphs, which are composed of a single vertex with no edges, implying that this
system is causal invariant by definition:

```wl
In[] := IsomorphicGraphQ @@ Echo @ (
  WolframModel[causalInvariantRule, causalInvariantInit, Infinity, "EventOrderingFunction" -> #]["CausalGraph"] & /@
    {"RuleIndex", "ReverseRuleIndex"})
```

<img src="Images/CausalInvariantCausalGraphs.png" width="480">

```wl
Out[] = True
```

It is not, however, confluent, because the final states in these two evolutions are not isomorphic, and the evolutions
terminate after these states are reached:


```wl
In[] := WolframModel[causalInvariantRule, causalInvariantInit, Infinity, "EventOrderingFunction" -> #][
  "FinalState"] & /@ {"RuleIndex", "ReverseRuleIndex"}
Out[] = {{{1, 1}}, {{1, 2}}}
```

Therefore, causal invariance *does not imply* confluence.

## Future Research

Despite not being equivalent, causal invariance and confluence are, of course, related.
In particular, systems that don't exhibit
[multiway branching](https://github.com/maxitg/SetReplace/blob/master/README.md#eventselectionfunction) at all do
satisfy both of these conditions.
It would be interesting to enumerate ([#57](https://github.com/maxitg/SetReplace/issues/57)) simple rules and
determine how many of them exhibit one of these properties but not the other.

To do that, we need to implement tests for both confluence ([#59](https://github.com/maxitg/SetReplace/issues/59),
[#477](https://github.com/maxitg/SetReplace/issues/477)) and causal invariance in *SetReplace*.

It will also be interesting to investigate other similar properties.
For example, one can investigate a stronger version of confluence:
1. Consider any infinite singleway evolution of a system.
2. Consider another finite partial singleway evolution.
3. If any such finite evolution can be continued in such a way as to reach one of the states from the infinite
evolution, we define the system as *"super"confluent* [#478](https://github.com/maxitg/SetReplace/issues/478).
