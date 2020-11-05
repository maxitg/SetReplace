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
ExportImageForEmbedding['name$', image$] saves image$ to the correct location in \
the documentation directory under the 'name$.png', and returns an HTML <img> tag that can
be pasted directly into a markdown file that includes the image.
* The 'name$' should be a CamelCased, descriptive string, not including a file extension.
* The image$ should be an Image[$$] produced by e.g. RasterizeExpressionAsOutput or RasterizeExpressionAsInputOutputPair.
* The resulting markdown is an absolute path, based on the root of the repository. It will \
correctly render on e.g. GitHub but may not render in e.g. VSCode.
* The resulting markdown is placed on the system clipboard, ready to be pasted into a file.
"

SyntaxInformation[ExportImageForEmbedding] = {"ArgumentsPattern" -> {_, _, OptionsPattern[]}};

ExportImageForEmbedding::nodot = "The name \"``\" should not contain a file extension, since one will be added automatically.";
ExportImageForEmbedding::notcap = "The name \"``\" should start with a capital letter and not contain any spaces.";
ExportImageForEmbedding::noexport = "The image could not be exported.";
ExportImageForEmbedding::paclet = "You have apparently loaded an installed, pacletized version of SetReplace (located at ``).
This means that ExportImageForEmbedding does not know where your development directory is, and hence where to save images.
Either load SetReplace directly from the Git repo, using e.g. Get[\"~/git/SetReplace/Kernel/init.m\"], or provide the directory \
of your checkout of the Git repository manually using the \"DevelopmentDirectory\" option.";
ExportImageForEmbedding::baddevdir = "The provided development directory `` does not exist or is not a string."
ExportImageForEmbedding::noimgpath = "The directory in which to save images was expected to exist at \"``\", but was not found.";

$ImageMarkdownTemplate = StringTemplate["<img src=\"/Documentation/Images/``\" width=\"``\">"];

Options[ExportImageForEmbedding] = {
  "DevelopmentDirectory" -> Automatic,
  CompressionLevel -> 1.0,
  "ColorMapLength" -> Automatic
}

ExportImageForEmbedding[name_String, image_Image, opts:OptionsPattern[]] := Scope[
  If[StringContainsQ[name, "."], ReturnFailed["nodot", name]];
  If[name === "" || !UpperCaseQ[StringTake[name, 1]] || StringContainsQ[name, " "], ReturnFailed["notcap", name]];
  filename = name <> ".png";
  UnpackOptions[developmentDirectory, compressionLevel, colorMapLength];
  SetAutomatic[developmentDirectory, $SetReplaceBaseDirectory];
  If[!StringQ[developmentDirectory] || !DirectoryQ[developmentDirectory],
    ReturnFailed["baddevdir", developmentDirectory]
  ];
  imagesDirectory = FileNameJoin[{developmentDirectory, "Documentation", "Images"}];
  If[!DirectoryQ[imagesDirectory],
    If[StringStartsQ[developmentDirectory, {$UserBasePacletsDirectory, $BasePacletsDirectory}],
      ReturnFailed["paclet", $SetReplaceBaseDirectory],
      ReturnFailed["noimgpath", imagesDirectory]
    ]
  ];
  path = FileNameJoin[{imagesDirectory, filename}];
  result = Export[path, image, CompressionLevel -> compressionLevel, "ColorMapLength" -> colorMapLength];
  If[!StringQ[result], ReturnFailed["noexport"]];
  width = First @ ImageDimensions[image];
  markdown = $ImageMarkdownTemplate[filename, width / 2.];
  If[$Notebooks, CopyToClipboard[markdown]];
  markdown
]
