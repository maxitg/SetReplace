Package["SetReplace`"]

PackageImport["GeneralUtilities`"]

PackageExport["RasterizeExpressionAsOutput"]
PackageExport["RasterizeExpressionAsInput"]
PackageExport["RasterizeExpressionAsInputOutputPair"]
PackageExport["RasterizePreviousCell"]
PackageExport["ExportImageForEmbedding"]

SetUsage @ "
makeFormattedCodeBoxes[expr$] generates boxes representing expr$ as 'nicely formatted code'.
makeFormattedCodeBoxes[expr$, width$] imposes a particular character limit for line breaking.
* makeFormattedCodeBoxes will fully qualify all symbols apart from those in System`, GeneralUtilities`, and SetReplace`.
* makeFormattedCodeBoxes is HoldFirst, so it will not evaluate the code it is given to format.
"

SyntaxInformation[makeFormattedCodeBoxes] = {"ArgumentsPattern" -> {_, _.}};

SetAttributes[makeFormattedCodeBoxes, HoldFirst];

makeFormattedCodeBoxes[expr_, n_:60] := Block[
  {GeneralUtilities`Formatting`PackagePrivate`$prettyFormWidth = n,
   GeneralUtilities`PackageScope`$enableReflow = False},
  MakeFormattedBoxes[expr] /. symbol_String /;
    StringMatchQ[symbol, ("GeneralUtilities`" | "SetReplace`") ~~ Except["`"]..] :>
      StringExtract[symbol, "`" -> 2]
  (* MakeFormattedBoxes fully qualifies all symbols, we strip off these two since
  they are assumed to be on the user's context path *)
];

SetRelatedSymbolGroup[RasterizeExpressionAsOutput, RasterizeExpressionAsInput, RasterizeExpressionAsInputOutputPair, RasterizePreviousCell, ExportImageForEmbedding]

SyntaxInformation[rasterizeCell] = {"ArgumentsPattern" -> {_}};

SetUsage @ "
rasterizeCell[Cell[$$]] rasterizes a Cell expression, returning an Image.
rasterizeCell[{cell$1, cell$2, $$}] rasterize a list of cells, returning a \
single Image of them arranged vertically, as in a notebook.
* Cells of type \"Input\" have an additional In[] label attached.
* Cells of type \"Output\" have an additional Out[] label attached.
* Other cells will have no label attached.
"

rasterizeCell[cell_Cell] := Scope[
  image = bitmapToImage @ MathLink`CallFrontEnd @ ExportPacket[cell,
    "BitmapPacket", ColorSpace -> RGBColor, "AlphaChannel" -> False,
    "DataCompression" -> True, ImageResolution -> 144 (* 144, being 2x72, is the resolution for Retina displays *)
  ];
  If[!MemberQ[cell, ShowCellLabel -> False], 
    Switch[
      cellType @ cell,
      "Input",  image = imageRow[{$inputCellLabel, image}, Top],
      "Output", image = imageRow[{$outputCellLabel, image}, Center]
    ]
  ];
  image
];

rasterizeCell[cells:{___Cell}] := imageColumn @ Map[rasterizeCell, cells];

bitmapToImage[System`ConvertersDump`Bitmap[rawString_, {width_, height_, depth_}, ___]] := Scope[
  bytes = NumericArray[Developer`RawUncompress @ rawString, "Byte"];
  Internal`ArrayReshapeTo[bytes, {height, width, depth}];
  (* we use magnification of 1/2 to compensate for the double-resolution of retina display,
  ensuring the image *displays* at the normal size in the front end *)
  Image[Image`ReverseNumericArray[bytes, False], Interleaving -> True, Magnification -> 1/2]
]

toCell[expr_, type_] := Cell[
  BoxData[
      If[type === "Input",
        makeFormattedCodeBoxes @ expr,
        ToBoxes @ Unevaluated @ expr
      ]
  ],
  type, ShowCellBracket -> False, Background -> Automatic, CellMargins -> 0,
  CellFrameMargins -> 0, CellContext -> "Global`"
];

