(* Wolfram Language Test file *)
TestRequirement[$VersionNumber >= 12.0];
(***************************************************************************************************************************************)
(*
	Set of test cases to test LLU functionality related to Managed Library Expressions
*)
(***************************************************************************************************************************************)
TestExecute[
	Needs["CCompilerDriver`"];
	currentDirectory = DirectoryName[$TestFileName];

	(* Get configuration (path to LLU sources, compilation options, etc.) *)
	Get[FileNameJoin[{ParentDirectory[currentDirectory], "TestConfig.wl"}]];

	$CppVersion = "c++17";

	(* Compile the test library *)
	lib = CCompilerDriver`CreateLibrary[
		FileNameJoin[{currentDirectory, "TestSources", #}]& /@ {"UtilitiesTest.cpp"},
		"Utilities",
		options
	];

	Get[FileNameJoin[{$LLUSharedDir, "LibraryLinkUtilities.wl"}]];
	`LLU`InitializePacletLibrary[lib];

	`LLU`Logger`PrintLogFunctionSelector := Block[{`LLU`Logger`FormattedLog = `LLU`Logger`LogToShortString},
		`LLU`Logger`PrintLogToSymbol[LogSymbol][##]
	]&;

	`LLU`PacletFunctionSet @@@ {
		(* Load a number of library functions. We do not provide library path, so the one passed to InitializePacletLibrary will be used. *)
		{$OpenRead, "OpenForReading", {String}, Integer, "Throws" -> False},
		{$OpenWrite, "OpenForWriting", {String}, Integer, "Throws" -> False},
		{$OpenInvalidMode, "OpenInvalidMode", {String}, Integer, "Throws" -> False},

		(* If the function name is the same as symbol name only without the leading "$", the function name can be omitted. *)
		{$ReadStrings, {String}, "DataStore"},
		{$WriteStrings, {String, "DataStore"}, "Void"},
		{$OpenManagedFile, {`LLU`Managed[MyFile], String, Integer}, "Void"},
		{$OpenManagedFileStream, {`LLU`Managed[FileStream], String, Integer}, "Void"}
	};

	`LLU`Constructor[MyFile] = $OpenManagedFile;
	`LLU`Constructor[FileStream] = $OpenManagedFileStream;

	f = FileNameJoin[{$TemporaryDirectory, "some_file_that-hopefully-does_not_exist"}];

	topSecretFile = If[$OperatingSystem === "Windows", "C:\\Windows\\system.ini", "/etc/passwd"];
	
	FailureOnWindowsIntegerOtherwiseQ[expr_] := If[$OperatingSystem == "Windows", FailureQ, IntegerQ][expr];
	
	FailureOnWindowsManagedExprOtherwiseQ[expr_] := If[$OperatingSystem == "Windows", FailureQ, ManagedLibraryExpressionQ][expr];

	(* UTF conversion utilities *)
	`LLU`PacletFunctionSet @@@ {
		(* Load encoding-related library functions explicitly providing a path to the library. *)
		{$WideStringUTF8UTF16Conversion, lib, "WideStringUTF8UTF16Conversion", {}, "Boolean"},
		{$Char16UTF8UTF16Conversion, lib, "Char16UTF8UTF16Conversion", {}, "Boolean"},
		{$StringToUTF16Bytes, lib, "UTF8ToUTF16Bytes", {String}, NumericArray},
		{$UTF16BytesToString, lib, "UTF16BytesToUTF8", {NumericArray}, String},
		{$Char32UTF8UTF32Conversion, lib, "Char32UTF8UTF32Conversion", {}, "Boolean"},
		{$StringToUTF32Bytes, lib, "UTF8ToUTF32Bytes", {String}, NumericArray},
		{$UTF32BytesToString, lib, "UTF32BytesToUTF8", {NumericArray}, String}
	};
];

TestExecute[
	DeleteFile[f];
];

TestMatch[
	$OpenRead @ f
	,
	Failure["OpenFileFailed", <|
		"MessageTemplate" -> "Could not open file `f`.",
		"MessageParameters" -><|"f" -> f|>,
		"ErrorCode" -> _?CppErrorCodeQ,
		"Parameters" -> {}
	|>]
	,
	TestID -> "UtilitiesTestSuite-20190718-I7S1K0"
];

Test[
	$OpenWrite @ f
	,
	0
	,
	TestID -> "UtilitiesTestSuite-20191221-T0X0K0"
];

Test[
	Developer`EvaluateProtected @ $OpenRead @ f
	,
	0
	,
	TestID -> "UtilitiesTestSuite-20191221-P3Q0Q8"
];

TestMatch[
	$OpenInvalidMode @ f
	,
	Failure["InvalidOpenMode", <|
		"MessageTemplate" -> "Specified open mode is invalid.",
		"MessageParameters" -> <||>,
		"ErrorCode" -> _?CppErrorCodeQ,
		"Parameters" -> {}
	|>]
	,
	TestID -> "UtilitiesTestSuite-20191221-M2O8P0"
];

TestMatch[
	Developer`EvaluateProtected @ $OpenWrite[topSecretFile]
	,
	Failure["PathNotValidated", <|
		"MessageTemplate" -> "File path `path` could not be validated under desired open mode.",
		"MessageParameters" -><|"path" -> topSecretFile|>,
		"ErrorCode" -> _?CppErrorCodeQ,
		"Parameters" -> {}
	|>]
	,
	TestID -> "UtilitiesTestSuite-20191221-T5I6L4"
];

TestExecute[
	words = {"upraise", "saturnalia", "phonology", "salutatory", "molester", "evolution", "hoist", "humbled", "rusty", "fluctuate"};
];

Test[
	$WriteStrings[f, Developer`DataStore @@ words]
	,
	Null
	,
	TestID -> "UtilitiesTestSuite-20191221-I2C5M4"
];

