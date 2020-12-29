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

	(* Compile the test library *)
	lib = CCompilerDriver`CreateLibrary[
		FileNameJoin[{currentDirectory, "TestSources", #}]& /@ {"ManagedExprTest.cpp"},
		"ManagedExpressions",
		options,
		"Defines" -> {"LLU_LOG_DEBUG"}
	];

	Get[FileNameJoin[{$LLUSharedDir, "LibraryLinkUtilities.wl"}]];

	`LLU`InitializePacletLibrary[lib];

	`LLU`Logger`PrintLogFunctionSelector := Block[{`LLU`Logger`FormattedLog = `LLU`Logger`LogToShortString},
		`LLU`Logger`PrintLogToSymbol[LogSymbol][##]
	]&;

	GetManagedExpressionCount = `LLU`PacletFunctionLoad["GetManagedExpressionCount", {}, Integer];
	GetManagedExpressionTexts = `LLU`PacletFunctionLoad["GetManagedExpressionTexts", {}, "DataStore"];
	ReleaseExpression = `LLU`PacletFunctionLoad["ReleaseExpression", {`LLU`Managed[MyExpression]}, Integer];

	$CreateNewMyExpression = `LLU`PacletFunctionLoad["OpenManagedMyExpression", {`LLU`Managed[MyExpression], String}, "Void"];
	$CreateNewMyChildExpression = `LLU`PacletFunctionLoad["OpenManagedMyChildExpression", {`LLU`Managed[MyExpression], String}, "Void"];

	(* Register a constructor for new Managed Expression. This step could be more automated if we agree that for each class X that shall be managed there is
	 * an interface function "OpenManagedX" defined in the library.
	 * It gets more complicated if you want to use a class hierarchy as MLE as you need to decide which class will be instantiated at WL level.
	 *)
	CreateMyExpression[instance_, text_?StringQ, createChildQ_ : False] := If[createChildQ, $CreateNewMyChildExpression, $CreateNewMyExpression][instance, text];
	`LLU`Constructor[MyExpression] = CreateMyExpression;

	(* Load library functions that wrap MyExpression member functions *)
	`LLU`LazyMemberFunctionSet[MyExpression][getText, "GetText", {}, String];
	`LLU`LazyMemberFunctionSet[MyExpression][setText, "SetText", {String}, "Void"];
	`LLU`LazyWSTPMemberFunctionSet[MyExpression][setTextWS, "SetTextWS"];
	`LLU`LazyMemberFunctionSet[MyExpression][getCounter, "GetCounter", {}, Integer]; (* this member only works with MLEs that are of type MyChildExpression in C++ *)

	(* Load other library functions *)
	joinText = `LLU`PacletFunctionLoad["JoinText", {`LLU`Managed[MyExpression], `LLU`Managed[MyExpression]}, String];
	getMyExpressionStoreName = `LLU`PacletFunctionLoad["GetMyExpressionStoreName", {}, String];
	swapText = `LLU`PacletFunctionLoad["SwapText", LinkObject, LinkObject];

	ManagedMyExprQ = `LLU`ManagedQ[MyExpression];
	ManagedMyExprIDQ = `LLU`ManagedIDQ[MyExpression];

	(* Create new instance of MyExpression *)
	globalExpr = `LLU`NewManagedExpression[MyExpression]["I will live through all tests"];

	(* In some rare cases you may want LLU to issue single-argument Throws. It can be achieved by modifying $ExceptionTagFunction as follows: *)
	`LLU`$ExceptionTagFunction = Nothing;
];

Test[
	LogSymbol
	,
	{ "MyExpression[1] created." }
	,
	SameTest -> LoggerStringTest
	,
	TestID -> "ManagedExpressionsTestSuite-20200207-I4S3H8"
];

TestExecute[
	Clear[LogSymbol];
];

Test[
	ManagedMyExprQ[globalExpr]
	,
	True
	,
	TestID -> "ManagedExpressionsTestSuite-20200207-C2I7L1"
];

Test[
	`LLU`ManagedQ[x][globalExpr]
	,
	False
	,
	TestID -> "ManagedExpressionsTestSuite-20200207-F6S3U8"
];

Test[
	ManagedMyExprIDQ[`LLU`GetManagedID[globalExpr]]
	,
	True
	,
	TestID -> "ManagedExpressionsTestSuite-20200207-N2E7N8"
];

Test[
	GetManagedExpressionCount[]
	,
	1
	,
	TestID -> "ManagedExpressionsTestSuite-20200207-W8B4N0"
];

Test[
	ManagedMyExprIDQ[150]
	,
	False
	,
	TestID -> "ManagedExpressionsTestSuite-20200207-C4I6E1"
];

Test[
	Clear[LogSymbol];
	Block[{e},
		e = `LLU`NewManagedExpression[MyExpression]["I will die when this test ends"];
		e @ getText[]
	]
	,
	"I will die when this test ends"
	,
	TestID -> "ManagedExpressionsTestSuite-20200207-O5L3L4"
];

Test[
	LogSymbol
	,
	{
		"MyExpression[2] created.",
		"MyExpression[2] is dying now."
	}
	,
	SameTest -> LoggerStringTest
	,
	TestID -> "ManagedExpressionsTestSuite-20200207-A1A1A7"
];

Test[
	MyExpression`getText[globalExpr]
	,
	"I will live through all tests"
	,
	TestID -> "ManagedExpressionsTestSuite-20200207-I9S8M8"
];

