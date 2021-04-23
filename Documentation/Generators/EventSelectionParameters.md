###### [Generators](README.md)

# EventSelectionParameters

**`EventSelectionParameters`** allows one to obtain the list of event selection parameters that can be used with a
[computational system](/Documentation/Systems/README.md):

```wl
In[] := EventSelectionParameters[MultisetSubstitutionSystem]
Out[] = {"MaxGeneration", "MaxDestroyerEvents", "MinEventInputs", "MaxEventInputs"}
```

The values returned by this function can be used as keys for the corresponding arguments of [generators](README.md).

## Selection Parameters

Selection parameters control which matches will be instantiated during the evolution. Unlike the
[stopping conditions](StoppingConditionParameters.md), these constraints are local. In other words, the evaluation does
not terminate if any of these constraints are encountered. Instead, only particular matches will be skipped.

### MaxGeneration

Roughly speaking, **generation** corresponds to how many "steps" it took to get to a particular token or event starting
from the initial state. More precisely, the generation of the tokens in the initial state is defined to be zero. The
generation of an event is defined as the maximum of the generations of its inputs plus one. The generation of a token is
the same as the generation of its creator event.

A neat feature of the `TokenEventGraph` property is that it arranges tokens and events on layers corresponding to their
generations. In the following example, the tokens and events are labeled with their generation numbers:

```wl
In[] := #["ExpressionsEventsGraph",
          VertexLabels -> Placed["Name", After, Replace[
            {{"Expression", n_} :> #["ExpressionGenerations"][[n]], {"Event", n_} :> #["EventGenerations"][[n]]}]]] & @
  SetReplaceTypeConvert[{WolframModelEvolutionObject, 2}] @
    GenerateMultihistory[MultisetSubstitutionSystem[{a__} /; Total[{a}] == 5 :> {Total[{a}] - 1, Total[{a}] + 1}],
                         {},
                         None,
                         EventOrderingFunctions[MultisetSubstitutionSystem],
                         "MaxEvents" -> 3] @ {1, 2, 3}
```

<img src="/Documentation/Images/TokenEventGraphGenerations.png" width="444.6">

Restricting the number of generations to one will prevent the last two events from occuring. Note, however, that another
event is created instead:

```wl
In[] := #["ExpressionsEventsGraph"] & @ SetReplaceTypeConvert[{WolframModelEvolutionObject, 2}] @
  GenerateMultihistory[MultisetSubstitutionSystem[{a__} /; Total[{a}] == 5 :> {Total[{a}] - 1, Total[{a}] + 1}],
                       {"MaxGeneration" -> 1},
                       None,
                       EventOrderingFunctions[MultisetSubstitutionSystem],
                       "MaxEvents" -> 3] @ {1, 2, 3}
```

<img src="/Documentation/Images/MaxGeneration.png" width="478.2">

Since `"MaxGeneration"` is a selection parameter rather than a [stopping condition](StoppingConditionParameters.md), it
will continue evaluation even after encountering matches exceeding the generations constraint, which might also result
in a different [event ordering](EventOrderingFunctions.md) than if using, e.g.,
[`"MaxEvents"`](StoppingConditionParameters.md#maxevents). For this reason, `"MaxGenerations"` (like other selection
parameters) does not have a corresponding termination reason as it cannot cause a termination by itself.

```wl
In[] := #[[2, "TerminationReason"]] & @
  GenerateMultihistory[MultisetSubstitutionSystem[{a__} /; Total[{a}] == 5 :> {Total[{a}] - 1, Total[{a}] + 1}],
                       {"MaxGeneration" -> 1},
                       None,
                       EventOrderingFunctions[MultisetSubstitutionSystem],
                       "MaxEvents" -> 3] @ {1, 2, 3}
Out[] = "Complete"
```

## MaxDestroyerEvents

## MinEventInputs and MaxEventInputs
