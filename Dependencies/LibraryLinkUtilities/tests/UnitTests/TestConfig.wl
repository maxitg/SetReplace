(* Project base directory *)
$baseDir = FileNameDrop[$TestFileName, -3];

$installDir = If[StringQ[$LLUInstallDir], $LLUInstallDir, FileNameJoin[{$baseDir, "install"}]];

(* Path to directory containing include folder from LibraryLinkUtilities installation *)
$LLUIncDir = FileNameJoin[{$installDir, "include"}];

$lib = FileNames[RegularExpression[".*LLU\\.(a|lib|" <> System`Dump`LibraryExtension[] <> ")"], $installDir, 2];
If[Length[$lib] =!= 1,
	Throw["Could not find LLU library.", "LLUTestConfig"];
];

(* Path to LibraryLinkUtilities static lib *)
$LLULibDir = DirectoryName @ First @ $lib;

(* LibraryLinkUtilities library name *)
$LLULib = "LLU";

(* Path to LibraryLinkUtilities shared resources *)
$LLUSharedDir = FileNameJoin[{$installDir, "share"}];

(* C++ version to build unit tests with. Some parts of LLU require C++17. *)
$CppVersion = "c++17";

(* Compilations options for all tests *)
options := {
	"CleanIntermediate" -> True,
	"IncludeDirectories" -> { $LLUIncDir },
	"Libraries" -> { $LLULib },
	"LibraryDirectories" -> { $LLULibDir },
	"CompileOptions" ->
		Switch[$OperatingSystem,
			"Windows",
				"/EHsc /W3 /std:" <> $CppVersion <> " /D_SILENCE_CXX17_CODECVT_HEADER_DEPRECATION_WARNING",
			"Unix",
				"-Wall --pedantic -fvisibility=hidden -std=" <> $CppVersion,
			"MacOSX",
				"-mmacosx-version-min=10.12 -Wall -Wextra --pedantic -fvisibility=hidden -std=" <> $CppVersion
		],
	"ShellOutputFunction" -> Print,
	"ShellCommandFunction" -> Print,
	"Language" -> "C++",
	"TransferProtocolLibrary" -> "WSTP"
};

(* If dynamic version of LLU was built, we want to load it to Mathematica before test libs are loaded *)
LibraryLoad /@ FileNames[{"*.so", "*.dll", "*.dylib"}, $LLULibDir];


(* Helper definitions *)

TopLevelErrorCodeQ[c_Integer] := c > 7;
TopLevelErrorCodeQ[_] := False;

LLErrorCodeQ[c_Integer] := 0 <= c <= 7;
LLErrorCodeQ[_] := False;

CppErrorCodeQ[c_Integer] := c < 0;
CppErrorCodeQ[_] := False;

LoggerStringTest = (AllTrue[MapThread[StringEndsQ, {##}], TrueQ]&);

(* Memory leak test *)
ClearAll[MemoryLeakTest];
SetAttributes[MemoryLeakTest, HoldAll];
Options[MemoryLeakTest] = {"ReturnValue" -> Last};

MemoryLeakTest[expression_, opts : OptionsPattern[]] :=
	MemoryLeakTest[expression, {i, 10}, opts];

MemoryLeakTest[expression_, repetitions_Integer?Positive, opts : OptionsPattern[]] :=
	MemoryLeakTest[expression, {i, repetitions}, opts];

MemoryLeakTest[expression_, {s_Symbol, repetitions__}, opts : OptionsPattern[]] :=
	Block[{$MessageList},
		Module[{res, memory},
			$MessageList = {};
			ClearSystemCache[];
			res = Table[
				memory = MemoryInUse[];
				expression;
				$MessageList = {};
				ClearSystemCache[];
				MemoryInUse[] - memory
				,
				{s, repetitions}
			];
			OptionValue["ReturnValue"] @ res
		]
	];

MemoryLeakTestWithMessages[expression_] :=
	MemoryLeakTestWithMessages[expression, 10];

MemoryLeakTestWithMessages[expression_, repetitions_Integer?Positive] :=
	Block[{mem},
		Do[
			mem = MemoryInUse[];
			expression;
			Print[MemoryInUse[] - mem]
			,
			{repetitions}
		]
	];
	
SetAttributes[CatchException, HoldAllComplete];
CatchException[a__] := Function[x, CatchException[a, x], HoldAll];

CatchException[tagPattern_String, body_] := Catch[body, _String?(StringMatchQ[tagPattern])];
CatchException[tagPattern_, body_] := Catch[body, tagPattern];

SetAttributes[CatchAll, HoldFirst];
CatchAll[body_] := CatchException[_, body];