###### [Symbols and Functions](/README.md#symbols-and-functions) > [WolframModel and WolframModelEvolutionObject](../WolframModelAndWolframModelEvolutionObject.md) > [Options](../WolframModelAndWolframModelEvolutionObject.md#options) >

# TimeConstraint

**`TimeConstraint`** option allows one to stop the evolution early. If an evolution object is requested, it will return
a partial result, otherwise, it will just give [`$Aborted`](https://reference.wolfram.com/language/ref/$Aborted.html):

```wl
In[] := WolframModel[{{1, 2}} -> {{1, 3}, {1, 3}, {3, 2}},
 {{1, 1}}, Infinity, TimeConstraint -> 1]
```

<img src="/Documentation/Images/TimeConstrainedEvolutionObject.png"
     width="565"
     alt="Out[] = WolframModelEvolutionObject[... Generations: 9...10, Events: 12454 ...]">
