Package["SetReplace`"]

PackageImport["GeneralUtilities`"]

PackageScope["checkEnumOptionValue"]
PackageScope["checkIfKnownOptions"]

declareMessage[General::invalidOptionChoice, "Option value `option` -> `value` in `expr` should be one of `choices`."];
checkEnumOptionValue[func_, optionToCheck_, validValues_, options_] := With[{
    value = OptionValue[func, {options}, optionToCheck]},
  If[!MemberQ[validValues, value],
    throw[Failure["invalidOptionChoice", <|"value" -> value, "option" -> optionToCheck, "choices" -> validValues|>]]
  ];
];

declareMessage[General::optx, StringTemplate[General::optx]["`opt`", "`expr`"]];
checkIfKnownOptions[func_, options_, allowedOptions_ : Automatic] := With[{
    unknownOptions = Complement @@
      {Flatten[{options}][[All, 1]], If[allowedOptions === Automatic, Options[func][[All, 1]], allowedOptions]}},
  If[Length[unknownOptions] > 0, throw[Failure["optx", <|"opt" -> unknownOptions[[1]]|>]]];
];
