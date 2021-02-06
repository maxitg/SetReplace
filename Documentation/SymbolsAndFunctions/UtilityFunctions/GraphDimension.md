###### [Symbols and Functions](/README.md#symbols-and-functions) > Utility Functions >

# GraphDimension

**`GraphDimension`** estimates the dimension of a subregion of a given graph, using one of the supported methods
below.

## Dimension estimation methods

### `FlatCausalDiamondRelationProbability`

Uses the Myrheim-Meyer dimension estimation algorithm. This method is
based on Causal Set Theory, an approach to quantum gravity which, much like the Wolfram Model, describes spacetime
not as a continuum but as a large collection of discrete points endowed with a causal partial order of the form
x \[Precedes] y, i.e. "x is to the past of y." A causal set then contains a finite set of causal relations following
this partial order in space. Starting from d-dimensional flat (Minkowski) space, the Myrheim-Meyer dimension
estimation works essentially as a box-counting method, whereby one can consider two points *p* and *q* in that space
that are causally connected.The Alexandrov Interval or causal diamond *A[p, q]* is then defined to be the intersection
of the future of the event *p* with the past of the event *q*. In this interval, define C<sub>2</sub> to be the
average number of causal relations, i.e. the number of pairs x \[Precedes] y between *p* and *q*, and define
C<sub>1</sub> to be the average number of events (i.e. vertices) in the interval. It is found that a suitable ratio
between C<sub>2</sub> and C<sub>1</sub> is purely dependent on the dimensionality d into which the causal set embeds:

<img src="/Documentation/Images/MyrheimMeyer.png" width="203.8">,

where *d* is the dimensionality of the (flat) manifold. This expression comes from the fact that the probabilty
that a random choice of elements in the causal set are causally connected is directly proportional to the volume
of the region *A[p, q]* in this set. By then evaluating an integral over this interval, one can obtain an
expectation value for the number of causal relations in that specified region. The result of this integration
is that of the right-hand side of the above expression.

The right-hand side of this equation is a monotonically decreasing function, meaning that one can invert the
relationship in order to determine the dimension *d*. It is worth noting that when the events *p* and *q* defining
the causal diamond are either causally disconnected or are the same event, the left-hand side of the above expression
will diverge, meaning that the dimensionality estimation will return infinity.

```wl
In[] := graph = BlockRandom[
  IndexGraph[ResourceFunction["FlatSpacetimeSprinkling"][2, 50, "CausalGraph"], VertexLabels -> Automatic],
  RandomSeeding -> 0
]
```

<img src="/Documentation/Images/GraphDimensionInput.png" width="398.4">

```wl
In[] := GraphDimension[graph, "FlatCausalDiamondRelationProbability", {41, 17}]
Out[] := 2.00213
```
