###### [Symbols and Functions](/README.md#symbols-and-functions) > [WolframModel and WolframModelEvolutionObject](../WolframModelAndWolframModelEvolutionObject.md) > [Properties](../WolframModelAndWolframModelEvolutionObject.md#properties) >

# Version

**`"Version"`** returns the version of the data structure used in the evolution object. It will always be the same for the same version of *SetReplace*:

```wl
In[] := WolframModel[1 -> 2, {1}]["Version"]
Out[] = 2
```

Objects are automatically converted to the latest version when they are encountered by the newer version of *SetReplace*.
