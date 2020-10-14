[![Discord](https://img.shields.io/discord/761616685173309481?logo=Discord)](https://discord.setreplace.org)

[Wolfram Models as Set Substitution Systems](#wolfram-models-as-set-substitution-systems) | [Getting Started](#getting-started) | [Symbols and Functions](#symbols-and-functions) | [Physics](#physics) | [Acknowledgements](#acknowledgements)

# Wolfram Models as Set Substitution Systems

## Set Substitution Systems

*SetReplace* is a [Wolfram Language](https://www.wolfram.com/language/) package for manipulating set substitution systems. To understand what a set substitution system does consider an unordered set of elements:

```wl
{1, 2, 5, 3, 6}
```

We can set up an operation on this set which would take any of the two elements and replace them with their sum:

```wl
{a_, b_} :> {a + b}
```

In *SetReplace*, this can be expressed as the following (the new element `1 + 2 -> 3` is put at the end)

```wl
In[] := SetReplace[{1, 2, 5, 3, 6}, {a_, b_} :> {a + b}]
Out[] = {5, 3, 6, 3}
```

Note that this is similar to [`SubsetReplace`](https://reference.wolfram.com/language/ref/SubsetReplace.html) function of Wolfram Language (introduced in version 12.1, it replaces all non-overlapping subsets at once by default):

```wl
In[] := SubsetReplace[{1, 2, 5, 3, 6}, {a_, b_} :> a + b]
Out[] = {3, 8, 6}
```

## Wolfram Models

A more interesting case (which we call a Wolfram model) is one where the set elements are related to each other. Specifically, we can consider a set of ordered lists of atomic vertices; in other words, an ordered hypergraph.

As an example consider a set:

```wl
{{1, 2, 3}, {2, 4, 5}, {4, 6, 7}}
```

We can render it as a collection of ordered hyperedges:

```wl
In[] := WolframModelPlot[{{1, 2, 3}, {2, 4, 5}, {4, 6, 7}},
 VertexLabels -> Automatic]
```

<img src="READMEImages/BasicHypergraphPlot.png" width="478">

We can then have a rule which would pick a subset of these hyperedges related through common vertices (much like a join query) and replace them with something else:

```wl
{{v1_, v2_, v3_}, {v2_, v4_, v5_}} :>
 Module[{v6}, {{v5, v6, v1}, {v6, v4, v2}, {v4, v5, v3}}]
```

Note the [`Module`](https://reference.wolfram.com/language/ref/Module.html) on the right-hand side creates a new variable (vertex) which causes the hypergraph to grow. Due to optimizations, it's not always a [`Module`](https://reference.wolfram.com/language/ref/Module.html) that creates vertices, so its name may be different. After a single replacement we get this (the new vertex is v11):

```wl
In[] := WolframModelPlot[SetReplace[{{1, 2, 3}, {2, 4, 5}, {4, 6, 7}},
  {{v1_, v2_, v3_}, {v2_, v4_, v5_}} :>
   Module[{v6}, {{v5, v6, v1}, {v6, v4, v2}, {v4, v5, v3}}]],
 VertexLabels -> Automatic]
```

<img src="READMEImages/EvolutionResult1Step.png" width="478">

After 10 steps, we get a more complicated structure:

```wl
In[] := WolframModelPlot[SetReplace[{{1, 2, 3}, {2, 4, 5}, {4, 6, 7}},
  {{v1_, v2_, v3_}, {v2_, v4_, v5_}} :>
   Module[{v6}, {{v5, v6, v1}, {v6, v4, v2}, {v4, v5, v3}}], 10],
 VertexLabels -> Automatic]
```

<img src="READMEImages/EvolutionResult10Steps.png" width="478">

And after 100 steps, it gets even more elaborate:

```wl
In[] := WolframModelPlot[SetReplace[{{1, 2, 3}, {2, 4, 5}, {4, 6, 7}},
  {{v1_, v2_, v3_}, {v2_, v4_, v5_}} :>
   Module[{v6}, {{v5, v6, v1}, {v6, v4, v2}, {v4, v5, v3}}], 100]]
```

<img src="READMEImages/EvolutionResult100Steps.png" width="478">

Exploring the hypergraph models of this variety is the primary purpose of this package.

# Physics

A hypothesis is that spacetime at small scales is a network, and the fundamental law of physics is a system similar to the one this package implements.

A slightly different version of this system was first introduced in *Stephen Wolfram*'s [A New Kind Of Science](https://www.wolframscience.com/nks/chap-9--fundamental-physics/).

You can find many more details about our physics results in *Stephen Wolfram*'s [Technical Introduction](https://www.wolframphysics.org/technical-introduction/), and *Jonathan Gorard*'s papers on [Relativity](https://www.wolframcloud.com/obj/wolframphysics/Documents/some-relativistic-and-gravitational-properties-of-the-wolfram-model.pdf) and [Quantum Mechanics](https://www.wolframcloud.com/obj/wolframphysics/Documents/some-quantum-mechanical-properties-of-the-wolfram-model.pdf). And there is much more on [wolframphysics.org](https://www.wolframphysics.org).

# Acknowledgements

In additional to commit authors and reviewers, *Stephen Wolfram* has contributed to the API design of most functions, and *Jeremy Davis* has contributed to the visual style of [`WolframModelPlot`](#wolframmodelplot), [`RulePlot`](#ruleplot-of-wolframmodel) and [`"CausalGraph"`](#causal-graphs).