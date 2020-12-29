(* Wolfram Language Test file *)
TestRequirement[$VersionNumber > 10.3]
(***************************************************************************************************************************************)
(*
	Set of test cases to test LLU functionality related to WSTP
*)
(***************************************************************************************************************************************)
TestExecute[
	Needs["CCompilerDriver`"];
	currentDirectory = DirectoryName[$TestFileName];

	(* Get configuration (path to LLU sources, compilation options, etc.) *)
	Get[FileNameJoin[{ParentDirectory[currentDirectory], "TestConfig.wl"}]];

	(* Compile the test library *)
	lib = CCompilerDriver`CreateLibrary[FileNameJoin[{currentDirectory, "TestSources", #}]& /@ {"WSTest.cpp", "WSEncodings.cpp"}, "WSTest", options];

	Get[FileNameJoin[{$LLUSharedDir, "LibraryLinkUtilities.wl"}]];
	`LLU`InitializePacletLibrary[lib];

	i8Range = {0, 255};
	i16Range = {-2^15, 2^15 - 1};
	i32Range = {-2^31, 2^31 - 1};
	i64Range = {-2^63, 2^63 - 1};

	Off[General::stop]; (* because we want to see all error messages from CreateLibrary *)
]


(* Compile-time errors *)
Test[
	CCompilerDriver`CreateLibrary[{FileNameJoin[{currentDirectory, "TestSources", "WSTestCompilationErrors.cpp"}]}, "WSTestErrors", options]
	,
	$Failed
	,
	{CreateLibrary::cmperr..} (* On Linux there should be 6 errors, but MSVC does not like generic lambdas so it spits out more errors *)
	,
	TestID -> "WSTPTestSuite-20171129-U5Q3L8"
]


(* Scalars *)
Test[
	`LLU`WSTPFunctionSet[SameInts];
	SameInts[0, -1, -1, -1] (* Integer8 is actually UnsignedInteger8 in WSTP, so send 0 insted of -1. Other integer types are signed *)
	,
	{0, -1, -1, -1}
	,
	TestID -> "WSTPTestSuite-20171129-U4Q3L8"
]

Test[
	SameInts[2^7 - 1, 2^15 - 1, 2^31 - 1, 2^63 - 1]
	,
	{2^7 - 1, 2^15 - 1, 2^31 - 1, 2^63 - 1}
	,
	TestID -> "WSTPTestSuite-20171201-Z2N4U1"
]

Test[
	`LLU`WSTPFunctionSet[MaxInts];
	MaxInts[RandomInteger[i8Range], RandomInteger[i16Range], RandomInteger[i32Range], RandomInteger[i64Range]]
	,
	{2^8 - 1, 2^15 - 1, 2^31 - 1, 2^63 - 1}
	,
	TestID -> "WSTPTestSuite-20171201-O7D3B0"
]

Test[
	`LLU`WSTPFunctionSet[WriteMint];
	WriteMint[]
	,
	-1
	,
	TestID -> "WSTPTestSuite-20190718-U5N0F1"
]

Test[
	`LLU`WSTPFunctionSet[SameFloats];
	{pi, e} = SameFloats[N[Pi], N[E]];
	(Abs[Pi - pi] < 10^-4) && (E == e)
	,
	True
	,
	TestID -> "WSTPTestSuite-20171201-X6F6R7"
]

Test[
	`LLU`WSTPFunctionSet[BoolAnd, "Throws" -> False];
	BoolAnd[True, True, True, False]
	,
	False
	,
	TestID -> "WSTPTestSuite-20171201-F3S0Q7"
]

Test[
	BoolAnd[True, True, True, True, True, True]
	,
	True
	,
	TestID -> "WSTPTestSuite-20171201-P0O0A8"
]

Test[
	BoolAnd[True, True, True, True, Pi]
	,
	Failure["WSWrongSymbolForBool", <|
		"MessageTemplate" -> "Tried to read something else than \"True\" or \"False\" as boolean.",
		"MessageParameters" -> <||>,
		"ErrorCode" -> n_,
		"Parameters" -> {}
	|>] /; n < 0
	,
	SameTest -> MatchQ
	,
	TestID -> "WSTPTestSuite-20171201-L1W7O4"
]

