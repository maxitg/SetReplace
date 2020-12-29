(* Wolfram Language Test file *)
TestRequirement[$VersionNumber > 10.3];
(***************************************************************************************************************************************)
(*
	Set of test cases to test LLU functionality related to error reporting
*)
(***************************************************************************************************************************************)
TestExecute[
	Needs["CCompilerDriver`"];
	currentDirectory = DirectoryName[$TestFileName];

	(* Get configuration (path to LLU sources, compilation options, etc.) *)
	Get[FileNameJoin[{ParentDirectory[currentDirectory], "TestConfig.wl"}]];

	(* Compile the test library *)
	lib = CCompilerDriver`CreateLibrary[FileNameJoin[{currentDirectory, "TestSources", #}]& /@ {"ErrorReportingTest.cpp"},
		"ErrorReporting", options];

	Get[FileNameJoin[{$LLUSharedDir, "LibraryLinkUtilities.wl"}]];

	`LLU`InitializePacletLibrary[lib];
	`LLU`RegisterPacletErrors[<|
		"StaticTopLevelError" -> "This top-level error has a static error message.",
		"TopLevelNamedSlotsError" -> "Hi `name`! Error occurred `when`.",
		"TopLevelNumberedSlotsError" -> "Slot number one: `1`, number two: `2`."
	|>];

	(* Make sure the log file used in "ReadDataWithLoggingError" does not exist *)
	Quiet @ DeleteFile["LLUErrorLog.txt"];

	ResultAndLogTest[{result_, {logs_}}, {expectedRes_, {expectedLogs_}}] := MatchQ[result, expectedRes] && LoggerStringTest[logs, expectedLogs];
	ResultAndLogTest[___] := False;
];

(*********************************************************** Top-level failures **************************************************************)
Test[
	`LLU`CreatePacletFailure["NoSuchError", "MessageParameters" -> <|"X" -> 1|>]
	,
	Failure["UnknownFailure", <|
		"MessageTemplate" -> "The error `ErrorName` has not been registered.",
		"MessageParameters" -> <|"X" -> 1, "ErrorName" -> "NoSuchError"|>,
		"ErrorCode" -> 23,
		"Parameters" -> {}
	|>]
	,
	TestID -> "ErrorReportingTestSuite-20171201-L1W7O4"
];

TestMatch[
	`LLU`CreatePacletFailure["StaticTopLevelError"]
	,
	Failure["StaticTopLevelError", <|
		"MessageTemplate" -> "This top-level error has a static error message.",
		"MessageParameters" -> <||>,
		"ErrorCode" -> n_,
		"Parameters" -> {}
	|>] /; n > 7
	,
	TestID -> "ErrorReportingTestSuite-20190320-V9F7V7"
];

TestMatch[
	Catch[
		`LLU`ThrowPacletFailure["StaticTopLevelError", "MessageParameters" -> <|"X" -> 3|>, "Parameters" -> {"p1", "p2"}]
		,
		"LLUExceptionTag"
	]
	,
	Failure["StaticTopLevelError", <|
		"MessageTemplate" -> "This top-level error has a static error message.",
		"MessageParameters" -> <|"X" -> 3|>,
		"ErrorCode" -> n_?TopLevelErrorCodeQ,
		"Parameters" -> {"p1", "p2"}
	|>]
	,
	TestID -> "ErrorReportingTestSuite-20190320-C8I1M4"
];

TestMatch[
	Block[{`LLU`$ExceptionTagFunction = First},
		Catch[
			`LLU`ThrowPacletFailure["StaticTopLevelError", "MessageParameters" -> "Must be Association or List", "Parameters" -> {1, 2}]
			,
			_String?(StringEndsQ["Error"])
		]
	]
	,
	Failure["StaticTopLevelError", <|
		"MessageTemplate" -> "This top-level error has a static error message.",
		"MessageParameters" -> <||>,
		"ErrorCode" -> n_?TopLevelErrorCodeQ,
		"Parameters" -> {}
	|>]
	,
	TestID -> "ErrorReportingTestSuite-20190320-N4O5P9"
];

TestMatch[
	`LLU`CreatePacletFailure["TopLevelNamedSlotsError", "MessageParameters" -> <|"name" -> "John", "when" -> ToString[Now], "unused" -> "param"|>]
	,
	Failure["TopLevelNamedSlotsError", <|
		"MessageTemplate" -> "Hi `name`! Error occurred `when`.",
		"MessageParameters" -> <|"name" -> "John", "when" -> _String, "unused" -> "param"|>,
		"ErrorCode" -> n_?TopLevelErrorCodeQ,
		"Parameters" -> {}
	|>]
	,
	TestID -> "ErrorReportingTestSuite-20190320-D1Q8T7"
];

TestMatch[
	Catch[
		`LLU`ThrowPacletFailure["TopLevelNumberedSlotsError", MyTag[17], "MessageParameters" -> {"x", "y", "z"}]
		,
		_MyTag
	]
	,
	Failure["TopLevelNumberedSlotsError", <|
		"MessageTemplate" -> "Slot number one: `1`, number two: `2`.",
		"MessageParameters" -> {"x", "y", "z"},
		"ErrorCode" -> n_?TopLevelErrorCodeQ,
		"Parameters" -> {}
	|>]
	,
	TestID -> "ErrorReportingTestSuite-20190320-Z5Q7P0"
];

TestMatch[
	Catch[`LLU`SafeLibraryLoad["NoSuchLibrary"], _]
	,
	Failure["LibraryLoadFailure", <|
		"MessageTemplate" -> "Failed to load library `LibraryName`. Details: `Details`.",
		"MessageParameters" -> <|"LibraryName" -> "NoSuchLibrary", "Details" -> "None"|>,
		"ErrorCode" -> n_?TopLevelErrorCodeQ,
		"Parameters" -> {}
	|>]
	,
	TestID->"ErrorReportingTestSuite-20200806-B1S9L6"
];


TestMatch[
	Off[LibraryFunction::notfound];
	Catch[`LLU`SafeLibraryLoad["NoSuchLibrary"], _]
	,
	Failure["LibraryLoadFailure", <|
		"MessageTemplate" -> "Failed to load library `LibraryName`. Details: `Details`.",
		"MessageParameters" -> <|"LibraryName" -> "NoSuchLibrary", "Details" -> "None"|>,
		"ErrorCode" -> n_?TopLevelErrorCodeQ,
		"Parameters" -> {}
	|>]
	,
	TestID->"ErrorReportingTestSuite-20200806-P5A5X1"
];

TestExecute[
	On[LibraryFunction::notfound]
];

TestMatch[
	Catch[`LLU`Private`SafeLibraryFunctionLoad["demo", "NoSuchFunction", {}, "Void"], _]
	,
	Failure["FunctionLoadFailure", <|
		"MessageTemplate" -> "Failed to load the function `FunctionName` from `LibraryName`. Details: `Details`.",
		"MessageParameters" -> <|"FunctionName" -> "NoSuchFunction", "LibraryName" -> "demo", "Details" -> _?StringQ|>,
		"ErrorCode" -> n_?TopLevelErrorCodeQ,
		"Parameters" -> {}
	|>]
	,
	TestID->"ErrorReportingTestSuite-20200806-Z5P4V4"
];


