# Generators

Generators are functions that generate [`Multihistory`](/Documentation/Types/Multihistory/README.md) objects for
[various computational systems](/Documentation/Systems/README.md).

Generators typically take rules for a particular computational system, the initial state, and some parameters of the
evaluation such as the number of events and whether to generate a single history or a multihistory.

The most general generator is [`GenerateMultihistory`](GenerateMultihistory.md), which takes the form

```wl
GenerateMultihistory[
  system, eventSelectionSpec, tokenDeduplicationSpec, eventOrderingSpec, stoppingConditionSpec][init]
```

`system` specifies the [computational system](/Documentation/Systems/README.md) to evaluate.

`eventSelectionSpec`
