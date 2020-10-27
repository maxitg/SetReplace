###### [Symbols and Functions](/README.md#symbols-and-functions) > [WolframModel and WolframModelEvolutionObject](../WolframModelAndWolframModelEvolutionObject.md) > [Properties](../WolframModelAndWolframModelEvolutionObject.md#properties) >

# Event Counts

**`"AllEventsCount"`** (aka `"EventsCount"`) returns the overall number of events throughout the evolution (the [`Length`](https://reference.wolfram.com/language/ref/Length.html) of [`"AllEventsList"`](Events.md)).

**`"GenerationEventsCountList"`** gives the number of events per each generation ([`Length`](https://reference.wolfram.com/language/ref/Length.html) mapped over [`"GenerationEventsList"`](Events.md)):

```wl
In[] := WolframModel[{{1, 2}} -> {{1, 3}, {1, 3}, {3, 2}},
 {{1, 1}}, 5, "GenerationEventsCountList"]
Out[] = {1, 3, 9, 27, 81}
```