TestMatch[
	Off[LibraryFunction::libload];
	Catch[`LLU`Private`SafeLibraryFunctionLoad["demo", "NoSuchFunction", {}, "Void"], _]
	,
	Failure["FunctionLoadFailure", <|
		"MessageTemplate" -> "Failed to load the function `FunctionName` from `LibraryName`. Details: `Details`.",
		"MessageParameters" -> <|"FunctionName" -> "NoSuchFunction", "LibraryName" -> "demo", "Details" -> _?StringQ|>,
		"ErrorCode" -> n_?TopLevelErrorCodeQ,
		"Parameters" -> {}
	|>]
	,
	TestID->"ErrorReportingTestSuite-20200806-T4V9V1"
];

TestExecute[
	On[LibraryFunction::libload]
];

VerificationTest[
	Catch[
		f1 = `LLU`Private`SafeLibraryFunctionLoad["demo", "demo_I_I", {Integer}, Integer];
		f2 = `LLU`Private`SafeLibraryFunctionLoad["demo", "demo_I_I", {Real}, Integer]
		,
		_
	];
	MatchQ[f1, _LibraryFunction] && MatchQ[f2, _LibraryFunction]
	,
	TestID->"ErrorReportingTestSuite-20200806-P9M9F4"
];

(*********************************************************** C++ code failures **************************************************************)

TestMatch[
	`LLU`PacletFunctionSet[$ReadData, {String}, "Void"];
	Flatten @ {FreeQ[OwnValues @ $ReadData, _LibraryFunction], 
		Catch[
			{$ReadData["test.txt"], "NoCatch"}
			,
			"LLUExceptionTag"
		]
	}
	,
	{False, Failure["DataFileError", ___]}
	,
	TestID -> "ErrorReportingTestSuite-20200713-125282"
];

TestMatch[
	`LLU`PacletFunctionSet[$ReadData, "ReadData", {String}, "Void"];
	Flatten @ {FreeQ[OwnValues @ $ReadData, _LibraryFunction], 
		Catch[
			{$ReadData["test.txt"], "NoCatch"}
			,
			"LLUExceptionTag"
		]
	}
	,
	{False, Failure["DataFileError", ___]}
	,
	TestID -> "ErrorReportingTestSuite-20200713-6F42A8"
];

TestMatch[
	`LLU`PacletFunctionSet[$ReadData, lib, "ReadData", {String}, "Void"];
	Flatten @ {FreeQ[OwnValues @ $ReadData, _LibraryFunction], 
		Catch[
			{$ReadData["test.txt"], "NoCatch"}
			,
			"LLUExceptionTag"
		]
	}
	,
	{False, Failure["DataFileError", ___]}
	,
	TestID -> "ErrorReportingTestSuite-20200713-6F4461"
];

TestMatch[
	`LLU`PacletFunctionSet[$ReadData, {String}, "Void", "Throws" -> False];
	Flatten @ {FreeQ[OwnValues @ $ReadData, _LibraryFunction], 
		Catch[
			{$ReadData["test.txt"], "NoCatch"}
			,
			"LLUExceptionTag"
		]
	}
	,
	{False, Failure["DataFileError", ___], "NoCatch"}
	,
	TestID -> "ErrorReportingTestSuite-20200713-B663B5"
];

TestMatch[
	`LLU`PacletFunctionSet[$ReadData, "ReadData", {String}, "Void", "Throws" -> False];
	Flatten @ {FreeQ[OwnValues @ $ReadData, _LibraryFunction], 
		Catch[
			{$ReadData["test.txt"], "NoCatch"}
			,
			"LLUExceptionTag"
		]
	}
	,
	{False, Failure["DataFileError", ___], "NoCatch"}
	,
	TestID -> "ErrorReportingTestSuite-20200713-F84E10"
];

TestMatch[
	`LLU`PacletFunctionSet[$ReadData, lib, "ReadData", {String}, "Void", "Throws" -> False];
	Flatten @ {FreeQ[OwnValues @ $ReadData, _LibraryFunction], 
		Catch[
			{$ReadData["test.txt"], "NoCatch"}
			,
			"LLUExceptionTag"
		]
	}
	,
	{False, Failure["DataFileError", ___], "NoCatch"}
	,
	TestID -> "ErrorReportingTestSuite-20200713-4E8804"
];

TestMatch[
	`LLU`WSTPFunctionSet[$testFunctionWSTP];
	Flatten @ {FreeQ[OwnValues @ $testFunctionWSTP, _LibraryFunction], 
		Catch[
			{$testFunctionWSTP[], "NoCatch"}
			,
			"LLUExceptionTag"
		]
	}
	,
	{False, Failure["SimpleError", ___]}
	,
	TestID -> "ErrorReportingTestSuite-20200713-D70EA4"
];

TestMatch[
	`LLU`WSTPFunctionSet[$testFunctionWSTP, "testFunctionWSTP"];
	Flatten @ {FreeQ[OwnValues @ $testFunctionWSTP, _LibraryFunction], 
		Catch[
			{$testFunctionWSTP[], "NoCatch"}
			,
			"LLUExceptionTag"
		]
	}
	,
	{False, Failure["SimpleError", ___]}
	,
	TestID -> "ErrorReportingTestSuite-20200713-AFC0F3"
];

TestMatch[
	`LLU`WSTPFunctionSet[$testFunctionWSTP, lib, "testFunctionWSTP"];
	Flatten @ {FreeQ[OwnValues @ $testFunctionWSTP, _LibraryFunction], 
		Catch[
			{$testFunctionWSTP[], "NoCatch"}
			,
			"LLUExceptionTag"
		]
	}
	,
	{False, Failure["SimpleError", ___]}
	,
	TestID -> "ErrorReportingTestSuite-20200713-6FD0F0"
];

TestMatch[
	`LLU`WSTPFunctionSet[$testFunctionWSTP, "Throws" -> False];
	Flatten @ {FreeQ[OwnValues @ $testFunctionWSTP, _LibraryFunction], 
		Catch[
			{$testFunctionWSTP[], "NoCatch"}
			,
			"LLUExceptionTag"
		]
	}
	,
	{False, Failure["SimpleError", ___], "NoCatch"}
	,
	TestID -> "ErrorReportingTestSuite-20200713-F156F5"
];

TestMatch[
	`LLU`WSTPFunctionSet[$testFunctionWSTP, "testFunctionWSTP", "Throws" -> False];
	Flatten @ {FreeQ[OwnValues @ $testFunctionWSTP, _LibraryFunction], 
		Catch[
			{$testFunctionWSTP[], "NoCatch"}
			,
			"LLUExceptionTag"
		]
	}
	,
	{False, Failure["SimpleError", ___], "NoCatch"}
	,
	TestID -> "ErrorReportingTestSuite-20200713-7162C9"
];

TestMatch[
	`LLU`WSTPFunctionSet[$testFunctionWSTP, lib, "testFunctionWSTP", "Throws" -> False];
	Flatten @ {FreeQ[OwnValues @ $testFunctionWSTP, _LibraryFunction], 
		Catch[
			{$testFunctionWSTP[], "NoCatch"}
			,
			"LLUExceptionTag"
		]
	}
	,
	{False, Failure["SimpleError", ___], "NoCatch"}
	,
	TestID -> "ErrorReportingTestSuite-20200713-A24463"
];

TestMatch[
	`LLU`LazyPacletFunctionSet[$ReadData, {String}, "Void"];
	Flatten @ {FreeQ[OwnValues @ $ReadData, _LibraryFunction], 
		Catch[
			{$ReadData["test.txt"], "NoCatch"}
			,
			"LLUExceptionTag"
		]
	}
	,
	{True, Failure["DataFileError", ___]}
	,
	TestID -> "ErrorReportingTestSuite-20200713-7C1AD4"
];

TestMatch[
	`LLU`LazyPacletFunctionSet[$ReadData, "ReadData", {String}, "Void"];
	Flatten @ {FreeQ[OwnValues @ $ReadData, _LibraryFunction], 
		Catch[
			{$ReadData["test.txt"], "NoCatch"}
			,
			"LLUExceptionTag"
		]
	}
	,
	{True, Failure["DataFileError", ___]}
	,
	TestID -> "ErrorReportingTestSuite-20200713-5E02EC"
];

TestMatch[
	`LLU`LazyPacletFunctionSet[$ReadData, lib, "ReadData", {String}, "Void"];
	Flatten @ {FreeQ[OwnValues @ $ReadData, _LibraryFunction], 
		Catch[
			{$ReadData["test.txt"], "NoCatch"}
			,
			"LLUExceptionTag"
		]
	}
	,
	{True, Failure["DataFileError", ___]}
	,
	TestID -> "ErrorReportingTestSuite-20200713-016035"
];

TestMatch[
	`LLU`LazyPacletFunctionSet[$ReadData, {String}, "Void", "Throws" -> False];
	Flatten @ {FreeQ[OwnValues @ $ReadData, _LibraryFunction], 
		Catch[
			{$ReadData["test.txt"], "NoCatch"}
			,
			"LLUExceptionTag"
		]
	}
	,
	{True, Failure["DataFileError", ___], "NoCatch"}
	,
	TestID -> "ErrorReportingTestSuite-20200713-AFF54B"
];

TestMatch[
	`LLU`LazyPacletFunctionSet[$ReadData, "ReadData", {String}, "Void", "Throws" -> False];
	Flatten @ {FreeQ[OwnValues @ $ReadData, _LibraryFunction], 
		Catch[
			{$ReadData["test.txt"], "NoCatch"}
			,
			"LLUExceptionTag"
		]
	}
	,
	{True, Failure["DataFileError", ___], "NoCatch"}
	,
	TestID -> "ErrorReportingTestSuite-20200713-9D4498"
];

TestMatch[
	`LLU`LazyPacletFunctionSet[$ReadData, lib, "ReadData", {String}, "Void", "Throws" -> False];
	Flatten @ {FreeQ[OwnValues @ $ReadData, _LibraryFunction], 
		Catch[
			{$ReadData["test.txt"], "NoCatch"}
			,
			"LLUExceptionTag"
		]
	}
	,
	{True, Failure["DataFileError", ___], "NoCatch"}
	,
	TestID -> "ErrorReportingTestSuite-20200713-6C8AE9"
];

TestMatch[
	`LLU`LazyWSTPFunctionSet[$testFunctionWSTP];
	Flatten @ {FreeQ[OwnValues @ $testFunctionWSTP, _LibraryFunction],
		Catch[
			{$testFunctionWSTP[], "NoCatch"}
			,
			"LLUExceptionTag"
		]
	}
	,
	{True, Failure["SimpleError", ___]}
	,
	TestID -> "ErrorReportingTestSuite-20200713-A0E9A0"
];

TestMatch[
	`LLU`LazyWSTPFunctionSet[$testFunctionWSTP, "testFunctionWSTP"];
	Flatten @ {FreeQ[OwnValues @ $testFunctionWSTP, _LibraryFunction],
		Catch[
			{$testFunctionWSTP[], "NoCatch"}
			,
			"LLUExceptionTag"
		]
	}
	,
	{True, Failure["SimpleError", ___]}
	,
	TestID -> "ErrorReportingTestSuite-20200713-189E64"
];

TestMatch[
	`LLU`LazyWSTPFunctionSet[$testFunctionWSTP, lib, "testFunctionWSTP"];
	Flatten @ {FreeQ[OwnValues @ $testFunctionWSTP, _LibraryFunction],
		Catch[
			{$testFunctionWSTP[], "NoCatch"}
			,
			"LLUExceptionTag"
		]
	}
	,
	{True, Failure["SimpleError", ___]}
	,
	TestID -> "ErrorReportingTestSuite-20200713-283EE8"
];

TestMatch[
	`LLU`LazyWSTPFunctionSet[$testFunctionWSTP, "Throws" -> False];
	Flatten @ {FreeQ[OwnValues @ $testFunctionWSTP, _LibraryFunction],
		Catch[
			{$testFunctionWSTP[], "NoCatch"}
			,
			"LLUExceptionTag"
		]
	}
	,
	{True, Failure["SimpleError", ___], "NoCatch"}
	,
	TestID -> "ErrorReportingTestSuite-20200713-D31B04"
];

TestMatch[
	`LLU`LazyWSTPFunctionSet[$testFunctionWSTP, "testFunctionWSTP", "Throws" -> False];
	Flatten @ {FreeQ[OwnValues @ $testFunctionWSTP, _LibraryFunction],
		Catch[
			{$testFunctionWSTP[], "NoCatch"}
			,
			"LLUExceptionTag"
		]
	}
	,
	{True, Failure["SimpleError", ___], "NoCatch"}
	,
	TestID -> "ErrorReportingTestSuite-20200713-58379C"
];

TestMatch[
	`LLU`LazyWSTPFunctionSet[$testFunctionWSTP, lib, "testFunctionWSTP", "Throws" -> False];
	Flatten @ {FreeQ[OwnValues @ $testFunctionWSTP, _LibraryFunction],
		Catch[
			{$testFunctionWSTP[], "NoCatch"}
			,
			"LLUExceptionTag"
		]
	}
	,
	{True, Failure["SimpleError", ___], "NoCatch"}
	,
	TestID -> "ErrorReportingTestSuite-20200713-DE4796"
];

TestExecute[
	`LLU`Constructor[MyTestExpression] = `LLU`MemberFunctionSet[OpenManagedMyTestExpression, {`LLU`Managed[MyTestExpression]}, "Void"];
	myExpr = `LLU`NewManagedExpression[MyTestExpression][];
];

TestMatch[
	`LLU`MemberFunctionSet[MyTestExpression][$GetMLEError, {}, "Void"];
	Flatten @ {FreeQ[OwnValues @ MyTestExpression`$GetMLEError, _LibraryFunction],
		Catch[
			{myExpr @ $GetMLEError[], "NoCatch"}
			,
			"LLUExceptionTag"
		]
	}
	,
	{False, Failure["SimpleError", ___]}
	,
	TestID -> "ErrorReportingTestSuite-20200713-6B4657"
];

