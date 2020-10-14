## SetReplace*

**`SetReplace`** (and related **`SetReplaceList`**, **`SetReplaceAll`**, **`SetReplaceFixedPoint`** and **`SetReplaceFixedPointList`**) are the functions the package is named after. They are quite simple, and perform replacement operations either one-at-a-time (as in the case of `SetReplace`), to all non-overlapping subsets (`SetReplaceAll`), or until no more matches can be made (`SetReplaceFixedPoint`). A suffix `*List` implies the function returns a list of sets after each step instead of just the final result.

These functions are good for their simplicity and can be primarily used to obtain replacement results. [`WolframModel`](WolframModel.md#wolframmodel-and-wolframmodelevolutionobject) is an advanced version of these functions and incorporates all of their features plus more sophisticated analysis capabilities.

As was mentioned previously, `SetReplace` performs a single iteration if called with two arguments:

```wl
In[] := SetReplace[set, rule]
```

For example,

```wl
In[] := SetReplace[{1, 2, 5, 3, 6}, {a_, b_} :> {a + b}]
Out[] = {5, 3, 6, 3}
```

It can be supplied a third argument specifying the number of replacements (the same can be achieved using [`Nest`](https://reference.wolfram.com/language/ref/Nest.html)):

```wl
In[] := SetReplace[{1, 2, 5, 3, 6}, {a_, b_} :> {a + b}, 2]
Out[] = {6, 3, 8}
```

If the number of replacements is set to [`Infinity`](https://reference.wolfram.com/language/ref/Infinity.html) calling `SetReplace` is equivalent to `SetReplaceFixedPoint`:

```wl
In[] := SetReplace[{1, 2, 5, 3, 6}, {a_, b_} :> {a + b}, Infinity]
Out[] = {17}
```

It is possible to use multiple rules (here the replacements `{1, 5} -> {5}` and `{2, 6} -> {8}` are made):

```wl
In[] := SetReplace[{1, 2, 5, 3, 6},
 {{a_?EvenQ, b_?EvenQ} :> {a + b}, {a_?OddQ, b_?OddQ} :> {a b}}, 2]
Out[] = {3, 5, 8}
```

`SetReplaceList` can be used to see the set after each replacement (here a list is omitted on the right-hand side of the rule, which can be done if the subset only contains a single element). Similar to `SetReplace`, if the number of steps is [`Infinity`](https://reference.wolfram.com/language/ref/Infinity.html), it's equivalent to `SetReplaceFixedPointList`:

```wl
In[] := SetReplaceList[{1, 2, 5, 3, 6}, {a_, b_} :> a + b, Infinity]
Out[] = {{1, 2, 5, 3, 6}, {5, 3, 6, 3}, {6, 3, 8}, {8, 9}, {17}}
```

`SetReplaceAll` replaces all non-overlapping subsets:

```wl
In[] := SetReplaceAll[{1, 2, 5, 3, 6}, {a_, b_} :> a + b]
Out[] = {6, 3, 8}
```

`SetReplaceFixedPoint` and `SetReplaceFixedPointList` perform replacements for as long as possible as previously mentioned:

```wl
In[] := SetReplaceFixedPoint[{1, 2, 5, 3, 6}, {a_, b_} :> a + b]
Out[] = {17}
```

```wl
In[] := SetReplaceFixedPointList[{1, 2, 5, 3, 6}, {a_, b_} :> a + b]
Out[] = {{1, 2, 5, 3, 6}, {5, 3, 6, 3}, {6, 3, 8}, {8, 9}, {17}}
```

All of these functions have [`Method`](Properties.md#method), [`TimeConstraint`](Properties.md#timeconstraint) and [`"EventOrderingFunction"`](Properties.md#eventorderingfunction) options. [`TimeConstraint`](Properties.md#timeconstraint) is self-explanatory. The other two work the same way as they do in [`WolframModel`](WolframModel.md#wolframmodel-and-wolframmodelevolutionobject), and we describe them further in the [`WolframModel`](WolframModel.md#wolframmodel-and-wolframmodelevolutionobject) section.