cellLabelToImage[text_] := With[
  {img = rasterizeCell @ Cell[text, "CellLabel", "CellLabelExpired"]},
  ImagePad[img, {{80 - ImageDimensions[img][[1]], 15}, {0, 10}}, White]];

$outputCellLabel := $outputCellLabel = cellLabelToImage["Out[\:f759\:f363]="];
$inputCellLabel := $inputCellLabel = cellLabelToImage["In[\:f759\:f363]:="];

SetUsage @ "
rasterizeExpression[expr$] creates an Image of expr$, formatted graphically.
* Graphics[$$], Graph[$$], etc. objects within expr$ are rendered in StandardForm.
* The Image is produced at high DPI, suitable for Retina displays.
* Unlike RasterizeExpressionAsOutput, the result does not include an In[] or Out[] label.
"

SyntaxInformation[rasterizeExpression] = {"ArgumentsPattern" -> {_}};

rasterizeExpression[expr_] := 
  rasterizeCell @ Append[ShowCellLabel -> False] @ toCell[Unevaluated @ expr, "Output"]

SetUsage @ "
RasterizeExpressionAsOutput[expr$] creates an Image of expr$, formatted graphically as an \"Output\" cell.
* Graphics[$$], Graph[$$], etc. objects within expr$ are rendered in StandardForm.
* The Image is produced at high DPI, suitable for Retina displays.
"

SyntaxInformation[RasterizeExpressionAsOutput] = {"ArgumentsPattern" -> {_}};

RasterizeExpressionAsOutput[expr_] := rasterizeCell @ toCell[Unevaluated @ expr, "Output"]

SetUsage @ "
RasterizeExpressionAsInput[expr$] creates an Image of expr$, formatted textually as an \"Input\" cell.
* RasterizeExpressionAsInput Holds expr$, preventing it from evaluating.
* RasterizeExpressionAsInput uses PrettyForm to automatically format the given input code.
* The Image is produced at high DPI, suitable for Retina displays.
"

SyntaxInformation[RasterizeExpressionAsInput] = {"ArgumentsPattern" -> {_}};

SetAttributes[{RasterizeExpressionAsInput, RasterizeExpressionAsInputOutputPair}, HoldFirst];

RasterizeExpressionAsInput[expr_] := rasterizeCell @ toCell[Unevaluated @ expr, "Input"]