TestMatch[
	`LLU`MemberFunctionSet[MyTestExpression][$GetMLEError, "GetMLEError", {}, "Void"];
	Flatten @ {FreeQ[OwnValues @ MyTestExpression`$GetMLEError, _LibraryFunction],
		Catch[
			{myExpr @ $GetMLEError[], "NoCatch"}
			,
			"LLUExceptionTag"
		]
	}
	,
	{False, Failure["SimpleError", ___]}
	,
	TestID -> "ErrorReportingTestSuite-20200713-B378C7"
];

TestMatch[
	`LLU`MemberFunctionSet[MyTestExpression][$GetMLEError, lib, "GetMLEError", {}, "Void"];
	Flatten @ {FreeQ[OwnValues @ MyTestExpression`$GetMLEError, _LibraryFunction],
		Catch[
			{myExpr @ $GetMLEError[], "NoCatch"}
			,
			"LLUExceptionTag"
		]
	}
	,
	{False, Failure["SimpleError", ___]}
	,
	TestID -> "ErrorReportingTestSuite-20200713-4DE4ED"
];

TestMatch[
	`LLU`MemberFunctionSet[MyTestExpression][$GetMLEError, {}, "Void", "Throws" -> False];
	Flatten @ {FreeQ[OwnValues @ MyTestExpression`$GetMLEError, _LibraryFunction],
		Catch[
			{myExpr @ $GetMLEError[], "NoCatch"}
			,
			"LLUExceptionTag"
		]
	}
	,
	{False, Failure["SimpleError", ___], "NoCatch"}
	,
	TestID -> "ErrorReportingTestSuite-20200713-BECA91"
];

TestMatch[
	`LLU`MemberFunctionSet[MyTestExpression][$GetMLEError, "GetMLEError", {}, "Void", "Throws" -> False];
	Flatten @ {FreeQ[OwnValues @ MyTestExpression`$GetMLEError, _LibraryFunction],
		Catch[
			{myExpr @ $GetMLEError[], "NoCatch"}
			,
			"LLUExceptionTag"
		]
	}
	,
	{False, Failure["SimpleError", ___], "NoCatch"}
	,
	TestID -> "ErrorReportingTestSuite-20200713-9D730A"
];

