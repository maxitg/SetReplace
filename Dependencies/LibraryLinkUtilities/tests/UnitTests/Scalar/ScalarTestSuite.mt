(* Wolfram Language Test file *)
TestRequirement[$VersionNumber >= 12.0];
(***************************************************************************************************************************************)
(*
	Set of test cases to test LLU functionality related to handling and exchanging scalar data types
*)
(***************************************************************************************************************************************)
TestExecute[
	Needs["CCompilerDriver`"];
	currentDirectory = DirectoryName[$TestFileName];

	(* Get configuration (path to LLU sources, compilation options, etc.) *)
	Get[FileNameJoin[{ParentDirectory[currentDirectory], "TestConfig.wl"}]];

	(* Compile the test library *)
	lib = CCompilerDriver`CreateLibrary[
		FileNameJoin[{currentDirectory, "TestSources", #}]& /@ {"Boolean.cpp", "Complex.cpp", "Integer.cpp", "Real.cpp"},
		"ScalarTest",
		options (* defined in TestConfig.wl *)
	];

	Get[FileNameJoin[{$LLUSharedDir, "LibraryLinkUtilities.wl"}]];
	`LLU`InitializePacletLibrary[lib];
];


(*
	Boolean
*)
TestExecute[
	BooleanAnd = LibraryFunctionLoad[lib, "BooleanAnd", {"Boolean", "Boolean"}, "Boolean"];
	BooleanNot = LibraryFunctionLoad[lib, "BooleanNot", {"Boolean"}, "Boolean"];
	BooleanOr = LibraryFunctionLoad[lib, "BooleanOr", {"Boolean", "Boolean"}, "Boolean"];
];

Test[
	{BooleanAnd[True, False], BooleanAnd[False, True], BooleanAnd[False, False], BooleanAnd[True, True]}
	,
	{False, False, False, True}
	,
	TestID -> "ScalarBooleanOperations-20150806-H2A7H8"
];

Test[
	{BooleanOr[True, False], BooleanOr[False, True], BooleanOr[False, False], BooleanOr[True, True]}
	,
	{True, True, False, True}
	,
	TestID -> "ScalarBooleanOperations-20150806-Q1W1V8"
];

Test[
	{BooleanNot[False], BooleanNot[True]}
	,
	{True, False}
	,
	TestID -> "ScalarBooleanOperations-20150806-U1B6I7"
];


(*
	Complex
*)
TestExecute[
	ComplexAdd = LibraryFunctionLoad[lib, "ComplexAdd", {_Complex, _Complex}, _Complex];
	ComplexTimes = LibraryFunctionLoad[lib, "ComplexTimes", {_Complex, _Complex}, _Complex];
];

Test[
	ComplexAdd[1 + 2I, 3 + 10I]
	,
	4. + 12.I
	,
	TestID -> "ScalarComplexOperations-20150806-D9W5E1"
];

Test[
	ComplexTimes[1 + 2I, 3 + 10I]
	,
	-17. + 16.I
	,
	TestID -> "ScalarComplexOperations-20150806-A5D2Q3"
];


(*
	Integer
*)
TestExecute[
	LLGet = LibraryFunctionLoad[lib, "llGet", {}, Integer];
	LLSet = LibraryFunctionLoad[lib, "llSet", {Integer}, "Void"];
	IntegerAdd = LibraryFunctionLoad[lib, "IntegerAdd", {Integer, Integer}, Integer];
	IntegerTimes = LibraryFunctionLoad[lib, "IntegerTimes", {Integer, Integer}, Integer];
	SquareInteger = LibraryFunctionLoad[lib, "SquareInteger", {Integer}, Integer];
];

ExactTest[
	LLSet[5];
	LLGet[]
	,
	5
	,
	TestID -> "ScalarIntegerOperations-20150806-M0L0V7"
];

ExactTest[
	SquareInteger[2]
	,
	4
	,
	TestID -> "ScalarIntegerOperations-20150806-F8V5U1"
];

ExactTest[
	IntegerAdd[2, 3]
	,
	5
	,
	TestID -> "ScalarIntegerOperations-20150806-D9W5E1"
];

ExactTest[
	IntegerTimes[4, 6]
	,
	24
	,
	TestID -> "ScalarIntegerOperations-20150806-A5D2Q3"
];


(*
	Real
*)
TestExecute[
	RealAdd = LibraryFunctionLoad[lib, "RealAdd", {_Real, _Real}, _Real];
	RealTimes = LibraryFunctionLoad[lib, "RealTimes", {_Real, _Real}, _Real];
];

Test[
	RealAdd[1., 2.]
	,
	3.
	,
	TestID -> "ScalarRealOperations-20150806-D9W5E1"
];

Test[
	RealTimes[4., 5.]
	,
	20.
	,
	TestID -> "ScalarRealOperations-20150806-A5D2Q3"
];