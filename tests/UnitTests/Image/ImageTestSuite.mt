(* Wolfram Language Test file *)
TestRequirement[$VersionNumber >= 12];
(***************************************************************************************************************************************)
(*
	Set of test cases to test LLU functionality related to handling and exchanging images
*)
(***************************************************************************************************************************************)
TestExecute[
	Needs["CCompilerDriver`"];
	currentDirectory = DirectoryName[$TestFileName];

	(* Get configuration (path to LLU sources, compilation options, etc.) *)
	Get[FileNameJoin[{ParentDirectory[currentDirectory], "TestConfig.wl"}]];

	(* Compile the test library *)
	lib = CCompilerDriver`CreateLibrary[
		FileNameJoin[{currentDirectory, "TestSources", #}]& /@ {"EchoImage.cpp", "ImageDimensions.cpp", "ImageNegate.cpp"},
		"ImageTest",
		options (* defined in TestConfig.wl *)
	];

	Get[FileNameJoin[{$LLUSharedDir, "LibraryLinkUtilities.wl"}]];
	`LLU`InitializePacletLibrary[lib];

	EchoImage1 = `LLU`PacletFunctionLoad["EchoImage1", { LibraryDataType[Image | Image3D] }, LibraryDataType[Image | Image3D] ];
	EchoImage2 = `LLU`PacletFunctionLoad["EchoImage2", { LibraryDataType[Image | Image3D] }, LibraryDataType[Image | Image3D] ];
	EchoImage3 = `LLU`PacletFunctionLoad["EchoImage3", { LibraryDataType[Image | Image3D] }, LibraryDataType[Image | Image3D] ];
	ConvertImageToByte = `LLU`PacletFunctionLoad["ConvertImageToByte", { LibraryDataType[Image | Image3D] }, LibraryDataType[Image | Image3D] ];
	UnifyImageTypes = `LLU`PacletFunctionLoad["UnifyImageTypes", { LibraryDataType[Image | Image3D], LibraryDataType[Image | Image3D] }, LibraryDataType[Image | Image3D]];
	CloneImage = `LLU`PacletFunctionLoad["CloneImage", { LibraryDataType[Image | Image3D] }, LibraryDataType[Image | Image3D] ];
	EmptyWrapper = `LLU`PacletFunctionLoad["EmptyWrapper", {}, "Void" ];

	ImageNegate = `LLU`PacletFunctionLoad["ImageNegate", { LibraryDataType[Image | Image3D] }, LibraryDataType[Image | Image3D] ];
	NegateImages = `LLU`PacletFunctionLoad["NegateImages", { "DataStore" }, "DataStore"];

	ImageColumnCount = `LLU`PacletFunctionLoad["ImageColumnCount", { LibraryDataType[Image | Image3D] }, Integer ];
	ImageRowCount = `LLU`PacletFunctionLoad["ImageRowCount", { LibraryDataType[Image | Image3D] }, Integer ];
	ImageRank = `LLU`PacletFunctionLoad["ImageRank", {LibraryDataType[Image | Image3D] }, Integer ];
	GetLargest = `LLU`PacletFunctionLoad["GetLargest", {Image, {Image, "Constant"}, {Image, "Manual"}}, Integer];
	EmptyView = `LLU`PacletFunctionLoad["EmptyView", {}, {Integer, 1}];
];


(*
	Tests for "Bit" Images
*)
TestExecute[
	testImage = Image[{{0.1, 0.2, 0.3}, {0.4, 0.5, 0.6}, {0.7, 0.7, 0.9}, {0., 0.8, 0.}}, "Bit"];
	testImage3D = Image3D[{{{0.1, 0.2}, {0.3, 0.4}, {0.5, 0.6}}, {{0.7, 0.7}, {0.9, 0.}, {0.8, 0.}}}, "Bit"];
];

Test[
	res = EchoImage1[Image[{{1}}, "Bit"]];
	And[ImageType[res] === "Bit", ImageData[res] === {{1}}]
	,
	True
	,
	TestID -> "ImageBitOperations-20150731-H7U4V0"
];

Test[
	res = EchoImage1[testImage3D];
	And[ImageType[res] === "Bit", res == testImage3D]
	,
	True
	,
	TestID -> "ImageBitOperations-20170801-F6T0X6"
];

Test[
	res = EchoImage2[testImage];
	And[SameQ[ImageType[testImage], ImageType[res]],
		SameQ[ImageData[testImage], ImageData[res]],
		SameQ[ImageChannels[testImage], ImageChannels[res]],
		SameQ[ImageColorSpace[testImage], ImageColorSpace[res]]
	]
	,
	True
	,
	TestID -> "ImageBitOperations-20150731-M0R8N3"
];

Test[
	res = EchoImage3[testImage3D];
	And[SameQ[ImageType[testImage3D], ImageType[res]],
		SameQ[ImageData[testImage3D], ImageData[res]],
		SameQ[ImageChannels[testImage3D], ImageChannels[res]],
		SameQ[ImageColorSpace[testImage3D], ImageColorSpace[res]]
	]
	,
	True
	,
	TestID -> "ImageTestSuite-20190618-S9B1D3"
];


Test[
	ConvertImageToByte[testImage]
	,
	Image[testImage, "Byte"]
	,
	TestID -> "ImageBitOperations-20170904-J4P2U1"
];


Test[
	ConvertImageToByte[testImage3D]
	,
	Image3D[testImage3D, "Byte"]
	,
	TestID -> "ImageBitOperations-20170904-U9Q4T8"
];

Test[
	UnifyImageTypes[ConvertImageToByte[testImage3D], testImage]
	,
	Image[testImage, "Byte"]
	,
	TestID -> "ImageBitOperations-20170904-M7Y3X8"
];


Test[
	UnifyImageTypes[ConvertImageToByte[testImage], testImage3D]
	,
	Image3D[testImage3D, "Byte"]
	,
	TestID -> "ImageBitOperations-20170904-O5V0V7"
];

Test[
	CloneImage[testImage]
	,
	testImage
	,
	TestID -> "ImageBit16Operations-20190731-I9W1X5"
];

Test[
	CloneImage[testImage3D]
	,
	testImage3D
	,
	TestID -> "ImageBit16Operations-20190731-O2B9I8"
];

TestMatch[
	Catch[EmptyWrapper[], _]
	,
	Failure["CreateFromNullError", <|
		"MessageTemplate" -> "Attempting to create a generic container from nullptr.",
		"MessageParameters" -> <||>,
		"ErrorCode" -> _?CppErrorCodeQ,
		"Parameters" -> {}|>
	]
	,
	TestID -> "ImageTestSuite-20190819-G2I1N4"
];

Test[
	ImageNegate[Image[{{1}}, "Bit"]] // ImageData
	,
	{{0}}
	,
	TestID -> "ImageBitOperations-20150803-D9E4U5"
];

Test[
	ImageNegate[testImage3D] === ColorNegate[testImage3D]
	,
	True
	,
	TestID -> "ImageBitOperations-20170804-P8M8S1"
];

ExactTest[
	ImageRowCount[testImage]
	,
	4
	,
	TestID -> "ImageBitOperations-20150803-W2O8G4"
];

ExactTest[
	ImageRowCount[testImage3D]
	,
	3
	,
	TestID -> "ImageBitOperations-20170801-A8P2V0"
];

ExactTest[
	ImageColumnCount[testImage]
	,
	3
	,
	TestID -> "ImageBitOperations-20150803-U7I6G8"
];

ExactTest[
	ImageColumnCount[testImage3D]
	,
	2
	,
	TestID -> "ImageBitOperations-20170801-X2K8A4"
];

ExactTest[
	ImageRank[testImage]
	,
	2
	,
	TestID -> "ImageBitOperations-20150805-D1S6E6"
];

ExactTest[
	ImageRank[testImage3D]
	,
	3
	,
	TestID -> "ImageBitOperations-20170801-M1A4H7"
];


(*
	Tests for "Byte" Images
*)
TestExecute[
	testImage = Image[ {{0, 63, 127, 191, 255}, {0, 50, 100, 150, 200}}, "Byte"];
	testImage3D = Image3D[{{{65, 0}, {34, 56}, {233, 1}}, {{255, 10}, {9, 0}, {55, 52}}}, "Byte"];
];

Test[
	res = EchoImage1[testImage3D];
	And[ImageType[res] === "Byte", Length @ Image3DSlices[res] === 2]
	,
	True
	,
	TestID -> "ImageByteOperations-20150731-H7U4V0"
];

Test[
	res = EchoImage1[Image[{{60}}, "Byte"]];
	And[ImageType[res] === "Byte", ImageData[res, "Byte"] === {{60}}]
	,
	True
	,
	TestID -> "ImageByteOperations-20170804-Y7S1M7"
];

Test[
	res = EchoImage2[testImage];
	And[SameQ[ImageType[testImage], ImageType[res]],
		SameQ[ImageData[testImage, "Byte"], ImageData[res, "Byte"]],
		SameQ[ImageChannels[testImage], ImageChannels[res]],
		SameQ[ImageColorSpace[testImage], ImageColorSpace[res]]
	]
	,
	True
	,
	TestID -> "ImageByteOperations-20150731-M0R8N3"
];

Test[
	res = EchoImage3[testImage3D];
	And[SameQ[ImageType[testImage3D], ImageType[res]],
		SameQ[ImageData[testImage3D], ImageData[res]],
		SameQ[ImageChannels[testImage3D], ImageChannels[res]],
		SameQ[ImageColorSpace[testImage3D], ImageColorSpace[res]]
	]
	,
	True
	,
	TestID -> "ImageTestSuite-20190618-T3U5T6"
];


Test[
	res = EchoImage2[testImage3D];
	And[SameQ[ImageType[testImage3D], ImageType[res]],
		SameQ[ImageData[testImage3D, "Byte"], ImageData[res, "Byte"]],
		SameQ[ImageChannels[testImage3D], ImageChannels[res]],
		SameQ[ImageColorSpace[testImage3D], ImageColorSpace[res]]
	]
	,
	True
	,
	TestID -> "ImageByteOperations-20170804-S2G4R2"
];

Test[
	res = ImageNegate[Image[{{70}}, "Byte"]];
	ImageData[res, "Byte"]
	,
	{{185}}
	,
	TestID -> "ImageByteOperations-20150803-D9E4U5"
];

Test[
	ImageNegate[testImage3D] === ColorNegate[testImage3D]
	,
	True
	,
	TestID -> "ImageByteOperations-20170804-P8M8S1"
];

ExactTest[
	ImageRowCount[testImage]
	,
	2
	,
	TestID -> "ImageByteOperations-20150803-W2O8G4"
];

ExactTest[
	ImageRowCount[testImage3D]
	,
	3
	,
	TestID -> "ImageByteOperations-20170804-Z9A3L4"
];

ExactTest[
	ImageColumnCount[testImage]
	,
	5
	,
	TestID -> "ImageByteOperations-20170804-X1E1E1"
];

ExactTest[
	ImageColumnCount[testImage3D]
	,
	2
	,
	TestID -> "ImageByteOperations-20170804-H9L6J9"
];


ExactTest[
	ImageRank[testImage]
	,
	2
	,
	TestID -> "ImageByteOperations-20150805-E4V0X3"
];

ExactTest[
	ImageRank[testImage3D]
	,
	3
	,
	TestID -> "ImageByteOperations-20170804-T5K0Q6"
];


(*
	Tests for "Bit16" Images
*)
TestExecute[
	testImage = Image[{{0, 63000, 1270, 1910, 25550}, {0, 5000, 10000, 15700, 2000}}, "Bit16"];
	testImage3D = Image3D[{{{65535, 0}, {3456, 5678}, {23345, 1}}, {{23425, 10}, {9, 0}, {55555, 5234}}}, "Bit16"];
];

Test[
	res = EchoImage1[Image[{{5666}}, "Bit16"]];
	And[ImageType[res] === "Bit16", ImageData[res, "Bit16"] === {{5666}}]
	,
	True
	,
	TestID -> "ImageBit16Operations-20150731-H7U4V0"
];

Test[
	res = EchoImage1[testImage3D];
	And[ImageType[res] === "Bit16", (Length @ Image3DSlices[res]) === 2]
	,
	True
	,
	TestID -> "ImageBit16Operations-20170804-L9E1H5"
];

Test[
	res = EchoImage2[testImage];
	And[SameQ[ImageType[testImage], ImageType[res]],
		SameQ[ImageData[testImage, "Bit16"], ImageData[res, "Bit16"]],
		SameQ[ImageChannels[testImage], ImageChannels[res]],
		SameQ[ImageColorSpace[testImage], ImageColorSpace[res]]
	]
	,
	True
	,
	TestID -> "ImageBit16Operations-20150731-M0R8N3"
];

Test[
	res = EchoImage2[testImage3D];
	And[SameQ[ImageType[testImage3D], ImageType[res]],
		SameQ[ImageData[testImage3D, "Bit16"], ImageData[res, "Bit16"]],
		SameQ[ImageChannels[testImage3D], ImageChannels[res]],
		SameQ[ImageColorSpace[testImage3D], ImageColorSpace[res]]
	]
	,
	True
	,
	TestID -> "ImageBit16Operations-20170804-J6D3N1"
];

Test[
	res = EchoImage3[testImage3D];
	And[SameQ[ImageType[testImage3D], ImageType[res]],
		SameQ[ImageData[testImage3D], ImageData[res]],
		SameQ[ImageChannels[testImage3D], ImageChannels[res]],
		SameQ[ImageColorSpace[testImage3D], ImageColorSpace[res]]
	]
	,
	True
	,
	TestID -> "ImageTestSuite-20190618-H3L0K4"
];

Test[
	ConvertImageToByte[testImage]
	,
	Image[testImage, "Byte"]
	,
	TestID -> "ImageBit16Operations-20170904-J4P2U1"
];


Test[
	ConvertImageToByte[testImage3D]
	,
	Image3D[testImage3D, "Byte"]
	,
	TestID -> "ImageBit16Operations-20170904-U9Q4T8"
];

Test[
	UnifyImageTypes[ConvertImageToByte[testImage3D], testImage]
	,
	Image[testImage, "Byte"]
	,
	TestID -> "ImageBit16Operations-20170904-M7Y3X8"
];


Test[
	UnifyImageTypes[ConvertImageToByte[testImage], testImage3D]
	,
	Image3D[testImage3D, "Byte"]
	,
	TestID -> "ImageBit16Operations-20170904-O5V0V7"
];

Test[
	res = ImageNegate[Image[{{0}}, "Byte"]];
	ImageData[res, "Bit16"]
	,
	{{65535}}
	,
	TestID -> "ImageBit16Operations-20150803-D9E4U5"
];

Test[
	ImageNegate[testImage3D] === ColorNegate[testImage3D]
	,
	True
	,
	TestID -> "ImageBit16Operations-20170804-P8M8S1"
];

ExactTest[
	ImageRowCount[testImage]
	,
	2
	,
	TestID -> "ImageBit16Operations-20150803-W2O8G4"
];

ExactTest[
	ImageRowCount[testImage3D]
	,
	3
	,
	TestID -> "ImageBit16Operations-20170804-Y8O1D1"
];

ExactTest[
	ImageColumnCount[testImage]
	,
	5
	,
	TestID -> "ImageBit16Operations-20150803-V5C3R0"
];

ExactTest[
	ImageColumnCount[testImage3D]
	,
	2
	,
	TestID -> "ImageBit16Operations-20170804-Z6Z7O7"
];

ExactTest[(*test rank of 2d image*)
	ImageRank[testImage]
	,
	2
	,
	TestID -> "ImageBit16Operations-20150805-R9H3F8"
];

ExactTest[(*test rank of 2d image*)
	ImageRank[testImage3D]
	,
	3
	,
	TestID -> "ImageBit16Operations-20170804-T4I3M7"
];


(*
	Tests for "Real32" Images
*)
TestExecute[
	testImage = Image[{{0., .3, .42, .99, .67}, {0., .5, .8, .31, .2}}, "Real32"];
	testImage3D = Image3D[{{{0.1, 0.2}, {0.3, 0.4}, {0.5, 0.6}}, {{0.7, 0.7}, {0.9, 0.}, {0.8, 0.}}}, "Real32"];
	real32 = 1.;
];

Test[
	res = EchoImage1[Image[{{real32}}, "Real32"]];
	And[ImageType[res] === "Real32", ImageData[res, "Real32"] === {{real32}}]
	,
	True
	,
	TestID -> "ImageReal32Operations-20150731-H7U4V0"
];

Test[
	res = EchoImage1[testImage3D];
	And[ImageType[res] === "Real32", Length @ Image3DSlices[res] === 2]
	,
	True
	,
	TestID -> "ImageReal32Operations-20170804-E8S0A7"
];

Test[
	res = EchoImage2[testImage];
	And[SameQ[ImageType[testImage], ImageType[res]],
		SameQ[ImageData[testImage, "Real32"], ImageData[res, "Real32"]],
		SameQ[ImageChannels[testImage], ImageChannels[res]],
		SameQ[ImageColorSpace[testImage], ImageColorSpace[res]]
	]
	,
	True
	,
	TestID -> "ImageReal32Operations-20150731-M0R8N3"
];

Test[
	res = EchoImage2[testImage3D];
	And[SameQ[ImageType[testImage3D], ImageType[res]],
		SameQ[ImageData[testImage3D, "Real32"], ImageData[res, "Real32"]],
		SameQ[ImageChannels[testImage3D], ImageChannels[res]],
		SameQ[ImageColorSpace[testImage3D], ImageColorSpace[res]]
	]
	,
	True
	,
	TestID -> "ImageReal32Operations-20170804-Z8J1C6"
];

Test[
	res = EchoImage3[testImage3D];
	And[SameQ[ImageType[testImage3D], ImageType[res]],
		SameQ[ImageData[testImage3D], ImageData[res]],
		SameQ[ImageChannels[testImage3D], ImageChannels[res]],
		SameQ[ImageColorSpace[testImage3D], ImageColorSpace[res]]
	]
	,
	True
	,
	TestID -> "ImageTestSuite-20190618-A8K2M2"
];

Test[
	ConvertImageToByte[testImage]
	,
	Image[testImage, "Byte"]
	,
	TestID -> "ImageReal32Operations-20170904-J4P2U1"
];


Test[
	ConvertImageToByte[testImage3D]
	,
	Image3D[testImage3D, "Byte"]
	,
	TestID -> "ImageReal32Operations-20170904-U9Q4T8"
];

Test[
	UnifyImageTypes[ConvertImageToByte[testImage3D], testImage]
	,
	Image[testImage, "Byte"]
	,
	TestID -> "ImageReal32Operations-20170904-M7Y3X8"
];


Test[
	UnifyImageTypes[ConvertImageToByte[testImage], testImage3D]
	,
	Image3D[testImage3D, "Byte"]
	,
	TestID -> "ImageReal32Operations-20170904-O5V0V7"
];

ExactTest[
	ImageRowCount[testImage]
	,
	2
	,
	TestID -> "ImageReal32Operations-20150803-W2O8G4"
];

ExactTest[
	ImageRowCount[testImage3D]
	,
	3
	,
	TestID -> "ImageReal32Operations-20170804-A6E4X9"
];

ExactTest[
	ImageColumnCount[testImage]
	,
	5
	,
	TestID -> "ImageReal32Operations-20150803-V5C3R0"
];

ExactTest[
	ImageColumnCount[testImage3D]
	,
	2
	,
	TestID -> "ImageReal32Operations-20170804-T8M6T5"
];

ExactTest[
	ImageRank[testImage]
	,
	2
	,
	TestID -> "ImageReal32Operations-20150805-V5N6L6"
];

ExactTest[
	ImageRank[testImage3D]
	,
	3
	,
	TestID -> "ImageReal32Operations-20170804-W2H3Q6"
];


(*
	Tests for "Real64" Images
*)
TestExecute[
	testImage = Image[{{.6, .5, .3}, {.8, .1, .4}}, "Real"];
	real32Num = 1.;
];

Test[
	res = EchoImage1[Image[{{real32Num}}, "Real"]];
	And[ImageType[res] === "Real64", ImageData[res, "Real"] === {{real32Num}}]
	,
	True
	,
	TestID -> "ImageRealOperations-20150731-H7U4V0"
];

Test[
	res = EchoImage2[testImage];
	And[SameQ[ImageType[testImage], ImageType[res]],
		SameQ[ImageData[testImage, "Real"], ImageData[res, "Real"]],
		SameQ[ImageChannels[testImage], ImageChannels[res]],
		SameQ[ImageColorSpace[testImage], ImageColorSpace[res]]
	]
	,
	True
	,
	TestID -> "ImageRealOperations-20150731-M0R8N3"
];

Test[
	res = EchoImage3[testImage3D];
	And[SameQ[ImageType[testImage3D], ImageType[res]],
		SameQ[ImageData[testImage3D], ImageData[res]],
		SameQ[ImageChannels[testImage3D], ImageChannels[res]],
		SameQ[ImageColorSpace[testImage3D], ImageColorSpace[res]]
	]
	,
	True
	,
	TestID -> "ImageTestSuite-20190618-F5T5X2"
];

Test[
	ConvertImageToByte[testImage]
	,
	Image[testImage, "Byte"]
	,
	TestID -> "ImageRealOperations-20170904-J4P2U1"
];


Test[
	ConvertImageToByte[testImage3D]
	,
	Image3D[testImage3D, "Byte"]
	,
	TestID -> "ImageRealOperations-20170904-U9Q4T8"
];

Test[
	UnifyImageTypes[ConvertImageToByte[testImage3D], testImage]
	,
	Image[testImage, "Byte"]
	,
	TestID -> "ImageRealOperations-20170904-M7Y3X8"
];


Test[
	UnifyImageTypes[ConvertImageToByte[testImage], testImage3D]
	,
	Image3D[testImage3D, "Byte"]
	,
	TestID -> "ImageRealOperations-20170904-O5V0V7"
];

ExactTest[
	ImageRowCount[testImage]
	,
	2
	,
	TestID -> "ImageRealOperations-20150803-W2O8G4"
];

ExactTest[
	ImageColumnCount[testImage]
	,
	3
	,
	TestID -> "ImageRealOperations-20150803-V5C3R0"
];

ExactTest[
	ImageRank[testImage]
	,
	2
	,
	TestID -> "ImageRealOperations-20150805-Z0C1B7"
];

ExactTest[
	GetLargest[RandomImage[1, {100, 100}], RandomImage[1, {200, 100}], RandomImage[1, {200, 99}]]
	,
	1
	,
	TestID -> "ImageTestSuite-20191127-E8Q1B9"
];

ExactTest[
	EmptyView[]
	,
	{-1, -1, -1, -1, -1}
	,
	TestID -> "ImageTestSuite-20191127-H2I2Z7"
];

Test[
	im1 = Image[{{0., .3, .42, .99, .67}, {0., .5, .8, .31, .2}}, "Real32"];
	im2 = Image3D[{{{65, 0}, {34, 56}, {233, 1}}, {{255, 10}, {9, 0}, {55, 52}}}, "Byte"];
	im3 = Image[{{0.1, 0.2, 0.3}, {0.4, 0.5, 0.6}, {0.7, 0.7, 0.9}, {0., 0.8, 0.}}, "Bit"];
	List @@ (NegateImages @ Developer`DataStore[im1, im2, im3])
	,
	ColorNegate /@ {im1, im2, im3}
	,
	TestID -> "ImageTestSuite-20191128-C0N1O1"
]