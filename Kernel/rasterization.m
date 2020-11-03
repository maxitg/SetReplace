Package["SetReplace`"]

PackageImport["GeneralUtilities`"]

PackageExport["RasterizeAsOutput"]
PackageExport["RasterizeAsInput"]
PackageExport["RasterizeAsInputOutputPair"]
PackageExport["ExportImageForEmbedding"]

SetRelatedSymbolGroup[RasterizeAsOutput, RasterizeAsInput, RasterizeAsInputOutputPair, ExportImageForEmbedding]

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
  ImageAssemble[{ImageCrop[#, {width, Full}, Left, Padding -> White]} & /@ images, opts]
];

SetUsage @ "
RasterizeAsInputOutputPair[expr$] creates an Image of expr$ formatted as both an input, \
and the corresponding resulting output expression.
* RasterizeAsInputOutputPair Holds expr$, preventing it from evaluating.
* RasterizeAsInput[expr$] is used to create the Image of the input.
* RasterizeAsOutput[expr$] is used to create the Image of the result.
* The Image is produced at high DPI, suitable for Retina displays.
"

SyntaxInformation[RasterizeAsInputOutputPair] = {"ArgumentsPattern" -> {_}};

RasterizeAsInputOutputPair[expr_] := 
  imageColumn[{RasterizeAsInput[expr], RasterizeAsOutput[expr]}, Magnification -> 1/2];

SetUsage @ "
ExportImageForEmbedding['name$', image$] saves image$ to the correct location in \
the documentation directory under the 'name$.png', and returns an HTML <img> tag that can
be pasted directly into a markdown file that includes the image.
* The 'name$' should be a CamelCased, descriptive string, not including a file extension.
* The image$ should be an Image[$$] produced by e.g. RasterizeAsOutput or RasterizeAsInputOutputPair.
* The resulting markdown is an absolute path, based on the root of the repository. It will \
correctly render on e.g. GitHub but may not render in e.g. VSCode.
* The resulting markdown is placed on the system clipboard, ready to be pasted into a file.
"

SyntaxInformation[ExportImageForEmbedding] = {"ArgumentsPattern" -> {_String, _Image}};

ExportImageForEmbedding::nodot = "The name \"``\" should not contain a file extension, since one will be added automatically.";
ExportImageForEmbedding::notcap = "The name \"``\" should start with a capital letter and not contain any spaces.";
ExportImageForEmbedding::noexport = "The image could not be exported.";

$ImagesDirectory = FileNameJoin[{$SetReplaceBaseDirectory, "Documentation", "Images"}];
$ImageMarkdownTemplate = StringTemplate["<img src=\"/Documentation/Images/``\" width=\"``\">"];

ExportImageForEmbedding[name_String, image_Image, opts:OptionsPattern[]] := Scope[
  If[StringContainsQ[name, "."], ReturnFailed["nodot", name]];
  If[name === "" || !UpperCaseQ[StringTake[name, 1]] || StringContainsQ[name, " "], ReturnFailed["notcap", name]];
  filename = name <> ".png";
  path = FileNameJoin[{$ImagesDirectory, filename}];
  result = Export[path, image, opts, CompressionLevel -> 1.0];
  If[!StringQ[result], ReturnFailed["noexport"]];
  width = First @ ImageDimensions[image];
  markdown = $ImageMarkdownTemplate[filename, width / 2.];
  If[$Notebooks, CopyToClipboard[markdown]];
  markdown
]
