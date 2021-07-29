Package["SetReplace`"]

PackageImport["GeneralUtilities`"]

PackageScope["checkEnumOptionValue"]
PackageScope["checkIfKnownOptions"]

declareMessage[General::invalidFiniteOption, "Value `value` of option `opt` should be one of `choices` in `expr`."];
checkEnumOptionValue[func_, optionToCheck_, validValues_, opts_] := ModuleScope[
  value = OptionValue[func, {opts}, optionToCheck];
  supportedQ = MemberQ[validValues, value];
  If[!supportedQ,
    throw[Failure["invalidFiniteOption", <|"value" -> value, "opt" -> optionToCheck, "choices" -> validValues|>]]
  ];
];

declareMessage[General::optx, StringTemplate[General::optx]["`opt`", "`expr`"]];
checkIfKnownOptions[func_, opts_, allowedOptions_ : Automatic] := With[{
    unknownOptions = Complement @@
      {Flatten[{opts}][[All, 1]], If[allowedOptions === Automatic, Options[func][[All, 1]], allowedOptions]}},
  If[Length[unknownOptions] > 0, throw[Failure["optx", <|"opt" -> unknownOptions[[1]]|>]]];
];
