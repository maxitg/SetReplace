Package["SetReplaceDevUtils`"]

PackageImport["GeneralUtilities`"]

PackageExport["ConsolePrintList"]

SetUsage @ "
ConsolePrintList[list$] will print a list of items in InputForm, one per line, with commas as appropriate.
";

ConsolePrintList[list_List] := (
  Print["{"];
  Scan[Print["  ", ToString[#, InputForm], ","]&, Most @ list];
  Print["  ", ToString[#, InputForm]]& @ Last @ list;
  Print["}"];
);

PackageExport["ConsoleTryEnvironment"]

SetUsage @ "
ConsoleTryEnvironment[var$, default$] will look up the value of the environment variable var$, but use \
default$ if it is not availabe.
";

SetAttributes[ConsoleTryEnvironment, HoldRest];
ConsoleTryEnvironment[var_, default_] := Replace[$Failed :> default] @ Environment[var];