imageColumn[images_, alignment_:Left, spacing_:20] := With[
  {width = Max[First /@ ImageDimensions /@ images]},
  ImageAssemble[
    {ImageCrop[#, {width, Full}, alignment, Padding -> White]} & /@ images,
    Spacings -> spacing, Background -> White, Magnification -> 1/2
  ]
];

imageRow[images_, alignment_, spacing_:0] := With[
  {height = Max[Last /@ ImageDimensions /@ images]},
  ImageAssemble[
    {ImageCrop[#, {Full, height}, alignment, Padding -> White] & /@ images},
    Spacings -> spacing, Background -> White, Magnification -> 1/2
  ]
];

SetUsage @ "
RasterizeExpressionAsInputOutputPair[expr$] creates an Image of expr$ formatted as both an input, \
and the corresponding resulting output expression.
* RasterizeExpressionAsInputOutputPair Holds expr$, preventing it from evaluating.
* RasterizeExpressionAsInput[expr$] is used to create the Image of the input.
* RasterizeExpressionAsOutput[expr$] is used to create the Image of the result.
* The Image is produced at high DPI, suitable for Retina displays.
"

SyntaxInformation[RasterizeExpressionAsInputOutputPair] = {"ArgumentsPattern" -> {_}};

RasterizeExpressionAsInputOutputPair[expr_] :=
  imageColumn @ {RasterizeExpressionAsInput[expr], RasterizeExpressionAsOutput[expr]};

cellType[Cell[_, type_, ___]] := type;
cellType[_] := None;

SetUsage @ "
RasterizePreviousCell[] will read the previous cell(s) from the current notebook \
and attempt to rasterize them.
* An input cell followed by an output cell will be rasterized together, similar to RasterizeExpressionAsInputOutputPair.
* Otherwise, the immediately preceding cell will be rasterized on its own.
* Use ExportImageForEmbedding['name$', RasterizePreviousCell[]] to save the previous cell(s) in an
image and copy a markdown-compatible <img> tag to the clipboard that displays this image.
"

SyntaxInformation[RasterizePreviousCell] = {"ArgumentsPattern" -> {}};

RasterizePreviousCell[] := Scope[
  prev1 = PreviousCell[]; prev2 = PreviousCell @ prev1;
  prev1 = NotebookRead[prev1]; prev2 = NotebookRead[prev2];
  If[Head[prev1] =!= Cell, Return[$Failed]];
  If[cellType[prev1] === "Output" && cellType[prev2] === "Input",
    rasterizeCell[{prev2, prev1}],
    rasterizeCell[prev1]
  ]
];

SetUsage @ "
ExportImageForEmbedding['path$', image$] saves image$ to file 'path$', and returns an HTML <img> tag that can
be pasted directly into a markdown file that includes the image. 
* 'path$' should be the absolute path to a CamelCased file name ending in .png.
* The image$ should be an Image[$$] produced by RasterizePreviousCell or the like.
* The resulting markdown will contain an absolute path relative to the root of the repository. It will \
correctly render on e.g. GitHub but may not render in e.g. VSCode.
* A path relative to the repository root can be provided if SetReplace was loaded from the repository rather than an installed paclet.
"

SyntaxInformation[ExportImageForEmbedding] = {"ArgumentsPattern" -> {_, _, OptionsPattern[]}};

ExportImageForEmbedding::noparentdir = "The parent directory \"``\" does not appear to exist.";
ExportImageForEmbedding::badfilename = "The name \"``\" should start with a capital letter, not contain any spaces, and end with '.png'.";
ExportImageForEmbedding::noexport = "The image could not be exported.";
ExportImageForEmbedding::paclet = "You have specified a relative path (``), but are using an installed, pacletized version of SetReplace (located at ``).
This means that ExportImageForEmbedding does not know where your development repo, and hence needs to be given a full path.";

$imageMarkdownTemplate = StringTemplate["<img src=\"``\" width=\"``\">"];

Options[ExportImageForEmbedding] = {
  CompressionLevel -> 1.0,
  Magnification -> 0.6,
  "ColorMapLength" -> Automatic
}

ExportImageForEmbedding[path_String, image_Image, OptionsPattern[]] := Scope[
  name = FileNameTake[path];
  If[name === "" || !UpperCaseQ[StringTake[name, 1]] || StringContainsQ[name, " "] || !StringEndsQ[name, ".png", IgnoreCase -> True], 
    ReturnFailed["badfilename", name]];
  If[StringContainsQ[path, "~"], path = ExpandFileName[path]];
  relativePathQ = StringStartsQ[path, LetterCharacter] && !($OperatingSystem == "Windows" && StringStartsQ[path, LetterCharacter ~~ ":\\"]);
  If[relativePathQ, 
    If[StringStartsQ[$SetReplaceBaseDirectory, {$UserBasePacletsDirectory, $BasePacletsDirectory}],
      ReturnFailed["paclet", $SetReplaceBaseDirectory]];
    If[StringFreeQ[path, $PathnameSeparator], 
      path = FileNameJoin[{"Documentation", "Images", path}]];
    path = FileNameJoin[{$SetReplaceBaseDirectory, path}];
  ];
  parentDir = FileNameDrop[path];
  If[!DirectoryQ[parentDir], ReturnFailed["noparentdir", parentDir]];
  UnpackOptions[compressionLevel, magnification, colorMapLength];
  result = Export[path, image, CompressionLevel -> compressionLevel, "ColorMapLength" -> colorMapLength];
  If[!StringQ[result], ReturnFailed["noexport"]];
  width = First @ ImageDimensions[image];
  relativePath = StringDrop[path, StringLength[findGitPath[parentDir]]];
  $imageMarkdownTemplate[relativePath, width * magnification]
]

findGitPath[path_] :=
  NestWhile[FileNameDrop, path, # =!= "" && !FileExistsQ[FileNameJoin[{#, ".git"}]]&]
