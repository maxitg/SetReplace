Package["SetReplace`"]

PackageImport["GeneralUtilities`"]

PackageExport["GenerateMultihistory"]
PackageExport["GenerateSingleHistory"]

declareGenerator[GenerateMultihistory, <||>, Identity];
declareGenerator[GenerateSingleHistory, <|"MaxDestroyerEvents" -> 1|>, Identity];
