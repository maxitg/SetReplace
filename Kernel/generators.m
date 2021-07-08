Package["SetReplace`"]

PackageImport["GeneralUtilities`"]

PackageExport["GenerateMultihistory"]
PackageExport["GenerateSingleHistory"]

PackageScope["generateMultihistory"]
PackageScope["generateSingleHistory"]

declareGenerator[GenerateMultihistory, generateMultihistory, <||>, Identity];
declareGenerator[GenerateSingleHistory, generateSingleHistory, <|"MaxDestroyerEvents" -> 1|>, Identity];