Test[
	MyExpression`setText[globalExpr, "New text for global expr."]
	,
	Null
	,
	TestID -> "ManagedExpressionsTestSuite-20200207-W1J2D0"
];

Test[
	globalExpr @ getText[]
	,
	"New text for global expr."
	,
	TestID -> "ManagedExpressionsTestSuite-20200207-H6Q5E0"
];

Test[
	globalExpr @ setText["I will live through all tests"]
	,
	Null
	,
	TestID -> "ManagedExpressionsTestSuite-20200207-R2G7I3"
];

Test[
	Catch @ MyExpression[500] @ getText[]
	,
	Failure["InvalidManagedExpressionID",
		<|
			"MessageTemplate" -> "`Expr` is not a valid ManagedExpression.",
			"MessageParameters" -> <|"Expr" -> MyExpression[500]|>,
			"ErrorCode" -> 25,
			"Parameters" -> {}
		|>
	]
	,
	TestID -> "ManagedExpressionsTestSuite-20200207-A2Z1W4"
];

Test[
	Catch @ MyExpression`getText[NotMyExpression[1]]
	,
	Failure["UnexpectedManagedExpression",
		<|
			"MessageTemplate" -> "Expected managed `Expected`, got `Actual`.",
			"MessageParameters" -> <|"Expected" -> MyExpression, "Actual" -> NotMyExpression[1]|>,
			"ErrorCode" -> 26,
			"Parameters" -> {}
		|>
	]
	,
	TestID -> "ManagedExpressionsTestSuite-20200207-J0C3H4"
];

Test[
	NotMyExpression[1] @ getText[]
	,
	NotMyExpression[1] @ getText[]
	,
	TestID -> "ManagedExpressionsTestSuite-20200207-R0O9X0"
];

Test[
	Clear[LogSymbol];
	joinText[globalExpr, `LLU`NewManagedExpression[MyExpression]["I'm just a temporary"]]
	,
	"I will live through all testsI'm just a temporary"
	,
	TestID -> "ManagedExpressionsTestSuite-20200207-X1O7K8"
];

Test[
	LogSymbol
	,
	{
		"MyExpression[3] created.",
		"MyExpression[3] is dying now."
	}
	,
	SameTest -> LoggerStringTest
	,
	TestID -> "ManagedExpressionsTestSuite-20200207-U9Z0V1"
];

Test[
	expr1 = `LLU`NewManagedExpression[MyExpression]["Hello"];
	expr2 = `LLU`NewManagedExpression[MyExpression]["World"];
	swapText[expr1, expr2];
	{expr1 @ getText[], expr2 @ getText[]}
	,
	{"World", "Hello"}
	,
	TestID -> "ManagedExpressionsTestSuite-20200207-L1P4L1"
];

Test[
	GetManagedExpressionCount[]
	,
	3
	,
	TestID -> "ManagedExpressionsTestSuite-20200207-I4N3P3"
];

Test[
	Association @@ GetManagedExpressionTexts[] // KeySort
	,
	<|"1" -> "I will live through all tests", "4" -> "World", "5" -> "Hello"|>
	,
	TestID -> "ManagedExpressionsTestSuite-20200207-W2B5W1"
];

Test[
	expr1 @ setTextWS["My new text"];
	expr1 @ getText[]
	,
	"My new text"
	,
	TestID -> "ManagedExpressionsTestSuite-20200207-M3K8R7"
];

Test[
	getMyExpressionStoreName[]
	,
	ToString @ Head @ globalExpr
	,
	TestID -> "ManagedExpressionsTestSuite-20200207-F8G3J3"
];

TestExecute[
	Clear[LogSymbol];
	`LLU`NewManagedExpression[MyExpression]["Hello, I'm a subclass of MyExpression", True];
];

Test[
	LogSymbol
	,
	{
		"MyExpression[6] created.",
		"MyChildExpression[6] created.",
		"MyChildExpression[6] is dying now.",
		"MyExpression[6] is dying now."
	}
	,
	SameTest -> LoggerStringTest
	,
	TestID -> "ManagedExpressionsTestSuite-20200207-I5D4C3"
];

Test[
	ReleaseExpression[expr1]
	,
	0
	,
	TestID -> "ManagedExpressionsTestSuite-20200207-O1W5W3"
];

