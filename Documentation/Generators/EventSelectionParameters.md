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
          VertexLabels -> Placed["Name", After, Replace[{{"Expression", n_} :> #["ExpressionGenerations"][[n]],
                                                         {"Event", n_} :> #["EventGenerations"][[n]]}]]] & @
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
parameters) does not have a corresponding termination reason.

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

`"MaxDestroyerEvents"` controls the number of (inconsistent) events that are allowed to take the same token as an input.
If `"MaxDestroyerEvents"` is set to one, a single-history system will be generated similar to `GenerateSingleHistory`:

```wl
In[] := #["ExpressionsEventsGraph", VertexLabels -> Placed[Automatic, After]] & @
  SetReplaceTypeConvert[{WolframModelEvolutionObject, 2}] @
    GenerateMultihistory[MultisetSubstitutionSystem[{a_, b_} :> {a + b}],
                         "MaxDestroyerEvents" -> 1,
                         None,
                         EventOrderingFunctions[MultisetSubstitutionSystem],
                         {}] @ {1, 2, 3}
```

<img src="/Documentation/Images/MaxDestroyerEvents1.png" width="322.2">

If unset (i.e., set to [`Infinity`](https://reference.wolfram.com/language/ref/Infinity.html)), it will generate a full
multihistory (similar to `GenerateFullMultihistory`) subject to other selection and stopping parameters:

```wl
In[] := #["ExpressionsEventsGraph", VertexLabels -> Placed[Automatic, After]] & @
  SetReplaceTypeConvert[{WolframModelEvolutionObject, 2}] @
    GenerateMultihistory[MultisetSubstitutionSystem[{a_, b_} :> {a + b}],
                         {"MaxDestroyerEvents" -> Infinity, "MaxGeneration" -> 1, "MaxEventInputs" -> 2},
                         None,
                         EventOrderingFunctions[MultisetSubstitutionSystem],
                         {}] @ {1, 2, 3}
```

<img src="/Documentation/Images/MaxDestroyerEventsInfinity.png" width="478.2">

If set to a finite number, it will generate a partial multihistory:

```wl
In[] := #["ExpressionsEventsGraph", VertexLabels -> Placed[Automatic, After]] & @
  SetReplaceTypeConvert[{WolframModelEvolutionObject, 2}] @
    GenerateMultihistory[MultisetSubstitutionSystem[{a_, b_} :> {a + b}],
                         {"MaxDestroyerEvents" -> 5, "MaxEventInputs" -> 2},
                         None,
                         EventOrderingFunctions[MultisetSubstitutionSystem],
                         {}] @ {1, 2, 3}
```

<img src="/Documentation/Images/MaxDestroyerEvents5.png" width="478.2">

Note that in this case, like in the case of a single history, changing [ordering functions](EventOrderingFunctions.md)
will change the result.

## MinEventInputs and MaxEventInputs
