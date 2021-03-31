###### [Generators](README.md)

# EventSelectionParameters

**`EventOrderingFunctions`** allows one to obtain the list of event ordering functions that can be used with a
[computational system](/Documentation/Systems/README.md):

```wl
In[] := EventOrderingFunctions[MultisetSubstitutionSystem]
Out[] = {"InputCount", "SortedInputExpressions", "UnsortedInputExpressions", "RuleIndex"}
```

The values returned by this function can typically be passed in any order to [generators](README.md) when used with the
corresponding system. (However, [`MultisetSubstitutionSystem`](/Documentation/Systems/README.md) only supports the
specific order returned by `EventOrderingFunctions` at the moment.)