(* Lists *)
Test[
	`LLU`WSTPFunctionSet[GetReversed, "GetReversed8"];
	GetReversed[m = RandomInteger[i8Range, 100000]]
	,
	Reverse[m]
	,
	TestID -> "WSTPTestSuite-20171201-T0E6W4"
]

Test[
	`LLU`WSTPFunctionSet[GetReversed, "GetReversed16"];
	GetReversed[m = RandomInteger[i16Range, 10000]]
	,
	Reverse[m]
	,
	TestID -> "WSTPTestSuite-20171205-H1L8Z6"
]

Test[
	`LLU`WSTPFunctionSet[GetReversed, "GetReversed32"];
	GetReversed[m = RandomInteger[i32Range, 1000]]
	,
	Reverse[m]
	,
	TestID -> "WSTPTestSuite-20171205-V3M5Z6"
]

Test[
	`LLU`WSTPFunctionSet[GetReversed, "GetReversed64"];
	GetReversed[m = RandomInteger[i64Range, 100]]
	,
	Reverse[m]
	,
	TestID -> "WSTPTestSuite-20171205-L4B1P5"
]

Test[
	`LLU`WSTPFunctionSet[GetReversed, "GetReversedDouble"];
	GetReversed[m = RandomReal[1., 100]]
	,
	Reverse[m]
	,
	TestID -> "WSTPTestSuite-20171205-I4G4U8"
]

Test[
	`LLU`WSTPFunctionSet[GetFloatList, "GetFloatList"];
	f = GetFloatList[r = RandomReal[1., 100]];
	Max[Abs[f - r]] < 10^-4
	,
	True
	,
	TestID -> "WSTPTestSuite-20171205-D5X3H2"
]

(* Arrays *)

Test[
	`LLU`WSTPFunctionSet[GetSame, "GetSame8"];
	`LLU`WSTPFunctionSet[Reshape, "Reshape8"];
	s = GetSame[m = RandomInteger[i8Range, {10, 10, 10, 20, 5}]];
	r = Reshape[m];
	ArrayReshape[s, {10, 10, 10, 5, 20}]
	,
	r
	,
	TestID -> "WSTPTestSuite-20171205-K0X1L2"
]

Test[
	`LLU`WSTPFunctionSet[GetSame, "GetSame16"];
	`LLU`WSTPFunctionSet[Reshape, "Reshape16"];
	s = GetSame[m = RandomInteger[i16Range, {10, 10, 20, 5}]];
	r = Reshape[m];
	ArrayReshape[s, {10, 10, 5, 20}]
	,
	r
	,
	TestID -> "WSTPTestSuite-20171205-V8W4L1"
]

Test[
	`LLU`WSTPFunctionSet[GetSame, "GetSame32"];
	`LLU`WSTPFunctionSet[Reshape, "Reshape32"];
	s = GetSame[m = RandomInteger[i32Range, {10, 20, 5}]];
	r = Reshape[m];
	ArrayReshape[s, {10, 5, 20}]
	,
	r
	,
	TestID -> "WSTPTestSuite-20171205-X6T1G7"
]

Test[
	`LLU`WSTPFunctionSet[GetSame, "GetSame64"];
	`LLU`WSTPFunctionSet[Reshape, "Reshape64"];
	s = GetSame[m = RandomInteger[i64Range, {20, 5}]];
	r = Reshape[m];
	ArrayReshape[s, {5, 20}]
	,
	r
	,
	TestID -> "WSTPTestSuite-20171205-K5D5R0"
]

Test[
	`LLU`WSTPFunctionSet[GetSame, "GetSameDouble"];
	`LLU`WSTPFunctionSet[Reshape, "ReshapeDouble"];
	s = GetSame[m = RandomReal[1., {20, 5}]];
	r = Reshape[m];
	ArrayReshape[s, {5, 20}]
	,
	r
	,
	TestID -> "WSTPTestSuite-20171205-Z8T6P5"
]

