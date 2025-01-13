###### [Symbols and Functions](/README.md#symbols-and-functions) > [WolframModel and WolframModelEvolutionObject](../WolframModelAndWolframModelEvolutionObject.md) > [Properties](../WolframModelAndWolframModelEvolutionObject.md#properties) >

# Generation Counts

**`"TotalGenerationsCount"`** returns the largest generation of any edge during the evolution:

```wl
In[] := WolframModel[{{1, 2}} -> {{1, 3}, {1, 3}, {3, 2}}, {{1, 1}},
 <|"MaxEvents" -> 42|>, "TotalGenerationsCount"]
Out[] = 5
```

**`"CompleteGenerationsCount"`** yields the number of generations that are "completely done". That is, no more matches
can be made involving this or earlier generations. If the
default [evaluation order](../Options/EventOrderingFunction.md) is used, this can only be either the same
as `"TotalGenerationsCount"` (if we just finished a step) or one less (if we are in the middle of a step). However, it
gets much more interesting if a different event order is used. For a random evolution, for instance, one can get

```wl
In[] := WolframModel[{{1, 2}} -> {{1, 3}, {1, 3}, {3, 2}}, {{1, 1}},
 <|"MaxEvents" -> 42|>, "EventOrderingFunction" -> "Random"]
```

<img src="/Documentation/Images/RandomEvolutionObject.png"
     width="507"
     alt="Out[] = WolframModelEvolutionObject[... Generations: 1...8, Events: 42 ...]">

Note, in this case, only one generation is complete, and seven are partial. That happens because the states grow with
each generation, so it becomes more likely for a random choice to pick an edge from a later generation. Thus earlier
ones are left unevolved.

**`"PartialGenerationsCount"`** is simply a difference of `"TotalGenerationsCount"` and `"CompleteGenerationsCount"`,
and **`"GenerationsCount"`** is equivalent to `{"CompleteGenerationsCount", "PartialGenerationsCount"}`.

**`"GenerationComplete"`** takes a generation number as an argument, and
gives [`True`](https://reference.wolfram.com/language/ref/True.html)
or [`False`](https://reference.wolfram.com/language/ref/False.html) depending on whether that particular generation is
complete:

```wl
In[] := WolframModel[{{1, 2}} -> {{1, 3}, {1, 3}, {3, 2}}, {{1, 1}},
  <|"MaxEvents" -> 42|>]["GenerationComplete", 5]
Out[] = False
```
