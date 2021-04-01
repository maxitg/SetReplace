###### [Generators](README.md)

# EventSelectionParameters

**`EventSelectionParameters`** allows one to obtain the list of event selection parameters that can be used with a
[computational system](/Documentation/Systems/README.md):

```wl
In[] := EventSelectionParameters[MultisetSubstitutionSystem]
Out[] = {"MaxGeneration", "MaxDestroyerEvents", "MinEventInputs", "MaxEventInputs"}
```

The values returned by this function can be used as
[`Association`](https://reference.wolfram.com/language/ref/Association.html) keys for the corresponding arguments of
[generators](README.md).