TestMatch[
	`LLU`MemberFunctionSet[MyTestExpression][$GetMLEError, lib, "GetMLEError", {}, "Void", "Throws" -> False];
	Flatten @ {FreeQ[OwnValues @ MyTestExpression`$GetMLEError, _LibraryFunction],
		Catch[
			{myExpr @ $GetMLEError[], "NoCatch"}
			,
			"LLUExceptionTag"
		]
	}
	,
	{False, Failure["SimpleError", ___], "NoCatch"}
	,
	TestID -> "ErrorReportingTestSuite-20200713-90377C"
];

TestMatch[
	`LLU`WSTPMemberFunctionSet[MyTestExpression][$GetMLEErrorWSTP];
	Flatten @ {FreeQ[OwnValues @ MyTestExpression`$GetMLEErrorWSTP, _LibraryFunction],
		Catch[
			{myExpr @ $GetMLEErrorWSTP[], "NoCatch"}
			,
			"LLUExceptionTag"
		]
	}
	,
	{False, Failure["SimpleError", ___]}
	,
	TestID -> "ErrorReportingTestSuite-20200713-0D6812"
];

TestMatch[
	`LLU`WSTPMemberFunctionSet[MyTestExpression][$GetMLEErrorWSTP, "GetMLEErrorWSTP"];
	Flatten @ {FreeQ[OwnValues @ MyTestExpression`$GetMLEErrorWSTP, _LibraryFunction],
		Catch[
			{myExpr @ $GetMLEErrorWSTP[], "NoCatch"}
			,
			"LLUExceptionTag"
		]
	}
	,
	{False, Failure["SimpleError", ___]}
	,
	TestID -> "ErrorReportingTestSuite-20200713-50F2C4"
];

TestMatch[
	`LLU`WSTPMemberFunctionSet[MyTestExpression][$GetMLEErrorWSTP, lib, "GetMLEErrorWSTP"];
	Flatten @ {FreeQ[OwnValues @ MyTestExpression`$GetMLEErrorWSTP, _LibraryFunction],
		Catch[
			{myExpr @ $GetMLEErrorWSTP[], "NoCatch"}
			,
			"LLUExceptionTag"
		]
	}
	,
	{False, Failure["SimpleError", ___]}
	,
	TestID -> "ErrorReportingTestSuite-20200713-02630F"
];

TestMatch[
	`LLU`WSTPMemberFunctionSet[MyTestExpression][$GetMLEErrorWSTP, "Throws" -> False];
	Flatten @ {FreeQ[OwnValues @ MyTestExpression`$GetMLEErrorWSTP, _LibraryFunction],
		Catch[
			{myExpr @ $GetMLEErrorWSTP[], "NoCatch"}
			,
			"LLUExceptionTag"
		]
	}
	,
	{False, Failure["SimpleError", ___], "NoCatch"}
	,
	TestID -> "ErrorReportingTestSuite-20200713-26CCC9"
];

TestMatch[
	`LLU`WSTPMemberFunctionSet[MyTestExpression][$GetMLEErrorWSTP, "GetMLEErrorWSTP", "Throws" -> False];
	Flatten @ {FreeQ[OwnValues @ MyTestExpression`$GetMLEErrorWSTP, _LibraryFunction],
		Catch[
			{myExpr @ $GetMLEErrorWSTP[], "NoCatch"}
			,
			"LLUExceptionTag"
		]
	}
	,
	{False, Failure["SimpleError", ___], "NoCatch"}
	,
	TestID -> "ErrorReportingTestSuite-20200713-4A76E1"
];

TestMatch[
	`LLU`WSTPMemberFunctionSet[MyTestExpression][$GetMLEErrorWSTP, lib, "GetMLEErrorWSTP", "Throws" -> False];
	Flatten @ {FreeQ[OwnValues @ MyTestExpression`$GetMLEErrorWSTP, _LibraryFunction],
		Catch[
			{myExpr @ $GetMLEErrorWSTP[], "NoCatch"}
			,
			"LLUExceptionTag"
		]
	}
	,
	{False, Failure["SimpleError", ___], "NoCatch"}
	,
	TestID -> "ErrorReportingTestSuite-20200713-056AC9"
];

TestMatch[
	`LLU`LazyMemberFunctionSet[MyTestExpression][$GetMLEError, {}, "Void"];
	Flatten @ {FreeQ[OwnValues @ MyTestExpression`$GetMLEError, _LibraryFunction],
		Catch[
			{myExpr @ $GetMLEError[], "NoCatch"}
			,
			"LLUExceptionTag"
		]
	}
	,
	{True, Failure["SimpleError", ___]}
	,
	TestID -> "ErrorReportingTestSuite-20200713-12A4F6"
];

