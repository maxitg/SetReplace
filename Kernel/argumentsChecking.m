Package["SetReplace`"]

PackageImport["GeneralUtilities`"]

PackageScope["supportedOptionQ"]
PackageScope["knownOptionsQ"]

declareMessage[General::invalidFiniteOption, "Value `value` of option `opt` should be one of `choices` in `expr`."];
supportedOptionQ[func_, optionToCheck_, validValues_, opts_] := ModuleScope[
  value = OptionValue[func, {opts}, optionToCheck];
  supportedQ = MemberQ[validValues, value];
  If[!supportedQ,
    throw[Failure["invalidFiniteOption", <|"value" -> value, "opt" -> optionToCheck, "choices" -> validValues|>]]
  ,
    True
  ]
];

declareMessage[General::optx, StringTemplate[General::optx]["`opt`", "`expr`"]];
knownOptionsQ[func_, opts_, allowedOptions_ : Automatic] := With[{
    unknownOptions = Complement @@
      {Flatten[{opts}][[All, 1]], If[allowedOptions === Automatic, Options[func][[All, 1]], allowedOptions]}},
  If[Length[unknownOptions] > 0,
    throw[Failure["optx", <|"opt" -> unknownOptions[[1]]|>]]
  ,
    True
  ]
];
