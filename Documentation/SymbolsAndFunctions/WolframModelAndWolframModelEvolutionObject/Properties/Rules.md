###### [Symbols and Functions](/README.md#symbols-and-functions) > [WolframModel and WolframModelEvolutionObject](../WolframModelAndWolframModelEvolutionObject.md) > [Properties](../WolframModelAndWolframModelEvolutionObject.md#properties) >

# Rules

**`"Rules"`** just stores the rules in the same way they were entered as an input to `WolframModel`:

```wl
In[] := WolframModel[<|"PatternRules" ->
    {{a_}} :> {{a + 1}, {a - 1}, {{a + 2, a - 2}}}|>,
  {{1}}, 1]["Rules"]
Out[] = <|"PatternRules" -> {{a_}} :> {{a + 1}, {a - 1}, {{a + 2, a - 2}}}|>
```

This is useful for display in the information box of the evolution object, and if one needs to reproduce an evolution object, the input for which is no longer available.
