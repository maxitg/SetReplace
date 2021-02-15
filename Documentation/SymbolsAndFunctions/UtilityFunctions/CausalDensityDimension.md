###### [Symbols and Functions](/README.md#symbols-and-functions) > Utility Functions >

# CausalDensityDimension

**`CausalDensityDimension`** estimates the dimension of a subregion of a given graph, using the Myrheim-Meyer
dimension estimation algorithm.

## Myrheim Meyer Dimension Estimation

This method is based on [Causal Set Theory](https://en.wikipedia.org/wiki/Causal_sets), an approach to quantum gravity
which, much like the Wolfram Model, describes spacetime not as a continuum but as a large collection of discrete points
endowed with a causal partial order of the form *x* ≺ *y*, i.e. "*x* is to the past of *y*." A causal set then
contains a finite set of causal relations following this partial order in spacetime.

Starting from *d*-dimensional flat (Minkowski) space, the Myrheim-Meyer dimension
estimation works essentially as a box-counting method, whereby one can consider two points *p* and *q* in that space
that are causally connected. The Alexandrov Interval or causal diamond *A[p, q]* is then defined to be the
intersection of the future of the event *p* with the past of the event *q*. In this interval, define *C*<sub>*2*</sub>
to be the number of causal relations, i.e. the number of pairs *x* ≺ *y* between *p* and *q*, and define
*C*<sub>*1*</sub> to be the number of events (i.e. vertices) in the interval. It is found that a suitable
ratio between *C*<sub>*2*</sub> and *C*<sub>*1*</sub> is dependent on the dimensionality *d* into which
the causal set embeds:

<img src="/Documentation/Images/MyrheimMeyer.png" width="203.8">,

where *d* is the dimensionality of the (flat) manifold. This expression comes from the fact that the probabilty
that a random choice of elements in the causal set are causally connected is directly proportional to the volume
of the region *A[p, q]* in this set. By then evaluating an integral over this interval, one can obtain an
expectation value for the number of causal relations in that specified region. The result of this integration
is that of the right-hand side of the above expression. An explicit derivation of this result can be found in
[D. Meyer, The Dimension of Causal Sets](https://dspace.mit.edu/handle/1721.1/14328), where, note, spacetime is
defined as 1 + *d*-dimensional Minkowski space, which corresponds to *d* in our convention for
`CausalDensityDimension`.

The right-hand side of this equation is a monotonically decreasing function, meaning that one can invert the
relationship in order to determine the dimension *d*. It is worth noting that when the events *p* and *q* defining
the causal diamond are either causally disconnected or are the same event, the left-hand side of the above
expression will turn to 0, meaning that the dimensionality estimation will return infinity.

```wl
sprinkledGraph = BlockRandom[Module[{coordinates, causalSet},
  coordinates = Sort[Join[{{0, 0}, {1, 1}}, RandomReal[1, {48, 2}]] . RotationMatrix[Pi / 4]];
  causalSet = RelationGraph[Abs[#2[[2]] - #1[[2]]] < #2[[1]] - #1[[1]] &, coordinates];
  TransitiveReductionGraph @
    IndexGraph[causalSet, VertexCoordinates -> ({#2, 1 - #1} & @@@ coordinates), VertexLabels -> Automatic]
], RandomSeeding -> 0]
```

<img src="/Documentation/Images/CausalDensityDimensionInput.png" width="386.4">

```wl
In[] := CausalDensityDimension[sprinkledGraph, {1, 50}]
Out[] := 1.92705
```
