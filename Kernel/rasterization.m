Package["SetReplace`"]

PackageImport["GeneralUtilities`"]

PackageExport["RasterizeAsOutput"]
PackageExport["RasterizeAsInput"]
PackageExport["RasterizeAsInputOutputPair"]

SetRelatedSymbolGroup[RasterizeAsOutput, RasterizeAsInput, RasterizeAsInputOutputPair]

rasterizeCell[cell_] := bitmapToImage @ MathLink`CallFrontEnd @ ExportPacket[cell,
  "BitmapPacket", ColorSpace -> RGBColor, "AlphaChannel" -> False,
  "DataCompression" -> True, ImageResolution -> 144 (* 144, being 2x72, is the resolution for Retina displays *)
];

bitmapToImage[System`ConvertersDump`Bitmap[rawString_, {width_, height_, depth_}, ___]] := Scope[
  bytes = NumericArray[Developer`RawUncompress @ rawString, "Byte"];
  Internal`ArrayReshapeTo[bytes, {height, width, depth}];
  (* we use magnification of 1/2 to compensate for the double-resolution of retina display,
  ensuring the image *displays* at the normal size in the front end *)
  Image[Image`ReverseNumericArray[bytes, False], Interleaving -> True, Magnification -> 1/2]
]

toCell[expr_, type_, isize_] := Cell[
  BoxData[If[type === "Input", PrettyFormBoxes @ expr, ToBoxes[Unevaluated @ expr]]],
  type, ShowCellBracket -> False, Background -> Automatic, CellMargins -> 0,
  CellFrameMargins -> 0, CellContext -> "Global`", 
  GraphicsBoxOptions -> {ImageSize -> isize}, Graphics3DBoxOptions -> {ImageSize -> isize}
];

rasterizeExpr[expr_, type_:"Output"] := 
  rasterizeCell @ toCell[Unevaluated @ expr, type, Small];

cellLabelToImage[text_] := With[{img = rasterizeCell @ Cell[text, "CellLabel", "CellLabelExpired"]}, 
	ImagePad[img, {{80 - ImageDimensions[img][[1]], 15}, {0, 10}}, White]];
	
$outputCellLabel := $outputCellLabel = cellLabelToImage["Out[\:f759\:f363]="];
$inputCellLabel := $inputCellLabel = cellLabelToImage["In[\:f759\:f363]:="];

assembleWithLabel[label_, cell_] := 
  ImageAssemble[{{label, cell}}, "Fit", Background -> White, Magnification -> 1/2];

SetUsage @ "
RasterizeAsOutput[expr$] creates an Image of expr$, formatted graphically as an \"Output\" cell.
* Graphics[$$], Graph[$$], etc. objects within expr$ are rendered in StandardForm.
* The Image is produced at high DPI, suitable for Retina displays.
"

SyntaxInformation[RasterizeAsOutput] = {"ArgumentsPattern" -> {_}};

RasterizeAsOutput[expr_] := 
  assembleWithLabel[$outputCellLabel, rasterizeExpr[expr, "Output"]];

SetUsage @ "
RasterizeAsInput[expr$] creates an Image of expr$, formatted textually as an \"Input\" cell.
* RasterizeAsInput Holds expr$, preventing it from evaluating.
* RasterizeAsInput uses PrettyForm to automatically format the given input code.
* The Image is produced at high DPI, suitable for Retina displays.
"

SyntaxInformation[RasterizeAsInput] = {"ArgumentsPattern" -> {_}};

SetAttributes[{RasterizeAsInput, RasterizeAsInputOutputPair}, HoldFirst];
RasterizeAsInput[expr_] := 
  assembleWithLabel[$inputCellLabel, rasterizeExpr[Unevaluated @ expr, "Input"]];

imageColumn[images_, opts___Rule] := With[
  {width = Max[First /@ ImageDimensions /@ images]}, 
  ImageAssemble[{ImageCrop[#, {width, Full}, Left, Padding -> White]}& /@ images, opts]
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

RasterizeAsInputOutputPair[expr_] := 
  imageColumn[{RasterizeAsInput[expr], RasterizeAsOutput[expr]}, Magnification -> 1/2];
