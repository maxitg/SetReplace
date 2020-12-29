(* Wolfram Language Test file *)
TestRequirement[$VersionNumber > 10.3];
(***************************************************************************************************************************************)
(*
	Set of test cases to test LLU functionality related to passing modes of different containers
*)
(***************************************************************************************************************************************)
TestExecute[
	Needs["CCompilerDriver`"];
	currentDirectory = DirectoryName[$TestFileName];

	(* Get configuration (path to LLU sources, compilation options, etc.) *)
	Get[FileNameJoin[{ParentDirectory[currentDirectory], "TestConfig.wl"}]];

	(* Compile the test library *)
	lib = CCompilerDriver`CreateLibrary[FileNameJoin[{currentDirectory, "TestSources", #}]& /@ {"GenericContainersTest.cpp"},
		"GenericContainers", options, "Defines" -> {"LLU_LOG_DEBUG"}];

	Get[FileNameJoin[{$LLUSharedDir, "LibraryLinkUtilities.wl"}]];

	`LLU`InitializePacletLibrary[lib];

	Off[General::stop]; (* because we want to see all error messages from CreateLibrary *)

	OwnerAutomatic = `LLU`PacletFunctionLoad["IsOwnerAutomatic", {Image}, "Boolean"];
	OwnerManual = `LLU`PacletFunctionLoad["IsOwnerManual", {{Integer, _, "Manual"}}, "Boolean"];
	OwnerShared = `LLU`PacletFunctionLoad["IsOwnerShared", {{NumericArray, "Shared"}}, "Boolean"];

	CloneAutomatic = `LLU`PacletFunctionLoad["CloneAutomatic", {Image}, Image];
	CloneManual = `LLU`PacletFunctionLoad["CloneManual", {{Integer, _, "Manual"}}, {Integer, _}];
	CloneShared = `LLU`PacletFunctionLoad["CloneShared", {{NumericArray, "Shared"}}, NumericArray];

	MoveAutomatic = `LLU`PacletFunctionLoad["MoveAutomatic", {Image}, Image];
	MoveManual = `LLU`PacletFunctionLoad["MoveManual", {{Integer, _, "Manual"}}, {Integer, _}];
	MoveShared = `LLU`PacletFunctionLoad["MoveShared", {{NumericArray, "Shared"}}, NumericArray];

	img = RandomImage[];
	tensor = {1, 2, 3, 4, 5};
	na = NumericArray[{5, 4, 3, 2, 1}, "UnsignedInteger16"];
	ds = Developer`DataStore["x" -> img, "y" -> 3];

	ClearAll[TestLogSymbol];
	`LLU`Logger`PrintLogFunctionSelector := Block[{`LLU`Logger`FormattedLog = `LLU`Logger`LogToShortString},
		`LLU`Logger`PrintLogToSymbol[TestLogSymbol][##]
	]&;
];


(* Compile-time errors *)
Test[
	CCompilerDriver`CreateLibrary[{FileNameJoin[{currentDirectory, "TestSources", "PoliciesCompilationErrors.cpp"}]}, "PoliciesErrors", options]
	,
	$Failed
	,
	{CreateLibrary::cmperr..}
	,
	TestID -> "GenericContainersTestSuite-20190712-R8A2K9"
];

VerificationTest[
	OwnerAutomatic[img]
	,
	TestID -> "GenericContainersTestSuite-20190724-V1C6L5"
];

VerificationTest[
	OwnerManual[tensor]
	,
	TestID -> "GenericContainersTestSuite-20190724-V7L9Q7"
];

VerificationTest[
	OwnerShared[na]
	,
	TestID -> "GenericContainersTestSuite-20190724-D2Q7F2"
];

Test[
	CloneAutomatic[img]
	,
	img
	,
	TestID -> "GenericContainersTestSuite-20190724-L8K9W7"
];

Test[
	CloneManual[tensor]
	,
	tensor
	,
	TestID -> "GenericContainersTestSuite-20190724-H0H3Y5"
];

Test[
	CloneShared[na]
	,
	na
	,
	TestID -> "GenericContainersTestSuite-20190724-E8P2L4"
];

Test[
	MoveAutomatic[img]
	,
	img
	,
	TestID -> "GenericContainersTestSuite-20190724-H0P0K2"
];

Test[
	MoveManual[tensor]
	,
	{-324, 2, 3, 4, 5}
	,
	TestID -> "GenericContainersTestSuite-20190724-X7Z5N5"
];

Test[
	MoveShared[na]
	,
	na
	,
	TestID -> "GenericContainersTestSuite-20190724-E4T3F7"
];

Test[
	TestLogSymbol
	,
	{
		"(MoveAutomatic): Automatic arg owner: LibraryLink",
		"(MoveAutomatic): Automatic arg owner: LibraryLink, clone owner: LibraryLink",
		"(MoveAutomatic): Automatic arg owner: LibraryLink, clone owner: LibraryLink",
		"(MoveManual): Manual arg owner: Library",
		"(MoveManual): Manual arg owner: Library, clone owner: Library",
		"(MoveManual): Manual arg owner: Library, clone owner: LibraryLink",
		"(MoveShared): Shared arg owner: Shared",
		"(MoveShared): Shared arg owner: Shared, clone owner: Shared",
		"(MoveShared): Shared arg owner: Shared, clone owner: Shared"
	}
	,
	SameTest -> LoggerStringTest
	,
	TestID -> "GenericContainersTestSuite-20190906-W5T3O4"
];