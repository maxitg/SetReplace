###### [Generators](README.md)

# EventOrderingFunctions

**`EventOrderingFunctions`** allows one to obtain the list of
[event ordering functions](GenerateMultihistory.md#Ordering-Functions) that can be used with a
[computational system](/Documentation/Systems/README.md):

```wl
In[] := EventOrderingFunctions[MultisetSubstitutionSystem]
Out[] = {"InputCount", "SortedInputExpressions", "UnsortedInputExpressions", "RuleIndex"}
```

The values returned by this function can typically be passed in any order to [generators](README.md) if used with the
corresponding system. However, in some cases systems can impose additional restrictions on which combinations of
ordering functions can be used.