Test[
	`LLU`WSTPFunctionSet[ToList, "ComplexToList"];
	c = RandomComplex[1 + I, {7, 8, 9}];
	ToList[c]
	,
	c /. Complex[x_, y_] -> {x, y}
	,
	TestID -> "WSTPTestSuite-20171205-W6B3U7"
]

Test[ (* Test if releasing memory works, if not the memory usage should drastically increase after this test *)
	`LLU`WSTPFunctionSet[ReceiveAndFreeArray, "ReceiveAndFreeArray"];
	r = RandomReal[1., {100, 100, 100}];
	MemoryLeakTest[ReceiveAndFreeArray[r]]
	,
	0
	,
	TestID -> "WSTPTestSuite-20171205-D4D6S4"
]

(* Strings *)
Test[
	testString = FromCharacterCode[{97, 261, 322, 945, 63488, 63264}]; (* "a\:0105\[LSlash]\[Alpha]\[FormalA]\[Wolf]" *)
	expected = StringRepeat[testString, 2];
	`LLU`WSTPFunctionSet[RepeatString, "RepeatString"];
	RepeatString[testString]
	,
	expected
	,
	TestID -> "WSTPTestSuite-20171205-C3X0I2"
]

Test[
	`LLU`WSTPFunctionSet[RepeatUTF8, "RepeatUTF8"];
	RepeatUTF8[testString]
	,
	expected
	,
	TestID -> "WSTPTestSuite-20171205-F0A7B0"
]

Test[
	`LLU`WSTPFunctionSet[RepeatUTF16, "RepeatUTF16"];
	RepeatUTF16[testString]
	,
	expected
	,
	TestID -> "WSTPTestSuite-20171205-M2B7E4"
]

Test[
	`LLU`WSTPFunctionSet[RepeatUTF32, "RepeatUTF32"];
	RepeatUTF32[testString]
	,
	expected
	,
	TestID -> "WSTPTestSuite-20171205-S9R5Q1"
]

Test[
	testString = "\\+\\\\+\"+\n+\t+?";  (* ToCharacterCode = {92, 43, 92, 92, 43, 34, 43, 10, 43, 9, 43, 63} *)
	expected = testString <> FromCharacterCode[{7, 8, 12, 13, 10, 9, 11, 92, 39, 34, 63}];
	`LLU`WSTPFunctionSet[AppendString, "AppendString"]; (* following string is appended in the C++ code: "\a\b\f\r\n\t\v\\\'\"\?" *)
	ToCharacterCode @ AppendString[testString]
	,
	ToCharacterCode @ expected
	,
	TestID -> "WSTPTestSuite-20180202-Q8H8K0"
]

Test[
	`LLU`WSTPFunctionSet[AppendUTF8, "AppendUTF8"];
	ToCharacterCode @ AppendUTF8[testString]
	,
	ToCharacterCode @ expected
	,
	TestID -> "WSTPTestSuite-20180202-Y8D5D1"
]

Test[
	`LLU`WSTPFunctionSet[AppendUTF16, "AppendUTF16"];
	ToCharacterCode @ AppendUTF16[testString]
	,
	ToCharacterCode @ expected
	,
	TestID -> "WSTPTestSuite-20180202-Q6K1Y5"
]

Test[
	`LLU`WSTPFunctionSet[AppendUTF32, "AppendUTF32"];
	ToCharacterCode @ AppendUTF32[testString]
	,
	ToCharacterCode @ expected
	,
	TestID -> "WSTPTestSuite-20180202-S0Q4U6"
]

Test[ (* Test if releasing strings works, if not the memory usage should drastically increase after this test *)
	`LLU`WSTPFunctionSet[ReceiveAndFreeString, "ReceiveAndFreeString"];
	s = StringJoin[RandomChoice[CharacterRange["A", "z"], 10000]];
	MemoryLeakTest @ ReceiveAndFreeString[s]
	,
	0
	,
	TestID -> "WSTPTestSuite-20171205-T6V1J3"
]

Test[
	`LLU`WSTPFunctionSet[GetAndPutUTF8, "GetAndPutUTF8"];
	testStr = "\:0105\:0119\[AE]\[Copyright]\\/";
	GetAndPutUTF8[testStr, testStr]
	,
	"This will be sent as UTF8 encoded string. No need to escape backslashes \\o/. Some weird characters: " <> FromCharacterCode[{196, 133, 194, 169, 197, 130, 195, 179, 195, 159, 194, 181}, "UTF8"]
	,
	TestID -> "WSTPTestSuite-20180207-C6Z9T4"
]

