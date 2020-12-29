(* Wolfram Language Test file *)
TestRequirement[$VersionNumber >= 12];
(***************************************************************************************************************************************)
(*
	Set of test cases to test LLU functionality related to handling and exchanging tensors
*)
(***************************************************************************************************************************************)
TestExecute[
	Needs["CCompilerDriver`"];
	currentDirectory = DirectoryName[$TestFileName];

	(* Get configuration (path to LLU sources, compilation options, etc.) *)
	Get[FileNameJoin[{ParentDirectory[currentDirectory], "TestConfig.wl"}]];

	(* Compile the test library *)
	lib = CCompilerDriver`CreateLibrary[
		FileNameJoin[{currentDirectory, "TestSources", #}]& /@ {"Basic.cpp", "ScalarOperations.cpp", "SharedData.cpp"},
		"TensorTest",
		options (* defined in TestConfig.wl *)
	];

	Get[FileNameJoin[{$LLUSharedDir, "LibraryLinkUtilities.wl"}]];
	`LLU`InitializePacletLibrary[lib];
];


(*
 Basic operations
*)
TestExecute[
	EchoTensor = LibraryFunctionLoad[lib, "EchoTensor", {{Integer, _}}, {Integer, _}];
	EchoFirst = LibraryFunctionLoad[lib, "EchoFirst", {{Integer, 1}}, Integer];
	EchoLast = LibraryFunctionLoad[lib, "EchoLast", {{Integer, 1} }, Integer];
	EchoElement = LibraryFunctionLoad[lib, "EchoElement", {{"NumericArray", "Constant"}, {Integer, 1}}, Integer];

	CreateMatrix = LibraryFunctionLoad[lib, "CreateMatrix", {Integer, Integer}, {Integer, 2}];
	EmptyVector = LibraryFunctionLoad[lib, "CreateEmptyVector", {}, {Integer, 1}];
	EmptyMatrix = LibraryFunctionLoad[lib, "CreateEmptyMatrix", {}, {Integer, _}];
	CloneTensor = LibraryFunctionLoad[lib, "CloneTensor", {{_, _, "Constant"}}, {_, _}];
	TestDimensions = LibraryFunctionLoad[lib, "TestDimensions", {{Integer, 1, "Manual"}}, {Real, _}];
	TestDimensions2 = LibraryFunctionLoad[lib, "TestDimensions2", {}, "DataStore"];
	FromVector = LibraryFunctionLoad[lib, "FromVector", {}, {Integer, 2}];
	FlattenThroughVector = LibraryFunctionLoad[lib, "FlattenThroughVector", {{Integer, _}}, {Integer, 1}];
	CopyThroughNumericArray = LibraryFunctionLoad[lib, "CopyThroughNumericArray", {{Integer, _}}, {Integer, _}];

	MeanValue = LibraryFunctionLoad[lib, "MeanValue", {{Real, 1}}, Real];

	IntegerMatrixTranspose = LibraryFunctionLoad[lib, "IntegerMatrixTranspose", {{Integer, 2}}, {Integer, 2}];
	GetLargest = LibraryFunctionLoad[lib, "GetLargest", {{_, _}, {_, _, "Constant"}, {_, _, "Manual"}}, Integer];
	ReverseTensor = LibraryFunctionLoad[lib, "Reverse", {{_, _, "Constant"}}, {_, _}];
];

Test[
	EchoTensor[{1, 2, 3}]
	,
	{1, 2, 3}
	,
	TestID -> "TensorOperations-20150817-O6E3O4"
];

Test[
	EchoTensor[{}]
	,
	{}
	,
	TestID -> "TensorTestSuite-20190703-L8P5C2"
];

Test[
	EchoTensor[{{}, {}}]
	,
	{{}, {}}
	,
	TestID -> "TensorTestSuite-20190731-M4L3S5"
]

Test[
	EchoTensor[{{3}, {6}}]
	,
	{{3}, {6}}
	,
	TestID -> "TensorTestSuite-20190731-C9Q9J9"
]

Test[
	EchoFirst[{1, 2, 3}]
	,
	1
	,
	TestID -> "TensorTestSuite-20181121-O5M3H2"
];

Test[
	EchoLast[{1, 2, 3}]
	,
	3
	,
	TestID -> "TensorTestSuite-20181121-W3H7Z7"
];

Test[
	r = RandomInteger[1000, {10, 5, 20}];
	EchoElement[NumericArray[r, "Integer64"], {3, 0, 12}]
	,
	r[[4, 1, 13]]
	,
	TestID -> "TensorTestSuite-20181121-W3gsdfgs"
];

TestMatch[
	r = RandomInteger[1000, {10, 5, 20}];
	Quiet @ EchoElement[NumericArray[r, "Integer64"], {3, 5, 12}]
	,
	LibraryFunctionError["LIBRARY_USER_ERROR", n_?IntegerQ]
	,
	TestID -> "TensorTestSuite-20181121-asdgsdf"
];

Test[
	CreateMatrix[3, 4]
	,
	{{1, 2, 3, 4}, {5, 6, 7, 8}, {9, 10, 11, 12}}
	,
	TestID -> "TensorOperations-20150811-Y4J6R0"
];

Test[
	CloneTensor[{}]
	,
	{}
	,
	TestID -> "TensorTestSuite-20190726-H3G2M8"
];

Test[
	CloneTensor[{3, 5, 7}]
	,
	{3, 5, 7}
	,
	TestID -> "TensorTestSuite-20190731-S6A1Q5"
];

Test[
	CloneTensor[{{3.6, 4.7}, {4.8, 3.9}}]
	,
	{{3.6, 4.7}, {4.8, 3.9}}
	,
	TestID -> "TensorTestSuite-20190731-V3L7J9"
];

Test[
	EmptyVector[]
	,
	{}
	,
	TestID -> "TensorTestSuite-20190731-Y9W4C9"
];

Test[
	Dimensions @ EmptyMatrix[]
	,
	{3, 5, 0}
	,
	TestID -> "TensorTestSuite-20190726-N5W9J1"
];

Test[
	TestDimensions[{}]
	,
	LibraryFunctionError["LIBRARY_DIMENSION_ERROR", 3]
	,
	LibraryFunction::dimerr
	,
	TestID -> "TensorTestSuite-20190729-X1X5Q8"
];

Test[
	Normal @* TestDimensions /@ {{0}, {3}, {3, 0}, {3, 2}, {3, 2, 0}, {3, 2, 4}}
	,
	{
		{},
		{0., 0., 0.},
		{{}, {}, {}},
		{{0., 0.}, {0., 0.}, {0., 0.}},
		{{{}, {}}, {{}, {}}, {{}, {}}},
		{{{0., 0., 0., 0.}, {0., 0., 0., 0.}}, {{0., 0., 0., 0.}, {0., 0., 0., 0.}}, {{0., 0., 0., 0.}, {0., 0., 0., 0.}}}
	}
	,
	TestID -> "TensorTestSuite-20190729-R3O9K3"
];

Test[
	Normal /@ List @@ TestDimensions2[]
	,
	{
		{},
		{0., 0., 0.},
		{{}, {}, {}},
		{{0., 0.}, {0., 0.}, {0., 0.}},
		{{{}, {}}, {{}, {}}, {{}, {}}},
		{{{0., 0., 0., 0.}, {0., 0., 0., 0.}}, {{0., 0., 0., 0.}, {0., 0., 0., 0.}}, {{0., 0., 0., 0.}, {0., 0., 0., 0.}}}
	}
	,
	TestID -> "TensorTestSuite-20190729-I2O3D2"
];


ExactTest[
	MeanValue[{2.2, 3.3, 4.4}]
	,
	3.3
	,
	TestID -> "TensorOperations-20150817-A4F7C6"
];

Test[
	IntegerMatrixTranspose[{{1, 2, 3}, {4, 5, 6}}]
	,
	{{1, 4}, {2, 5}, {3, 6}}
	,
	TestID -> "TensorOperations-20150817-L0F1J5"
];


(*
 Scalar operations on tensors
*)
TestExecute[
	getNthRealFromTR1 = LibraryFunctionLoad[lib, "getNthRealFromTR1", {{Real, 1}, Integer}, {Real}];
	getNthRealFromTR2 = LibraryFunctionLoad[lib, "getNthRealFromTR2", {{Real, 2}, Integer, Integer}, {Real}];
	getNthIntegerFromTR2 = LibraryFunctionLoad[lib, "getNthIntegerFromTR2", {{Integer, 2}, Integer, Integer}, {Integer}];
	setNthIntegerT = LibraryFunctionLoad[lib, "setNthIntegerT", {Integer}, {Integer, 1}];
	setI0I1T = LibraryFunctionLoad[lib, "setI0I1T", {{Integer, 1}, {Integer, 1}, Integer, Integer}, {Integer, 1}];
	getSubpartT = LibraryFunctionLoad[lib, "getSubpartT", {{Integer, 1}, Integer, Integer}, {Integer, 1}];
];

Test[
	getNthRealFromTR1[{1, 2, 3, 4.7}, 4]
	,
	4.7
	,
	TestID -> "TensorOperations-20150817-F9U7F4"
];

TestMatch[
	getNthRealFromTR1[{1, 2, 3, 4.7}, 100]
	,
	LibraryFunctionError["LIBRARY_USER_ERROR", n_] /; n < 0 (* even though we know what the error is, we cannot predict the error code *)
	,
	LibraryFunction::rterr
	,
	TestID -> "TensorOperations-20150817-Z2M1Q2"
];

ExactTest[
	getNthRealFromTR2[{{1, 2, 3}, {4, 5, 6}}, 1, 3]
	,
	3.
	,
	TestID -> "TensorOperations-20150817-N1I3G8"
];

ExactTest[
	getNthIntegerFromTR2[{{1, 2, 3}, {4, 5, 6}}, 1, 3]
	,
	3
	,
	TestID -> "TensorOperations-20150817-J6E5K2"
];

Test[
	setNthIntegerT[7]
	,
	{2, 4, 6, 8, 10, 12, 14}
	,
	TestID -> "TensorOperations-20150818-Y6F8K2"
];


(*
 Calling tensor API with shared data
*)
TestExecute[
	loadRealArray = LibraryFunctionLoad[lib, "loadRealArray", {{_, _, "Shared"}}, "Void"];
	getRealArray = LibraryFunctionLoad[lib, "getRealArray", {}, {Real, 1}];
	doubleRealArray = LibraryFunctionLoad[lib, "doubleRealArray", {}, {Real, 1}];
	unloadRealArray = LibraryFunctionLoad[lib, "unloadRealArray", {}, Integer];
	add1 = LibraryFunctionLoad[lib, "add1", {{Real, _, "Shared"}}, "Void"];
	copyShared = LibraryFunctionLoad[lib, "copyShared", {{Real, _, "Shared"}}, Integer];
];

Test[
	loadRealArray[Developer`ToPackedArray[{2.3, 4.5}]];
	getRealArray[]
	,
	{2.3, 4.5}
	,
	TestID -> "TensorOperations-20150819-F5H0C3"
];

