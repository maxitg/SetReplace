Needs["CCompilerDriver`"]
lib = CreateLibrary[{"NumericArrayOperations.cpp"}, "NumericArrayOperations", options, "Defines" -> {"LLU_LOG_DEBUG"}];
Get[FileNameJoin[{$LLUSharedDir, "LibraryLinkUtilities.wl"}]];
`LLU`InitializePacletLibrary[lib];

`LLU`$Throws = False; (* library functions will not throw unless overriden on a per-function basis *)

emptyVector = `LLU`PacletFunctionLoad["CreateEmptyVector", {}, NumericArray];
emptyMatrix = `LLU`PacletFunctionLoad["CreateEmptyMatrix", {}, NumericArray];
echoNumericArrays = `LLU`PacletFunctionLoad["echoNumericArrays", {NumericArray, {NumericArray, "Manual"}, {NumericArray, "Shared"}}, "DataStore"];
getNALength = `LLU`PacletFunctionLoad["getNumericArrayLength", {NumericArray}, Integer];
getNARank = `LLU`PacletFunctionLoad["getNumericArrayRank", {NumericArray}, Integer];
newNA = `LLU`PacletFunctionLoad["newNumericArray", {}, NumericArray];
cloneNA = `LLU`PacletFunctionLoad["cloneNumericArrays", {{NumericArray, "Constant"}, {NumericArray, "Manual"}, {NumericArray, "Shared"}}, "DataStore"];
changeSharedNA = `LLU`PacletFunctionLoad["changeSharedNumericArray", {{NumericArray, "Shared"}}, Integer];
getSharedNA = `LLU`PacletFunctionLoad["getSharedNumericArray", {}, NumericArray];
accumulateIntegers = `LLU`PacletFunctionLoad["accumulateIntegers", {{NumericArray, "Constant"}}, Integer];
convertMethodName = `LLU`PacletFunctionLoad["convertMethodName", {Integer}, String];
convert = `LLU`PacletFunctionLoad["convert", {{NumericArray, "Constant"}, Integer, Real}, NumericArray];
convertGeneric = `LLU`PacletFunctionLoad["convertGeneric", {{NumericArray, "Constant"}, Integer, Real}, NumericArray];
testDimensions = `LLU`PacletFunctionLoad["TestDimensions", {{Integer, 1, "Constant"}}, NumericArray];
testDimensions2 = `LLU`PacletFunctionLoad["TestDimensions2", {}, "DataStore"];
FlattenThroughList = `LLU`PacletFunctionLoad["FlattenThroughList", {NumericArray}, NumericArray];
CopyThroughTensor = `LLU`PacletFunctionLoad["CopyThroughTensor", {NumericArray}, NumericArray];
GetLargest = `LLU`PacletFunctionLoad["GetLargest", {NumericArray, {NumericArray, "Constant"}, {NumericArray, "Manual"}}, Integer];
EmptyView = `LLU`PacletFunctionLoad["EmptyView", {}, {Integer, 1}];
SumLargestDimensions = `LLU`PacletFunctionLoad["SumLargestDimensions", {NumericArray, {NumericArray, "Constant"}}, Integer];
ReverseNA = `LLU`PacletFunctionLoad["Reverse", {{NumericArray, "Constant"}}, NumericArray];