Test[
	`LLU`WSTPFunctionSet[NestedPutAs, "NestedPutAs"];
	testStr = "\:0105\:0119\[AE]\[Copyright]\\/";
	NestedPutAs[testStr]
	,
	testStr
	,
	TestID -> "WSTPTestSuite-20180403-P4U4Q4"
]

Test[
	`LLU`WSTPFunctionSet[CharacterCodes, "CharacterCodes"];
	testStr = "\:0105\:0119\[AE]\[Copyright]\\/";
	CharacterCodes[testStr]
	,
	<|
		"Native" -> {92, 58, 48, 49, 48, 53, 92, 58, 48, 49, 49, 57, 92, 51, 52, 54, 92, 50, 53, 49, 92, 92, 47}, (* "\:0105\:0119\346\251\\/" *)
		"Byte" -> {26, 26, 230, 169, 92, 47},
		"UTF8" -> {196, 133, 196, 153, 195, 166, 194, 169, 92, 47},
		"UTF16" -> {65279, 261, 281, 230, 169, 92, 47}, (* 65279 is BOM *)
		"UCS2" -> {261, 281, 230, 169, 92, 47},
		"UTF32" -> {65279, 261, 281, 230, 169, 92, 47}
	|>
	,
	TestID -> "WSTPTestSuite-20180403-H9X4X4"
]

