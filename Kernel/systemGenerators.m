Package["SetReplace`"]

PackageImport["GeneralUtilities`"]

PackageExport["GenerateMultihistory"]
PackageExport["GenerateSingleHistory"]

PackageScope["generateMultihistory"]
PackageScope["generateSingleHistory"]

declareSystemGenerator[GenerateMultihistory, generateMultihistory, <||>, Identity];
declareSystemGenerator[GenerateSingleHistory, generateSingleHistory, <|"MaxDestroyerEvents" -> 1|>, Identity];
