###### [Symbols and Functions](/README.md#symbols-and-functions) > [WolframModel and WolframModelEvolutionObject](../WolframModelAndWolframModelEvolutionObject.md) > [Options](../WolframModelAndWolframModelEvolutionObject.md#options) >

# "IncludePartialGenerations"

In case partial generations were produced, they can be automatically dropped by
setting **`"IncludePartialGenerations"`** to [`False`](https://reference.wolfram.com/language/ref/False.html). Compare
for instance

```wl
In[] := WolframModel[{{1, 2}} -> {{1, 3}, {1, 3}, {3, 2}},
 {{1, 1}}, <|"MaxEvents" -> 42|>]
```

<img src="/Documentation/Images/EvolutionObjectWithPartialGenerations.png"
     width="508"
     alt="Out[] = WolframModelEvolutionObject[... Generations: 4...5, Events: 42 ...]">

with

```wl
In[] := WolframModel[{{1, 2}} -> {{1, 3}, {1, 3}, {3, 2}},
 {{1, 1}}, <|"MaxEvents" -> 42|>,
 "IncludePartialGenerations" -> False]
```

<img src="/Documentation/Images/EvolutionObjectWithDroppedGenerations.png"
     width="488"
     alt="Out[] = WolframModelEvolutionObject[... Generations: 4, Events: 40 ...]">

One neat use of this is producing a uniformly random evolution for a complete number of generations:

```wl
In[] := WolframModel[{{1, 2, 3}, {2, 4, 5}} ->
  {{6, 6, 3}, {2, 6, 2}, {6, 4, 2}, {5, 3, 6}},
 {{1, 1, 1}, {1, 1, 1}}, <|"MaxEvents" -> 10000|>, "FinalStatePlot",
 "EventOrderingFunction" -> "Random",
 "IncludePartialGenerations" -> False]
```

<img src="/Documentation/Images/RandomEvolutionPlotWithDroppedGenerations.png"
     width="478"
     alt="Out[] = ... hypergraph plot showing a result of random evolution after a complete number of generations ...">