TestMatch[
	loadRealArray[Range[10]];
	getRealArray[]
	,
	{2.3, 4.5}
	,
	{LibraryFunction::rterr}
	,
	TestID -> "TensorTestSuite-20190619-Q0I1G2"
];

Test[
	doubleRealArray[]
	,
	{4.6, 9.}
	,
	TestID -> "TensorOperations-20150819-R4E5S2"
];

Test[
	unloadRealArray[]
	,
	1
	,
	TestID -> "TensorOperations-20150819-D8C1Y0"
];

Test[
	t = RandomReal[1., {3, 5}];
	oldT = t;
	t += 0; (* now oldT becomes and actual copy of t and will not be affected by the next line *)
	add1[t];
	t
	,
	oldT + 1.
	,
	TestID -> "TensorOperations-20150831-LGONV3"
];

Test[
	copyShared[RandomReal[1., {3, 5}]]
	,
	110
	,
	TestID -> "TensorOperations-20150831-L0U3V3"
];

Test[
	FromVector[]
	,
	{{3, 5}, {7, 9}}
	,
	TestID -> "TensorTestSuite-20190906-N0T6L8"
];

Test[
	FlattenThroughVector[{{}, {}}]
	,
	{}
	,
	TestID -> "TensorTestSuite-20190910-R5I6P2"
];

