###### [Symbols and Functions](/README.md#symbols-and-functions) > [WolframModel and WolframModelEvolutionObject](../WolframModelAndWolframModelEvolutionObject.md) > [Properties](../WolframModelAndWolframModelEvolutionObject.md#properties) >

# Feature Association

**`"FeatureAssociation"`** computes some features that can be handled by
[`FeatureExtraction`](https://reference.wolfram.com/language/ref/FeatureExtraction.html)
of the [`WolframModel`](/Documentation/SymbolsAndFunctions/WolframModelAndWolframModelEvolutionObject/WolframModelAndWolframModelEvolutionObject.md)
evolution and returns
an [`Association`](https://reference.wolfram.com/language/ref/Association.html) whose keys describe each feature
computed.
For now, it computes properties associated with these feature groups:

- `"StructurePreservingFinalStateGraph"`: The [`Graph`](https://reference.wolfram.com/language/ref/Graph.html)
version of
the [`"FinalState"`](/Documentation/SymbolsAndFunctions/WolframModelAndWolframModelEvolutionObject/Properties/States.md)
as given by [`HypergraphToGraph`](/Documentation/SymbolsAndFunctions/UtilityFunctions/HypergraphToGraph.md) using the
`"StructurePreserving"` transformation
- `"ObjectProperties"`: A list of properties of the [`WolframModel`](/Documentation/SymbolsAndFunctions/WolframModelAndWolframModelEvolutionObject/WolframModelAndWolframModelEvolutionObject.md)
that return a numeric value. Right now the list of properties is:
[`"CausalGraph"`](/Documentation/SymbolsAndFunctions/WolframModelAndWolframModelEvolutionObject/Properties/CausalGraphs.md),
[`"EventsCount"`](/Documentation/SymbolsAndFunctions/WolframModelAndWolframModelEvolutionObject/Properties/EventCounts.md),
[`"PartialGenerationsCount"`](/Documentation/SymbolsAndFunctions/WolframModelAndWolframModelEvolutionObject/Properties/GenerationCounts.md),
[`"AllEventsDistinctElementsCount"`](/Documentation/SymbolsAndFunctions/WolframModelAndWolframModelEvolutionObject/Properties/TotalElementCounts.md),
[`"AllEventsEdgesCount"`](/Documentation/SymbolsAndFunctions/WolframModelAndWolframModelEvolutionObject/Properties/TotalElementCounts.md),
[`"CompleteGenerationsCount"`](/Documentation/SymbolsAndFunctions/WolframModelAndWolframModelEvolutionObject/Properties/GenerationCounts.md),
[`"TerminationReason"`](/Documentation/SymbolsAndFunctions/WolframModelAndWolframModelEvolutionObject/Properties/TerminationReason.md).

```wl
In[] := WolframModel[{{x, y}, {x, z}} -> {{x, z}, {x, w}, {y, w}, {z, w}}, {{0, 0}, {0, 0}}, 5]["FeatureAssociation"]
```

<img src="/Documentation/Images/FeatureAssociationExampleSingleHistory.png"
     width="621.0"
     alt="Out[] = <|
       StructurePreservingFinalStateGraph -> Graph[...],
       ObjectPropertiesEventsCount -> 22,
       ObjectPropertiesPartialGenerationsCount -> 0,
       ObjectPropertiesAllEventsDistinctElementsCount -> 23,
       ObjectPropertiesAllEventsEdgesCount -> 90,
       ObjectPropertiesCompleteGenerationsCount -> 5,
       ObjectPropertiesTerminationReason -> MaxGenerations,
       ObjectPropertiesCausalGraph -> Graph[...]
     |>">

This property is useful for applying machine learning to Wolfram Models explorations:

```wl
In[] := BlockRandom[
  FeatureSpacePlot[#["FeatureAssociation"] -> Image[#["FinalStatePlot"], ImageSize -> Tiny] & /@
    (WolframModel[{{x, y}, {x, z}} -> {{x, z}, {x, w}, {y, w}, {z, w}}, #, 6] &) /@
      Table[RandomHypergraph[{3, 2}, 2], 10], LabelingFunction -> Callout], RandomSeeding -> 3
]
```

<img src="/Documentation/Images/FeatureAssociationFeatureSpacePlot.png"
     width="684.6"
     alt="Out[] = ... plot showing a feature space with 10 points labeled with hypergraph plots ...">

For [Multiway Systems](/Documentation/SymbolsAndFunctions/WolframModelAndWolframModelEvolutionObject/Properties/MultiwayQ.md)
it only computes features associated with
the [causal graph](/Documentation/SymbolsAndFunctions/WolframModelAndWolframModelEvolutionObject/Properties/CausalGraphs.md),
returning `Missing["NotExistent", {"MultiwaySystem", "FinalState"}]` for features related to
`"StructurePreservingFinalStateGraph"`, as there is
no [`"FinalState"`](/Documentation/SymbolsAndFunctions/WolframModelAndWolframModelEvolutionObject/Properties/States.md)
in a Multiway System:

```wl
In[] := WolframModel[{{x, y}, {x, z}} -> {{x, z}, {x, w}, {y, w}, {z, w}}, {{1, 1}, {1, 0}, {1, 1}}, 3,
  "EventSelectionFunction" -> "MultiwaySpacelike"]["FeatureAssociation"]
```

<img src="/Documentation/Images/FeatureAssociationExampleMultihistory.png"
     width="555.0"
     alt="Out[] = <|
       StructurePreservingFinalStateGraph -> Missing[NotExistent, {MultiwaySystem, FinalState}],
       ObjectPropertiesEventsCount -> 4054,
       ObjectPropertiesPartialGenerationsCount -> 0,
       ObjectPropertiesAllEventsDistinctElementsCount -> 4056,
       ObjectPropertiesAllEventsEdgesCount -> 16219,
       ObjectPropertiesCompleteGenerationsCount -> 3,
       ObjectPropertiesTerminationReason -> MaxGenerations,
       ObjectPropertiesCausalGraph -> Graph[...]
     |>">
