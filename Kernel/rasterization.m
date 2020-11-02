Package["SetReplace`"]

PackageImport["GeneralUtilities`"]

PackageExport["RasterizeAsOutput"]
PackageExport["RasterizeAsInput"]
PackageExport["RasterizeAsInputOutputPair"]

SetRelatedSymbolGroup[RasterizeAsOutput, RasterizeAsInput, RasterizeAsInputOutputPair]

cellToExportPacket[cell_] := ExportPacket[cell,
  "BitmapPacket", ColorSpace -> RGBColor, "AlphaChannel" -> False,
  "DataCompression" -> True, ImageResolution -> 144
];

bitmapToImage[System`ConvertersDump`Bitmap[rawString_, {width_, height_, depth_}, ___]] := Scope[
  bytes = NumericArray[Developer`RawUncompress @ rawString, "Byte"];
  Internal`ArrayReshapeTo[bytes, {height, width, depth}];
  Image[Image`ReverseNumericArray[bytes, False], Interleaving -> True, Magnification -> 0.5]
]

toCell[expr_, type_, isize_] := Cell[
  BoxData[If[type === "Input", PrettyFormBoxes @ expr, ToBoxes[Unevaluated @ expr]]],
  type, ShowCellBracket -> False, Background -> Automatic, CellMargins -> 0,
  CellFrameMargins -> 0, CellContext -> "Global`", 
  GraphicsBoxOptions -> {ImageSize -> isize}, Graphics3DBoxOptions -> {ImageSize -> isize}
];

rasterizeCell[cell_Cell] := 
	bitmapToImage @ MathLink`CallFrontEnd @ cellToExportPacket @ cell;

fastRasterize[expr_, type_:"Output", size_:Medium] := rasterizeCell @ toCell[Unevaluated @ expr, type, size];

cellLabelToImage[text_] := With[{img = rasterizeCell @ Cell[text, "CellLabel", "CellLabelExpired"]}, 
	ImagePad[img, {{80 - ImageDimensions[img][[1]], 15}, {0, 10}}, White]];
	
$outputCellLabel := $outputCellLabel = cellLabelToImage["Out[\:f759\:f363]="];
$inputCellLabel := $inputCellLabel = cellLabelToImage["In[\:f759\:f363]:="];

assembleWithLabel[label_, cell_] := ImageAssemble[{{label, cell}}, "Fit", Background -> White];

SetUsage @ "
RasterizeAsOutput[expr$] creates an Image of expr$, formatted graphically as an \"Output\" cell.
* Graphics[$$], Graph[$$], etc. objects within expr$ are rendered in StandardForm.
* The Image is produced at high DPI, suitable for Retina displays.
"

SyntaxInformation[RasterizeAsOutput] = {"ArgumentsPattern" -> {_}};

RasterizeAsOutput[expr_] := assembleWithLabel[$outputCellLabel, fastRasterize[expr, "Output"]];

SetUsage @ "
RasterizeAsInput[expr$] creates an Image of expr$, formatted textually as an \"Input\" cell.
* RasterizeAsInput Holds expr$, preventing it from evaluating.
* RasterizeAsInput uses PrettyForm to automatically format the given input code.
* The Image is produced at high DPI, suitable for Retina displays.
"

SyntaxInformation[RasterizeAsInput] = {"ArgumentsPattern" -> {_}};

SetAttributes[{RasterizeAsInput, RasterizeAsInputOutputPair}, HoldFirst];
RasterizeAsInput[expr_] := assembleWithLabel[$inputCellLabel, fastRasterize[Unevaluated @ expr, "Input"]];

imageColumn[images_] := With[
  {width = Max[First /@ ImageDimensions /@ images]}, 
  ImageAssemble[{ImageCrop[#, {width, Full}, Left, Padding -> White]}& /@ images]
];

SetUsage @ "
RasterizeAsInputOutputPair[expr$] creates an Image of expr$ formatted as both an input, \
and the corresponding resulting output expression.
* RasterizeAsInputOutputPair Holds expr$, preventing it from evaluating.
* RasterAsInput[expr$] is used to create the Image of the input.
* RasterAsOutput[expr$] is used to create the Image of the result.
* The Image is produced at high DPI, suitable for Retina displays.
"

SyntaxInformation[RasterizeAsInputOutputPair] = {"ArgumentsPattern" -> {_}};

RasterizeAsInputOutputPair[expr_] := imageColumn[{RasterizeAsInput[expr], RasterizeAsOutput[expr]}];