TestMatch[
	`LLU`LazyMemberFunctionSet[MyTestExpression][$GetMLEError, "GetMLEError", {}, "Void"];
	Flatten @ {FreeQ[OwnValues @ MyTestExpression`$GetMLEError, _LibraryFunction],
		Catch[
			{myExpr @ $GetMLEError[], "NoCatch"}
			,
			"LLUExceptionTag"
		]
	}
	,
	{True, Failure["SimpleError", ___]}
	,
	TestID -> "ErrorReportingTestSuite-20200713-EAE3F7"
];

TestMatch[
	`LLU`LazyMemberFunctionSet[MyTestExpression][$GetMLEError, lib, "GetMLEError", {}, "Void"];
	Flatten @ {FreeQ[OwnValues @ MyTestExpression`$GetMLEError, _LibraryFunction],
		Catch[
			{myExpr @ $GetMLEError[], "NoCatch"}
			,
			"LLUExceptionTag"
		]
	}
	,
	{True, Failure["SimpleError", ___]}
	,
	TestID -> "ErrorReportingTestSuite-20200713-751A06"
];

TestMatch[
	`LLU`LazyMemberFunctionSet[MyTestExpression][$GetMLEError, {}, "Void", "Throws" -> False];
	Flatten @ {FreeQ[OwnValues @ MyTestExpression`$GetMLEError, _LibraryFunction],
		Catch[
			{myExpr @ $GetMLEError[], "NoCatch"}
			,
			"LLUExceptionTag"
		]
	}
	,
	{True, Failure["SimpleError", ___], "NoCatch"}
	,
	TestID -> "ErrorReportingTestSuite-20200713-47DDCC"
];

TestMatch[
	`LLU`LazyMemberFunctionSet[MyTestExpression][$GetMLEError, "GetMLEError", {}, "Void", "Throws" -> False];
	Flatten @ {FreeQ[OwnValues @ MyTestExpression`$GetMLEError, _LibraryFunction],
		Catch[
			{myExpr @ $GetMLEError[], "NoCatch"}
			,
			"LLUExceptionTag"
		]
	}
	,
	{True, Failure["SimpleError", ___], "NoCatch"}
	,
	TestID -> "ErrorReportingTestSuite-20200713-E0AAF5"
];

TestMatch[
	`LLU`LazyMemberFunctionSet[MyTestExpression][$GetMLEError, lib, "GetMLEError", {}, "Void", "Throws" -> False];
	Flatten @ {FreeQ[OwnValues @ MyTestExpression`$GetMLEError, _LibraryFunction],
		Catch[
			{myExpr @ $GetMLEError[], "NoCatch"}
			,
			"LLUExceptionTag"
		]
	}
	,
	{True, Failure["SimpleError", ___], "NoCatch"}
	,
	TestID -> "ErrorReportingTestSuite-20200713-9709E0"
];

TestMatch[
	`LLU`LazyWSTPMemberFunctionSet[MyTestExpression][$GetMLEErrorWSTP];
	Flatten @ {FreeQ[OwnValues @ MyTestExpression`$GetMLEErrorWSTP, _LibraryFunction],
		Catch[
			{myExpr @ $GetMLEErrorWSTP[], "NoCatch"}
			,
			"LLUExceptionTag"
		]
	}
	,
	{True, Failure["SimpleError", ___]}
	,
	TestID -> "ErrorReportingTestSuite-20200713-774159"
];

TestMatch[
	`LLU`LazyWSTPMemberFunctionSet[MyTestExpression][$GetMLEErrorWSTP, "GetMLEErrorWSTP"];
	Flatten @ {FreeQ[OwnValues @ MyTestExpression`$GetMLEErrorWSTP, _LibraryFunction],
		Catch[
			{myExpr @ $GetMLEErrorWSTP[], "NoCatch"}
			,
			"LLUExceptionTag"
		]
	}
	,
	{True, Failure["SimpleError", ___]}
	,
	TestID -> "ErrorReportingTestSuite-20200713-6174BE"
];

TestMatch[
	`LLU`LazyWSTPMemberFunctionSet[MyTestExpression][$GetMLEErrorWSTP, lib, "GetMLEErrorWSTP"];
	Flatten @ {FreeQ[OwnValues @ MyTestExpression`$GetMLEErrorWSTP, _LibraryFunction],
		Catch[
			{myExpr @ $GetMLEErrorWSTP[], "NoCatch"}
			,
			"LLUExceptionTag"
		]
	}
	,
	{True, Failure["SimpleError", ___]}
	,
	TestID -> "ErrorReportingTestSuite-20200713-7A511A"
];

TestMatch[
	`LLU`LazyWSTPMemberFunctionSet[MyTestExpression][$GetMLEErrorWSTP, "Throws" -> False];
	Flatten @ {FreeQ[OwnValues @ MyTestExpression`$GetMLEErrorWSTP, _LibraryFunction],
		Catch[
			{myExpr @ $GetMLEErrorWSTP[], "NoCatch"}
			,
			"LLUExceptionTag"
		]
	}
	,
	{True, Failure["SimpleError", ___], "NoCatch"}
	,
	TestID -> "ErrorReportingTestSuite-20200713-311D22"
];

TestMatch[
	`LLU`LazyWSTPMemberFunctionSet[MyTestExpression][$GetMLEErrorWSTP, "GetMLEErrorWSTP", "Throws" -> False];
	Flatten @ {FreeQ[OwnValues @ MyTestExpression`$GetMLEErrorWSTP, _LibraryFunction],
		Catch[
			{myExpr @ $GetMLEErrorWSTP[], "NoCatch"}
			,
			"LLUExceptionTag"
		]
	}
	,
	{True, Failure["SimpleError", ___], "NoCatch"}
	,
	TestID -> "ErrorReportingTestSuite-20200713-572E96"
];

