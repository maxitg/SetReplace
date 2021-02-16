Package["SetReplaceDevUtils`"]

PackageImport["GeneralUtilities`"]

PackageExport["ConsolePrintList"]
PackageExport["ConsoleTryEnvironment"]

SyntaxInformation[ConsolePrintList] = {"ArgumentsPattern" -> {list_}};

SetUsage @ "
ConsolePrintList[list$] will print a list of items in InputForm, one per line, with commas as appropriate.
";

ConsolePrintList[list_List] := (
  Print["{"];
  Scan[Print["  ", ToString[#, InputForm], ","]&, Most @ list];
  Print["  ", ToString[#, InputForm]]& @ Last @ list;
  Print["}"];
);

SyntaxInformation[ConsoleTryEnvironment] = {"ArgumentsPattern" -> {var_, default_}};

SetUsage @ "
ConsoleTryEnvironment[var$, default$] will look up the value of the environment variable var$, but use \
default$ if it is not availabe.
";

SetAttributes[ConsoleTryEnvironment, HoldRest];
ConsoleTryEnvironment[var_, default_] := Replace[$Failed :> default] @ Environment[var];