Test[
	`LLU`WSTPFunctionSet[AllEncodingsRoundtrip, "AllEncodingsRoundtrip"];
	testStrs = {"abcde", "\[Integral]\[Wolf]\[DifferentialD]\[Xi]", "ab\[CAcute]\[Eth]\:0119", "\\+\\\\+\"+\n+\t+?"};
	MapThread[Map[Function[assocElem, #2 == assocElem], #1] &, {AllEncodingsRoundtrip /@ testStrs, testStrs}]
	,
	{
		<|"Native" -> True, "Byte" -> True, "UTF8" -> True, "UTF16" -> True, "UCS2" -> True, "UTF32" -> True|>,
		<|"Native" -> True, "Byte" -> False, "UTF8" -> True, "UTF16" -> True, "UCS2" -> True, "UTF32" -> True|>,
		<|"Native" -> True, "Byte" -> False, "UTF8" -> True, "UTF16" -> True, "UCS2" -> True, "UTF32" -> True|>,
		<|"Native" -> True, "Byte" -> True, "UTF8" -> True, "UTF16" -> True, "UCS2" -> True, "UTF32" -> True|>
	}
	,
	TestID -> "WSTPTestSuite-20180403-P1E4U8"
]

(* Symbols and Arbitrary Functions *)
Test[
	`LLU`WSTPFunctionSet[GetList, "GetList"];
	GetList[]
	,
	{{1, 2, 3}, Missing[""], {1.5, 2.5, 3.5}, "Hello!", Missing["Deal with it"]}
	,
	TestID -> "WSTPTestSuite-20171205-A4D8U2"
]

Test[
	ReverseSymbolsOrder = LibraryFunctionLoad[lib, "ReverseSymbolsOrder", LinkObject, LinkObject];
	ReverseSymbolsOrder[Pi, E, GoldenRatio, x] (* Things like I or Infinity are not symbols *)
	,
	{x, GoldenRatio, E, Pi}
	,
	TestID -> "WSTPTestSuite-20171214-Q8O4B9"
]

Test[
	TakeLibraryFunction = LibraryFunctionLoad[lib, "TakeLibraryFunction", LinkObject, LinkObject];
	TakeLibraryFunction @ TakeLibraryFunction
	,
	ReverseSymbolsOrder
	,
	TestID -> "WSTPTestSuite-20171214-N1Z1H6"
]

Test[
	TakeLibraryFunction = LibraryFunctionLoad[lib, "TakeLibraryFunction", LinkObject, LinkObject];
	(TakeLibraryFunction @ TakeLibraryFunction)[Pi, E, GoldenRatio, x]
	,
	{x, GoldenRatio, E, Pi}
	,
	TestID -> "WSTPTestSuite-20171214-K6Z5T3"
]

Test[
	`LLU`WSTPFunctionSet[GetSet, "GetSet"];
	GetSet[{"lorem", "ipsum", "dolor", "sit", "amet"}, "StringJoin"]
	,
	StringJoin @ Sort[{"lorem", "ipsum", "dolor", "sit", "amet"}]
	,
	TestID -> "WSTPTestSuite-20171214-F6N1C7"
]

Test[
	GetSet[{"lorem", "ipsum", "dolor", "sit", "amet"}]
	,
	Sort[{"lorem", "ipsum", "dolor", "sit", "amet"}]
	,
	TestID -> "WSTPTestSuite-20171227-V7Z8S6"
]


(* Associations/Maps *)
Test[
	`LLU`WSTPFunctionSet[ReadNestedMap, "ReadNestedMap"];
	r = RandomReal[{-Pi, Pi}, 10];
	Sort @ ReadNestedMap[<|
		"Multiply" -> <|3 -> r, 0 -> r, -3 -> r|>,
		"DoNothing" -> <|3 -> r, 0 -> r|>,
		"Negate" -> <|3 -> r, 0 -> r|>,
		"Add" -> <|-5 -> r|>
	|>]
	,
	Sort @ <|
		"Multiply" -> <|-3 -> -3r, 0 -> 0r, 3 -> 3r|>,
		"DoNothing" -> <|0 -> r, 3 -> r|>,
		"Negate" -> <|0 -> -r, 3 -> -r|>,
		"Add" -> <|-5 -> r - 5|>
	|>
	,
	TestID -> "WSTPTestSuite-20171227-V4J6Y2"
]


(* Local Loopback Link *)
Test[
	`LLU`WSTPFunctionSet[IntList, "UnknownLengthList"];
	modulus = 123;
	l = IntList[modulus];
	VectorQ[l, (IntegerQ[#] && 0 <= # <= 1000000 && !Divisible[#, modulus])&]
	,
	True
	,
	TestID -> "WSTPTestSuite-20180619-G8D1H1"
]

Test[
	`LLU`WSTPFunctionSet[Ragged, "RaggedArray"];
	length = 15;
	Ragged[length]
	,
	Table[Drop[Range[0, i], -1], {i, 0, length - 1}]
	,
	TestID -> "WSTPTestSuite-20180619-W3E7I4"
]

Test[
	`LLU`WSTPFunctionSet[Factors, "FactorsOrFailed"];
	l = RandomInteger[{1, 123456}, 20];
	Factors[l]
	,
	AssociationMap[
		With[{d = Divisors[#]},
			If[Length[d] > 15, $Failed, d]
		]&
		, l]
	,
	TestID -> "WSTPTestSuite-20180619-L6X0P3"
]

Test[
	`LLU`WSTPFunctionSet[GetEmpty, "Empty"];
	GetEmpty["Association"]
	,
	<||>
	,
	TestID -> "WSTPTestSuite-20180622-Z8V8N3"
]

Test[
	GetEmpty["List"]
	,
	{}
	,
	TestID -> "WSTPTestSuite-20180622-S5A9U6"
]

Test[
	GetEmpty["NoSuchHead"]
	,
	NoSuchHead[]
	,
	TestID -> "WSTPTestSuite-20180622-S7D2R7"
]

Test[
	`LLU`WSTPFunctionSet[ListOfStrings, lib, "ListOfStringsTiming"];
	los = RandomWord["CommonWords", 1000];
	{timeNormal, r1} = RepeatedTiming[ListOfStrings[los, False]];
	{timeBeginEnd, r2} = RepeatedTiming[ListOfStrings[los, True]];
	Print["Time when sending list as usual: " <> ToString[timeNormal] <> "s."];
	Print["Time when sending list with BeginExpr: " <> ToString[timeBeginEnd] <> "s."];
	r1 == r2 == Join @@ Table[los, 100]
	,
	True
	,
	TestID -> "WSTPTestSuite-20180622-S6K4T4"
]
