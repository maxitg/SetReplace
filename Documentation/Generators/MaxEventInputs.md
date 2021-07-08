# MaxEventInputs

`MaxEventInputs` and [`MinEventInputs`](MinEventInputs.md) are event-selection parameters that control the max and min
numbers of input tokens allowed per event. In addition to [being useful](MinEventInputs.md) for rules with variable
numbers of inputs, `MaxEventInputs` is sometimes useful for optimization. By default, systems like
[`MultisetSubstitutionSystem`](/Documentation/Systems/MultisetSubstitutionSystem.md) consider all subsets of tokens to
find matches, which can be slow, especially to finalize the complete evaluation, as it requires going through all
subsets to find out that no more matches are possible. However, if the range of match sizes is known ahead of time, it
can be used to make the evaluation faster. Compare:

```wl
In[] := First @ AbsoluteTiming @
  GenerateMultihistory[
      MultisetSubstitutionSystem[{a___} /; Length[{a}] == 4 :> {Total[{a}]}], {1, 2, 3, 4}, MaxEvents -> 20, #] & /@
    {{}, {MinEventInputs -> 4, MaxEventInputs -> 4}}
Out[] = {0.793215, 0.014419}
```