Test[
	Catch @ ReleaseExpression @ MyExpression[500]
	,
	Failure["InvalidManagedExpressionID",
		<|
			"MessageTemplate" -> "`Expr` is not a valid ManagedExpression.",
			"MessageParameters" -> <|"Expr" -> MyExpression[500]|>,
			"ErrorCode" -> 25,
			"Parameters" -> {}
		|>
	]
	,
	TestID -> "ManagedExpressionsTestSuite-20200207-O6Q1L6"
];

Test[
	ReleaseExpression[-1]
	,
	0 (* likely a bug in releaseManagedLibraryExpression - it is documented to return a non-zero code for invalid ID *)
	,
	TestID -> "ManagedExpressionsTestSuite-20200207-E5H4U0"
];

Test[
	GetManagedExpressionCount[]
	,
	2
	,
	TestID -> "ManagedExpressionsTestSuite-20200207-S7D4T4"
];

Test[
	subclassExpr = `LLU`NewManagedExpression[MyExpression]["I'm a MyChildExpression", True];
	subclassExpr @ getCounter[];
	subclassExpr @ getCounter[]
	,
	2
	,
	TestID -> "ManagedExpressionsTestSuite-20190911-R0A1T3"
];

Test[
	Block[{e},
		e = `LLU`NewManagedExpression[MyExpression]["I will die when this test ends", True];
		e @ getText[]
	]
	,
	"I'm a subclass! Here is your text: I will die when this test ends"
	,
	TestID -> "ManagedExpressionsTestSuite-20190911-R3Z8U9"
];

Test[
	(* Reload the getText member. MyExpression`getText will be Cleared and then reloaded. *)
	`LLU`MemberFunctionSet[MyExpression][getText, "GetText", {}, String];
	globalExpr @ getText[]
	,
	"I will live through all tests"
	,
	TestID -> "ManagedExpressionsTestSuite-20190911-R3ZHG9"
];

Test[
	getText = 3;
	(* When the symbol for member function is taken, MemberFunctionSet will fail silently.
	 * You can no longer use the "member function" syntax, but you can still access the member function with full context. 
	 *)
	`LLU`MemberFunctionSet[MyExpression][getText, "GetText", {}, String];
	{globalExpr @ getText[], MyExpression`getText @ globalExpr}
	,
	{globalExpr[3[]], "I will live through all tests"}
	,
	TestID -> "ManagedExpressionsTestSuite-20190911-R4ZHG9"
];

TestExecute[
	`LLU`LazyPacletFunctionSet[`LLU`Constructor[Serializable], "CreateSerializableExpression", {`LLU`Managed[Serializable], String}, "Void"];
	`LLU`LazyPacletFunctionSet[Serialize, {`LLU`Managed[Serializable]}, String];
];

Test[
	a = `LLU`NewManagedExpression[Serializable]["I am an A."]
	,
	Serializable[1]
	,
	TestID -> "ManagedExpressionsTestSuite-20200420-N6L0O5"
];

Test[
	Serialize[a]
	,
	"Hello! I'm A."
	,
	TestID -> "ManagedExpressionsTestSuite-20200420-D8B7D8"
];

Test[
	b = `LLU`NewManagedExpression[Serializable]["Yo soy B."];
	Serialize[b]
	,
	"Hello! I'm B. I hold 7."
	,
	TestID -> "ManagedExpressionsTestSuite-20200420-B9Q4H7"
];

VerificationTest[
	c = Catch @ `LLU`NewManagedExpression[Serializable]["Jestem C."]; (* The factory function will throw and the C++ object will not be created *)
	FailureQ[c]
	,
	TestID -> "ManagedExpressionsTestSuite-20200420-T5J0L7"
];

VerificationTest[
	Not @ `LLU`ManagedIDQ[Serializable][3] (* Since the creation of managed expression failed, it must not be registered as MLE *)
	,
	TestID -> "ManagedExpressionsTestSuite-20200420-R0M2X2"
];

VerificationTest[
	Not @ `LLU`ManagedQ[Serializable][c]
	,
	TestID -> "ManagedExpressionsTestSuite-20200420-W2O0L8"
];

TestExecute[
	Clear[f];
	f[1] = 1;
	f[2][2] = 2;
	f[3][2] = 3;
	f /: g[f[3]] = 3;
	f::x = "x";
	SetAttributes[f, Orderless];
];

Test[
	`LLU`Private`clearLHS[f[2]];
	{DownValues[f], SubValues[f], UpValues[f]}
	,
	{{HoldPattern[f[1]] :> 1}, {HoldPattern[f[2][2]] :> 2, HoldPattern[f[3][2]] :> 3}, {HoldPattern[g[f[3]]] :> 3}}
];

Test[
	`LLU`Private`clearLHS[f];
	{DownValues[f], SubValues[f], UpValues[f], Messages[f], Attributes[f]}
	,
	{{}, {}, {}, {HoldPattern[f::x] :> "x"}, {Orderless}}
];
