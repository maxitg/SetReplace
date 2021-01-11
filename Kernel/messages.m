Package["SetReplace`"]

PackageScope["recognizedOptionsQ"]

(* Implementation *)

Attributes[recognizedOptionsQ] = HoldFirst;
recognizedOptionsQ[expr_, func_, opts_] := With[{unrecognizedOptions = FilterRules[opts, Except[Options[func]]]},
  If[unrecognizedOptions === {},
    True,
  (* else, some options are not recognized *)
    Message[func::optx, unrecognizedOptions[[1]], Defer[expr]];
    False
  ]
];

(* General Messages *)

General::invalidHypergraph =
  "The argument at position `1` in `2` is not a valid hypergraph.";

General::setNotList =
  "The set specification `1` should be a List.";

General::invalidRules =
  "The rule specification `1` should be either a Rule, RuleDelayed, or " ~~
  "a List of them.";

General::nonIntegerIterations =
  "The `1` `2` should be a non-negative integer or infinity.";

General::tooSmallStepLimit =
  "The maximum `1` `2` is smaller than that in initial condition `3`.";

General::nonListExpressions =
  "Encountered expression `1` which is not a list, even though a constraint on vertices is specified.";

General::lowLevelNotImplemented =
  "Low level implementation is only available for local rules, " <>
  "and only for sets of lists (hypergraphs).";

General::noLowLevel =
  "Low level implementation was not compiled for your system type.";

General::notRules =
  "The rule specification `1` should be either a Rule, or a List of rules.";

General::unknownProperty =
  "Property \"`1`\" should be one of \"Properties\".";

General::pargx =
  "Property \"`1`\" requested with `2` argument`3`; " <>
  "`4``5``6``7` argument`8` `9` expected.";

General::parameterTooLarge =
  "`1` `2` requested out of `3` total.";

General::parameterTooSmall =
  "`1` `2` cannot be smaller than `3`.";

General::parameterNotInteger =
  "`1` `2` must be an integer.";

General::multiwayFinalStepLimit =
  "The limit for the `2` is not supported for multiway systems.";

General::nonPropertyOpt =
  "Options expected (instead of `2`) " <>
  "beyond position 1 for `1` property. " <>
  "An option must be a rule or a list of rules.";

General::multiwayState =
  "Multiple destroyer events found for edge index `1`. States are not supported for multiway systems.";
