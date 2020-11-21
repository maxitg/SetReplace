Package["SetReplaceDevUtils`"]

PackageImport["GeneralUtilities`"]


PackageExport["ConsoleBuildLibSetReplace"]

ConsoleBuildLibSetReplace[opts___] := ModuleScope @ Check[

  Off[General::stop];

  result = BuildLibSetReplace[opts, "PrintBeforeBuild" -> True];

  If[FailureQ[result],
    Print["Build failed."];
    ReturnFailed[];
  ];

  If[result["FromCache"],
    Print["Using cached build"];
  ];

  Print["Library at ", result["LibraryPath"]];
  Print["Build succeeded"];

  result
,
  Print["Message occurred during build. Build failed."];
  $Failed
];


PackageExport["ConsoleCreateSetReplacePaclet"]

ConsoleCreateSetReplacePaclet[opts___] := ModuleScope @ Check[

  If[!AssociationQ[ConsoleBuildLibSetReplace[opts]],
    Print["Build failed, creation of paclet aborted."];
    ReturnFailed[]];

  result = CreateSetReplacePaclet[];

  If[FailureQ[result] ,
    Print["Creation of paclet failed."];
    ReturnFailed[];
  ];

  Print["Paclet created at ", result["Location"]];
  Print["Creation of paclet succeeded."];

  result["Location"]
,
  Print["Message occurred during pack. Pack failed."];
  $Failed
];



PackageExport["ConsolePrintList"]

SetUsage @ "
ConsolePrintList[list$] will print a list of items in InputForm, one per line, with commas as appropriate.
"

ConsolePrintList[list_List] := (
  Print["{"];
  Scan[Print["  ", ToString[#, InputForm], ","]&, Most @ list];
  Print["  ", ToString[#, InputForm]]& @ Last @ list;
  Print["}"];
);



PackageExport["ConsoleTryEnvironment"]

SetUsage @ "
ConsoleTryEnvironment[var$, default$] will look up the value of the environment variable var$, but use default$ if it is not availabe.
"

SetAttributes[ConsoleTryEnvironment, HoldRest];
ConsoleTryEnvironment[var_, default_] := Replace[$Failed :> default] @ Environment[var];