Test[
	FlattenThroughVector[{{1, 2}, {3, 4}}]
	,
	{1, 2, 3, 4}
	,
	TestID -> "TensorTestSuite-20190910-P1O3G2"
];

Test[
	CopyThroughNumericArray[{{}, {}}]
	,
	{{}, {}}
	,
	TestID -> "TensorTestSuite-20190910-V9V4H1"
];

Test[
	CopyThroughNumericArray[{{1, 2}, {3, 4}}]
	,
	{{1, 2}, {3, 4}}
	,
	TestID -> "TensorTestSuite-20190910-Z7H8M8"
];

ExactTest[
	GetLargest[
		RandomInteger[1000, {100, 100}],
		RandomInteger[1000, {200, 100}],
		RandomReal[1., {200, 99}]
	]
	,
	1
	,
	TestID -> "TensorArrayTestSuite-20191127-E8Q1B9"
];

Test[
	ReverseTensor[Range[100]]
	,
	Reverse @ Range[100]
	,
	TestID -> "TensorTestSuite-20191129-A6J2D9"
];


Test[
	ReverseTensor[{{1.9, 2.8}, {3.7, 4.6}}]
	,
	{{4.6, 3.7}, {2.8, 1.9}}
	,
	TestID -> "TensorTestSuite-20191129-Y2C7M0"
];

EndRequirement[];