Test[
	$ReadStrings[f]
	,
	Developer`DataStore @@ words
	,
	TestID -> "UtilitiesTestSuite-20191221-D3K3Z9"
];

VerificationTest[
	Block[{myFile},
		myFile = `LLU`NewManagedExpression[MyFile][f, 0 (* read-access*)];
		ManagedLibraryExpressionQ[myFile] && IntegerQ[$OpenRead @ f] && IntegerQ[$OpenWrite @ f]
	]
	,
	TestID -> "UtilitiesTestSuite-20191231-O4Y9S8"
];

VerificationTest[
	Block[{myFile},
		myFile = `LLU`NewManagedExpression[MyFile][f, 1 (* write-access*)];
		ManagedLibraryExpressionQ[myFile] && IntegerQ[$OpenRead @ f] && FailureOnWindowsIntegerOtherwiseQ[$OpenWrite @ f]
	]
	,
	TestID -> "UtilitiesTestSuite-20191231-U6M3T5"
];

VerificationTest[
	Block[{myFile},
		myFile = `LLU`NewManagedExpression[MyFile][f, 2 (* read-write-access*)];
		ManagedLibraryExpressionQ[myFile] && IntegerQ[$OpenRead @ f] && FailureOnWindowsIntegerOtherwiseQ[$OpenWrite @ f]
	]
	,
	TestID -> "UtilitiesTestSuite-20191231-P2D8V0"
];

VerificationTest[
	Block[{fs, fs2, fs3},
		fs = CatchAll @ `LLU`NewManagedExpression[FileStream][f, 0 (* read-access*)];
		fs2 = CatchAll @ `LLU`NewManagedExpression[FileStream][f, 1 (* write-access*)];
		fs3 = CatchAll @ `LLU`NewManagedExpression[FileStream][f, 0 (* read-access*)];
		ManagedLibraryExpressionQ[fs] && FailureOnWindowsManagedExprOtherwiseQ[fs2] && ManagedLibraryExpressionQ[fs3]
	]
	,
	TestID -> "UtilitiesTestSuite-20200102-P6T5D6"
];

VerificationTest[
	Block[{fs, fs2, fs3},
		fs = CatchAll @ `LLU`NewManagedExpression[FileStream][f, 1 (* write-access*)];
		fs2 = CatchAll @ `LLU`NewManagedExpression[FileStream][f, 1 (* write-access*)];
		fs3 = CatchAll @ `LLU`NewManagedExpression[FileStream][f, 0 (* read-access*)];
		ManagedLibraryExpressionQ[fs] && FailureOnWindowsManagedExprOtherwiseQ[fs2] && FailureOnWindowsManagedExprOtherwiseQ[fs3]
	]
	,
	TestID -> "UtilitiesTestSuite-20200102-Z1E0R2"
];

VerificationTest[
	$WideStringUTF8UTF16Conversion[]
	,
	TestID -> "UtilitiesTestSuite-20200313-U7T5E2"
];

VerificationTest[
	$Char16UTF8UTF16Conversion[]
	,
	TestID -> "UtilitiesTestSuite-20200319-O6X5L7"
];

Test[
	$StringToUTF16Bytes[FromCharacterCode[{97, 98, 99, 65, 66, 67, 206, 177, 206, 178, 206, 179}, "UTF8"]]
	,
	NumericArray[{97, 98, 99, 65, 66, 67, 945, 946, 947}, "UnsignedInteger16"]
	,
	TestID -> "UtilitiesTestSuite-20200319-C7S3X2"
];

Test[
	$UTF16BytesToString[NumericArray[{97, 98, 99, 65, 66, 67, 945, 946, 947}, "UnsignedInteger16"]]
	,
	FromCharacterCode[{97, 98, 99, 65, 66, 67, 206, 177, 206, 178, 206, 179}, "UTF8"]
	,
	TestID -> "UtilitiesTestSuite-20200319-S9X8R6"
];

VerificationTest[
	$Char32UTF8UTF32Conversion[]
	,
	TestID -> "UtilitiesTestSuite-20200319-B7Y3D9"
];


Test[
	$StringToUTF32Bytes[FromCharacterCode[{122, 195, 159, 230, 176, 180, 240, 159, 141, 140}, "UTF8"]]
	,
	NumericArray[{122, 223, 27700, 127820}, "UnsignedInteger32"]
	,
	TestID -> "UtilitiesTestSuite-20200319-V9K7W3"
];


Test[
	$UTF32BytesToString[NumericArray[{122, 223, 27700, 127820}, "UnsignedInteger32"]]
	,
	FromCharacterCode[{122, 195, 159, 230, 176, 180, 240, 159, 141, 140}, "UTF8"]
	,
	TestID -> "UtilitiesTestSuite-20200319-B4O4E2"
];