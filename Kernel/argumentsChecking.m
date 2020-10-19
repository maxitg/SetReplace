Package["SetReplace`"]

PackageImport["GeneralUtilities`"]

PackageScope["supportedOptionQ"]
PackageScope["knownOptionsQ"]

General::invalidFiniteOption =
  "Value `2` of option `1` should be one of `3`.";

supportedOptionQ[func_, optionToCheck_, validValues_, opts_] := ModuleScope[
  value = OptionValue[func, {opts}, optionToCheck];
  supportedQ = MemberQ[validValues, value];
  If[!supportedQ,
    Message[func::invalidFiniteOption, optionToCheck, value, validValues]
  ];
  supportedQ
]

knownOptionsQ[func_, funcCall_, opts_, allowedOptions_ : Automatic] := With[{
    unknownOptions =
      Complement @@ {opts[[All, 1]], If[allowedOptions === Automatic, Options[func][[All, 1]], allowedOptions]}},
  If[Length[unknownOptions] > 0,
    Message[func::optx, unknownOptions[[1]], funcCall]
  ];
  Length[unknownOptions] == 0
]