TestMatch[
	`LLU`LazyWSTPMemberFunctionSet[MyTestExpression][$GetMLEErrorWSTP, lib, "GetMLEErrorWSTP", "Throws" -> False];
	Flatten @ {FreeQ[OwnValues @ MyTestExpression`$GetMLEErrorWSTP, _LibraryFunction],
		Catch[
			{myExpr @ $GetMLEErrorWSTP[], "NoCatch"}
			,
			"LLUExceptionTag"
		]
	}
	,
	{True, Failure["SimpleError", ___], "NoCatch"}
	,
	TestID -> "ErrorReportingTestSuite-20200713-E3946E"
];

TestMatch[
	ReadData = `LLU`PacletFunctionLoad["ReadData", {String}, "Void", "Throws" -> False];
	ReadData["test.txt"]
	,
	Failure["DataFileError", <|
		"MessageTemplate" -> "Data in file `fname` in line `lineNumber` is invalid because `reason`.",
		"MessageParameters" -> <|"fname" -> "test.txt", "lineNumber" -> 8, "reason" -> "data type is not supported"|>,
		"ErrorCode" -> n_?CppErrorCodeQ,
		"Parameters" -> {}
	|>]
	,
	TestID -> "ErrorReportingTestSuite-20190320-Z5Q2A7"
];

TestMatch[
	ReadData["somefile.txt"]
	,
	Failure["DataFileError", <|
		"MessageTemplate" -> "Data in file `fname` in line `lineNumber` is invalid because `reason`.",
		"MessageParameters" -> <|"fname" -> "somefile.txt", "lineNumber" -> 12, "reason" -> "data type is not supported"|>,
		"ErrorCode" -> n_?CppErrorCodeQ,
		"Parameters" -> {}
	|>]
	,
	TestID -> "ErrorReportingTestSuite-20190320-W3B2B3"
];

TestMatch[
	ReadData2 = `LLU`PacletFunctionLoad["ReadDataLocalWLD", {String}, "Void", "Throws" -> False];
	ReadData2["test.txt"]
	,
	Failure["DataFileError", <|
		"MessageTemplate" -> "Data in file `fname` in line `lineNumber` is invalid because `reason`.",
		"MessageParameters" -> <|"fname" -> "test.txt", "lineNumber" -> 8, "reason" -> "data type is not supported"|>,
		"ErrorCode" -> n_?CppErrorCodeQ,
		"Parameters" -> {}
	|>]
	,
	TestID -> "ErrorReportingTestSuite-20190320-V5I1S9"
];

TestMatch[
	ReadData2["somefile.txt"]
	,
	Failure["DataFileError", <|
		"MessageTemplate" -> "Data in file `fname` in line `lineNumber` is invalid because `reason`.",
		"MessageParameters" -> <|"fname" -> "somefile.txt", "lineNumber" -> 12, "reason" -> "data type is not supported"|>,
		"ErrorCode" -> n_?CppErrorCodeQ,
		"Parameters" -> {}
	|>]
	,
	TestID -> "ErrorReportingTestSuite-20190320-A4B7N1"
];

TestMatch[
	`LLU`PacletFunctionSet[RepeatedTemplate, {}, "Void", "Throws" -> False];
	RepeatedTemplate[]
	,
	Failure["RepeatedTemplateError", <|
		"MessageTemplate" -> "Cannot accept `x` nor `y` because `x` is unacceptable. So are `y` and `z`.",
		"MessageParameters" -> <|"x" -> "x", "y" -> "y", "z" -> "z"|>,
		"ErrorCode" -> n_?CppErrorCodeQ,
		"Parameters" -> {}
	|>]
	,
	TestID -> "ErrorReportingTestSuite-20190320-G2N3F5"
];

TestMatch[
	Block[{`LLU`$Throws = False},
		`LLU`PacletFunctionSet[NumberedSlots, {}, "Void"];
	];
	NumberedSlots[]
	,
	Failure["NumberedSlotsError", <|
		"MessageTemplate" -> "First slot is `1` and second is `2`.",
		"MessageParameters" -> {1, {"2", "3", "4"}},
		"ErrorCode" -> n_?CppErrorCodeQ,
		"Parameters" -> {}
	|>]
	,
	TestID -> "ErrorReportingTestSuite-20190320-N1J5Q8"
];

TestMatch[
	`LLU`PacletFunctionSet[RepeatedNumberTemplate, {}, "Void"];
	Catch[RepeatedNumberTemplate[], "LLUExceptionTag"]
	,
	Failure["RepeatedNumberTemplateError", <|
		"MessageTemplate" -> "Cannot accept `` nor `` because `1` is unacceptable. So are `2` and ``.",
		"MessageParameters" -> {"x", "y", "z"},
		"ErrorCode" -> n_?CppErrorCodeQ,
		"Parameters" -> {}
	|>]
	,
	TestID -> "ErrorReportingTestSuite-20190320-R9L9R5"
];

TestMatch[
	Block[{`LLU`$ExceptionTagString = "MyException"},
		Catch[RepeatedNumberTemplate[], "MyException"]
	]
	,
	Failure["RepeatedNumberTemplateError", <|
		"MessageTemplate" -> "Cannot accept `` nor `` because `1` is unacceptable. So are `2` and ``.",
		"MessageParameters" -> {"x", "y", "z"},
		"ErrorCode" -> n_?CppErrorCodeQ,
		"Parameters" -> {}
	|>]
	,
	TestID -> "ErrorReportingTestSuite-20200806-E5S2B6"
];

TestExecute[
	`LLU`$Throws = False;
];

TestMatch[
	TooManyValues = `LLU`PacletFunctionLoad["TooManyValues", {}, "Void"];
	TooManyValues[]
	,
	Failure["NumberedSlotsError", <|
		"MessageTemplate" -> "First slot is `1` and second is `2`.",
		"MessageParameters" -> {1, 2, 3, 4, 5},
		"ErrorCode" -> n_?CppErrorCodeQ,
		"Parameters" -> {}
	|>]
	,
	TestID -> "ErrorReportingTestSuite-20190320-A9U4T2"
];

TestMatch[
	TooFewValues = `LLU`PacletFunctionLoad["TooFewValues", {}, "Void"];
	TooFewValues[]
	,
	Failure["NumberedSlotsError", <|
		"MessageTemplate" -> "First slot is `1` and second is `2`.",
		"MessageParameters" -> {},
		"ErrorCode" -> n_?CppErrorCodeQ,
		"Parameters" -> {}
	|>]
	,
	TestID -> "ErrorReportingTestSuite-20190320-R0E3G0"
];

TestMatch[
	MixedSlots = `LLU`PacletFunctionLoad["MixedSlots", {}, "Void"];
	MixedSlots[]
	,
	Failure["MixedSlotsError", <|
		"MessageTemplate" -> "This message `` mixes `2` different `kinds` of `` slots.",
		"MessageParameters" -> {1, 2, <|"kinds" -> 3|>, 4},
		"ErrorCode" -> n_?CppErrorCodeQ,
		"Parameters" -> {}
	|>]
	,
	TestID -> "ErrorReportingTestSuite-20190320-C0V5L0"
];

TestExecute[
	`LLU`$Throws = True;
];

(* Unit tests of ErrorManager::throwCustomException *)

TestMatch[
	ReadDataWithLoggingError = `LLU`PacletFunctionLoad["ReadDataWithLoggingError", {String}, "Void"];
	Catch[ReadDataWithLoggingError["test.txt"], _]
	,
	Failure["DataFileError", <|
		"MessageTemplate" -> "Data in file `fname` in line `lineNumber` is invalid because `reason`.",
		"MessageParameters" -> <|"fname" -> "test.txt", "lineNumber" -> 8, "reason" -> "data type is not supported"|>,
		"ErrorCode" -> n_?CppErrorCodeQ,
		"Parameters" -> {}
	|>]
	,
	TestID -> "ErrorReportingTestSuite-20190404-F2M3A2"
];

TestMatch[
	Catch[ReadDataWithLoggingError["ThisFileHasExtremelyLongName.txt"], _String?(StringMatchQ["LLU*"])]
	,
	Failure["DataFileError", <|
		"MessageTemplate" -> "Data in file `fname` in line `lineNumber` is invalid because `reason`.",
		"MessageParameters" -> <|"fname" -> "ThisFileHasExtremelyLongName.txt", "lineNumber" -> 32, "reason" -> "file name is too long"|>,
		"ErrorCode" -> n_?CppErrorCodeQ,
		"Parameters" -> {}
	|>]
	,
	TestID -> "ErrorReportingTestSuite-20190404-B7J4Y9"
];

TestMatch[
	Catch[ReadDataWithLoggingError["Secret:Data"], "LLUExceptionTag", #1["Message"]&]
	,
	"Data in file Secret:Data in line 0 is invalid because file name contains a possibly problematic character \":\"."
	,
	TestID -> "ErrorReportingTestSuite-20190404-K3J3E1"
];

Test[
	exCount = StringCount[Import["LLUErrorLog.txt"], "Exception"];
	Quiet @ DeleteFile["LLUErrorLog.txt"];
	exCount
	,
	3
	,
	TestID -> "ErrorReportingTestSuite-20190404-U4H9N8"
];


(* Unit tests of ErrorManager::sendParamatersImmediately *)

Test[
	GetSPI = `LLU`PacletFunctionLoad["GetSendParametersImmediately", {}, "Boolean"];
	GetSPI[]
	,
	True
	,
	TestID -> "ErrorReportingTestSuite-20190404-F9O0O1"
];

Test[
	SetSPI = `LLU`PacletFunctionLoad["SetSendParametersImmediately", {"Boolean"}, "Void"];
	SetSPI[False];

	`LLU`Private`$LastFailureParameters = {"This", "will", "be", "overwritten"};
	ReadData["somefile.txt"];
	`LLU`Private`$LastFailureParameters
	,
	{}
	,
	TestID -> "ErrorReportingTestSuite-20190404-O3A4K4"
];

TestExecute[
	`LLU`$ExceptionTagFunction = First;
];

TestMatch[
	ReadDataDelayedParametersTransfer = `LLU`PacletFunctionLoad["ReadDataDelayedParametersTransfer", {String}, "Void"];
	Catch[ReadDataDelayedParametersTransfer["somefile.txt"], "DataFileError"]
	,
	Failure["DataFileError", <|
		"MessageTemplate" -> "Data in file `fname` in line `lineNumber` is invalid because `reason`.",
		"MessageParameters" -> <|"fname" -> "somefile.txt", "lineNumber" -> 12, "reason" -> "data type is not supported"|>,
		"ErrorCode" -> n_?CppErrorCodeQ,
		"Parameters" -> {}
	|>]
	,
	TestID -> "ErrorReportingTestSuite-20190404-N7X5J6"
];

TestMatch[
	EmptyLibDataException = `LLU`PacletFunctionLoad["EmptyLibDataException", {}, "Void"];
	Catch[EmptyLibDataException[], _String?(StringMatchQ["*Error"])]
	,
	Failure["LibDataError", <|
		"MessageTemplate" -> "WolframLibraryData is not set. Make sure to call LibraryData::setLibraryData in WolframLibrary_initialize.",
		"MessageParameters" -> <||>,
		"ErrorCode" -> n_?CppErrorCodeQ,
		"Parameters" -> {}
	|>]
	,
	TestID -> "ErrorReportingTestSuite-20200114-M9D6F9"
];

TestExecute[
	`LLU`$ExceptionTagFunction := `LLU`$ExceptionTagString&;
];

(*********************************************************** Logging tests **************************************************************)
TestExecute[
	loggerTestPath = FileNameJoin[{currentDirectory, "TestSources", "LoggerTest.cpp"}];
	libLogDebug = CCompilerDriver`CreateLibrary[{loggerTestPath}, "LogDebug", options, "Defines" -> {"LLU_LOG_DEBUG"}];

	(* Reset top-level LLU part *)
	Get[FileNameJoin[{$LLUSharedDir, "LibraryLinkUtilities.wl"}]];
	
	`LLU`InitializePacletLibrary[libLogDebug];

	`LLU`Logger`PrintLogFunctionSelector := Block[{`LLU`Logger`FormattedLog = `LLU`Logger`LogToAssociation},
		`LLU`Logger`PrintLogToSymbol[TestLogSymbol][##]
	]&;
];

Test[
	GreaterAt = `LLU`PacletFunctionLoad["GreaterAt", {String, {_, 1}, Integer, Integer}, "Boolean", "Throws" -> False];
	GreaterAt["file.txt", {5, 6, 7, 8, 9}, 1, 3];
	TestLogSymbol
	,
	{
		<|
			"Level" -> "Debug",
			"Line" -> 19,
			"File" -> loggerTestPath,
			"Function" -> "GreaterAt",
			"Message" -> Style["Library function entered with 4 arguments.", FontSize -> Inherited]
		|>,
		<|
			"Level" -> "Debug",
			"Line" -> 22,
			"File" -> loggerTestPath,
			"Function" -> "GreaterAt",
			"Message" -> Style["Starting try-block, current error code: 0", FontSize -> Inherited]
		|>,
		<|
			"Level" -> "Debug",
			"Line" -> 28,
			"File" -> loggerTestPath,
			"Function" -> "GreaterAt",
			"Message" -> Style["Input tensor is of type: 2", FontSize -> Inherited]
		|>,
		<|
			"Level" -> "Debug",
			"Line" -> 41,
			"File" -> loggerTestPath,
			"Function" -> "GreaterAt",
			"Message" -> Style["Comparing 5 with 7", FontSize -> Inherited]
		|>
	}
	,
	TestID -> "ErrorReportingTestSuite-20190409-U4I2Y8"
];

TestExecute[
	TestLogSymbol = 5; (* assign a number to TestLogSymbol to see if LLU`Logger`PrintToSymbol can handle it *)
	`LLU`Logger`PrintLogFunctionSelector := Block[{`LLU`Logger`FormattedLog = `LLU`Logger`LogToList},
		`LLU`Logger`PrintLogToSymbol[TestLogSymbol][##]
	]&
];

TestMatch[
	GreaterAt["my:file.txt", {5, 6, 7, 8, 9}, 1, 3];
	TestLogSymbol
	,
	{
		{"Debug", _Integer, loggerTestPath, "GreaterAt", "Library function entered with ", 4, " arguments."},
		{"Debug", _Integer, loggerTestPath, "GreaterAt", "Starting try-block, current error code: ", 0},
		{"Warning", _Integer, loggerTestPath, "GreaterAt", "File name ", "my:file.txt", " contains a possibly problematic character \":\"."},
		{"Debug", _Integer, loggerTestPath, "GreaterAt", "Input tensor is of type: ", 2},
		{"Debug", _Integer, loggerTestPath, "GreaterAt", "Comparing ", 5, " with ", 7}
	}
	,
	TestID -> "ErrorReportingTestSuite-20190409-L8V2U9"
];

Test[
	MultiThreadedLog = `LLU`PacletFunctionLoad["LogsFromThreads", {Integer}, "Void"];
	Clear[TestLogSymbol];
	MultiThreadedLog[3];
	And @@ (
		MatchQ[
			Alternatives[
				{"Debug", _Integer, loggerTestPath, "LogsFromThreads", "Starting ", 3, " threads."},
				{"Debug", _Integer, loggerTestPath, "operator()" | "operator ()", "Thread ", _, " going to sleep."},
				{"Debug", _Integer, loggerTestPath, "operator()" | "operator ()", "Thread ", _, " slept for ", _, "ms."},
				{"Debug", _Integer, loggerTestPath, "LogsFromThreads", "All threads joined."}
			]
		] /@ TestLogSymbol
	)
	&&
	MatchQ[First[TestLogSymbol], {"Debug", _Integer, loggerTestPath, "LogsFromThreads", "Starting ", 3, " threads."}]
	&&
	MatchQ[Last[TestLogSymbol], {"Debug", _Integer, loggerTestPath, "LogsFromThreads", "All threads joined."}]
	,
	True
	,
	TestID -> "ErrorReportingTestSuite-20190415-Y8F3L2"
];

TestExecute[
	`LLU`Logger`PrintLogFunctionSelector :=
		If[## =!= `LLU`Logger`LogFiltered,
			Sow @ `LLU`Logger`LogToShortString[##]
		]&;
];

TestMatch[
	Reap @ GreaterAt["file.txt", {5, 6, 7, 8, 9}, -1, 3]
	,
	{
		Failure["TensorIndexError", <|
			"MessageTemplate" -> "An error was caused by attempting to access a nonexistent Tensor element.",
			"MessageParameters" -> <||>,
			"ErrorCode" -> n_?CppErrorCodeQ,
			"Parameters" -> {}
		|>], {
		{
			"(GreaterAt): Library function entered with 4 arguments.",
			"(GreaterAt): Starting try-block, current error code: 0",
			"(GreaterAt): Input tensor is of type: 2",
			"(GreaterAt): Caught LLU exception TensorIndexError: Indices (-1, 3) must be positive."
		}
	}
	},
	SameTest -> ResultAndLogTest
	,
	TestID -> "ErrorReportingTestSuite-20190409-P1S6Y9"
];

TestExecute[
	(* Disable logging in top-level, messages are still transferred from the library *)
	`LLU`Logger`LogFilterSelector = `LLU`Logger`FilterRejectAll;
];

Test[
	Reap @ GreaterAt["my:file.txt", {5, 6, 7, 8, 9}, 1, 3]
	,
	{False, {}}
	,
	TestID -> "ErrorReportingTestSuite-20190410-R2D4P1"
];

TestExecute[
	(* Log only warnings *)
	`LLU`Logger`LogFilterSelector = `LLU`Logger`FilterByLevel[StringMatchQ["warning", IgnoreCase -> True]];
];

Test[
	Reap @ GreaterAt["my:file.txt", {5, 6, 7, 8, 9}, 1, 3]
	,
	{False, {{"(GreaterAt): File name my:file.txt contains a possibly problematic character \":\"."}}}
	,
	SameTest -> ResultAndLogTest
	,
	TestID -> "ErrorReportingTestSuite-20190410-H8S6D5"
];

TestExecute[
	(* Log only messages issued from even line numbers *)
	`LLU`Logger`LogFilterSelector = `LLU`Logger`FilterByLine[EvenQ];
];

Test[
	Reap @ GreaterAt["my:file.txt", {5, 6, 7, 8, 9}, 1, 3]
	,
	{
		False, {
		{
			"(GreaterAt): Starting try-block, current error code: 0",
			"(GreaterAt): File name my:file.txt contains a possibly problematic character \":\".",
			"(GreaterAt): Input tensor is of type: 2"
		}
	}
	},
	SameTest -> ResultAndLogTest
	,
	TestID -> "ErrorReportingTestSuite-20190410-G6A5W4"
];

TestExecute[
	libLogWarning = CCompilerDriver`CreateLibrary[FileNameJoin[{currentDirectory, "TestSources", #}]& /@ {"LoggerTest.cpp"},
		"LogWarning", options, "Defines" -> {"LLU_LOG_WARNING"}];

	Get[FileNameJoin[{$LLUSharedDir, "LibraryLinkUtilities.wl"}]];
	`LLU`InitializePacletLibrary[libLogWarning];
		
	`LLU`$Throws = False;

	GreaterAtW = `LLU`PacletFunctionLoad["GreaterAt", {String, {_, 1}, Integer, Integer}, "Boolean"];
];

Test[
	Reap @ GreaterAtW["my:file.txt", {5, 6, 7, 8, 9}, 1, 3]
	,
	{
		False, {}
	}
	,
	TestID -> "ErrorReportingTestSuite-20190415-A6S8Y7"
];

TestExecute[
	`LLU`Logger`PrintLogFunctionSelector := Sow @ `LLU`Logger`LogToShortString[##]&;
];

Test[
	Reap @ GreaterAtW["file.txt", {5, 6, 7, 8, 9}, -1, 3]
	,
	{
		Failure["TensorIndexError", <|
			"MessageTemplate" -> "An error was caused by attempting to access a nonexistent Tensor element.",
			"MessageParameters" -> <||>,
			"ErrorCode" -> n_?CppErrorCodeQ,
			"Parameters" -> {}
		|>], {
		{
			"(GreaterAt): Caught LLU exception TensorIndexError: Indices (-1, 3) must be positive."
		}
	}
	}
	,
	SameTest -> ResultAndLogTest
	,
	TestID -> "ErrorReportingTestSuite-20190415-P3C4F8"
];

TestExecute[
	TestLogSymbol = {};
	`LLU`Logger`PrintLogFunctionSelector := Block[{`LLU`Logger`FormattedLog = `LLU`Logger`LogToList},
		`LLU`Logger`PrintLogToSymbol[TestLogSymbol][##]
	]&;
	LogDemo = `LLU`PacletFunctionLoad["LogDemo", {Integer, Integer, Integer, Integer, Integer}, Integer];
];

Test[
	{LogDemo[1, 6, 7, 8, 9], TestLogSymbol}
	,
	{6, {}}
	,
	TestID -> "ErrorReportingTestSuite-20190415-C0D7H6"
];

TestMatch[
	{LogDemo[5, 6, 7, 8, 9], TestLogSymbol}
	,
	{
		9,
		{
			{"Warning", _Integer, loggerTestPath, "LogDemo", "Index ", 5, " is too big for the number of arguments: ", 5, ". Changing to ", 4}
		}
	}
	,
	TestID -> "ErrorReportingTestSuite-20190415-J1G2K9"
];

TestMatch[
	TestLogSymbol = {};
	{LogDemo[-1, 6, 7, 8, 9], TestLogSymbol}
	,
	{
		Failure["MArgumentIndexError",
			<|
				"MessageTemplate" -> "An error was caused by an incorrect argument index.",
				"MessageParameters" -> <||>,
				"ErrorCode" -> -2,
				"Parameters" -> {}
			|>
		],
		{
			{
				"Error",
				_Integer,
				loggerTestPath,
				"LogDemo",
				"Caught LLU exception ",
				"MArgumentIndexError", ": ", "Index 4294967295 out-of-bound when accessing LibraryLink argument"
			}
		}
	}
	,
	TestID -> "ErrorReportingTestSuite-20190415-U9M7O6"
];
