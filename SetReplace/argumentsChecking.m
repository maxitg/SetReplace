Package["SetReplace`"]

PackageScope["supportedOptionQ"]
PackageScope["knownOptionsQ"]

supportedOptionQ[func_, optionToCheck_, validValues_, opts_] := Module[{value, supportedQ},
  value = OptionValue[func, {opts}, optionToCheck];
  supportedQ = MemberQ[validValues, value];
  If[!supportedQ,
    Message[MessageName[func, "invalidFiniteOption"], optionToCheck, value, validValues]
  ];
  supportedQ
]

knownOptionsQ[func_, funcCall_, opts_] := With[{
    unknownOptions = Complement @@ {opts, Options[func]}[[All, All, 1]]},
  If[Length[unknownOptions] > 0,
    Message[func::optx, unknownOptions[[1]], funcCall]
  ];
  Length[unknownOptions] == 0
]
