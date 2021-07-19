Package["SetReplace`"]

PackageImport["GeneralUtilities`"]

PackageExport["GenerateMultihistory"]
PackageExport["GenerateSingleHistory"]

PackageScope["generateMultihistory"]
PackageScope["generateSingleHistory"]

declareSystemGenerator[
  GenerateMultihistory,
  generateMultihistory,
  <||>,
  Identity,
  "yields a Multihistory object of the evaluation of a specified system$ starting from an initial state init$."];

declareSystemGenerator[
  GenerateSingleHistory,
  generateSingleHistory,
  <|MaxDestroyerEvents -> 1|>,
  Identity,
  "yields a single history of the evaluation of a specified system$ starting from an initial state init$."];
