###### [Symbols and Functions](/README.md#symbols-and-functions) >

# Generators

Generators are functions that generate [`Multihistory`](TODO) objects for
[various computational systems]($SetReplaceSystems.md).

Generators typically take rules for a particular computational system, the initial state, and some parameters of the
evaluation such as the number of events and whether to generate a single history or a multihistory.

The most general generator is [`GenerateMultihistory`](TODO), which takes the form

```wl
GenerateMultihistory[
  system, eventSelectionSpec, tokenDeduplicationSpec, eventOrderingSpec, stoppingConditionSpec][init]
```

`system` specifies the computational system to evaluate.

`eventSelectionSpec`
