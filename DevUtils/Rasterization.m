Package["SetReplaceDevUtils`"]

PackageImport["GeneralUtilities`"]

SetRelatedSymbolGroup[
  RasterizeExpressionAndExportToMarkdown,
  RasterizePreviousOutputAndExportToMarkdown,
  RasterizePreviousInputOutputAndExportToMarkdown
];

$usageSuffix = "
* 'path$' should be a path, releative to the repository root, with a CamelCased filename ending in '.png'.
* If 'path$' consists of only a file name, the subdirectory 'Documentation/Images' will be used.
* The resulting markdown will contain an absolute path relative to the root of the repository. It will \
correctly render on e.g. GitHub but may not render in e.g. VSCode.
* The option 'MaxWidth' controls the desird maximum width of the resulting raster. If possible, the expression \
being rasterized will line-break so as not to exceed this width. Note that this width can occassionally be exceeded.
";

$exportOptions = {
  Magnification -> 0.6,
  "MaxWidth" -> 700,
  "CompressionLevel" -> 1.0,
  "ColorMapLength" -> Automatic
};

PackageExport["RasterizeExpressionAndExportToMarkdown"]

SetUsage @ Evaluate["
RasterizeExpressionAndExportToMarkdown['path$', expr$] will rasterize expr$, write the result to 'path$', and
return an HTML <img> tag that can be pasted directly into a markdown file.
* The resulting image WILL NOT have an attached Out[]= label." <> $usageSuffix];

SyntaxInformation[RasterizeExpressionAndExportToMarkdown] = {"ArgumentsPattern" -> {_, _, OptionsPattern[]}};

Options[RasterizeExpressionAndExportToMarkdown] = $exportOptions;

RasterizeExpressionAndExportToMarkdown[relativePath_, expr_, opts:OptionsPattern[]] := CatchFailureAsMessage @ Scope[
  UnpackOptions[maxWidth];
  image = rasterize[maxWidth, expr];
  exportImageToMarkdown[relativePath, image, FilterOptions @ opts]
];

PackageExport["RasterizePreviousOutputAndExportToMarkdown"]

SetUsage @ Evaluate["
RasterizePreviousOutputAndExportToMarkdown['path$', expr$] ill read the previous output cell from the current \
notebook, rasterize it, write the result to 'path$', and return an HTML <img> tag that can be pasted \
directly into a markdown file.
HTML <img> tag that can be pasted directly into a markdown file.
* The resulting image WILL include an attached Out[]= label." <> $usageSuffix];

SyntaxInformation[RasterizePreviousOutputAndExportToMarkdown] = {"ArgumentsPattern" -> {_, OptionsPattern[]}};

Options[RasterizePreviousOutputAndExportToMarkdown] = $exportOptions;

RasterizePreviousOutputAndExportToMarkdown[relativePath_, opts:OptionsPattern[]] := CatchFailureAsMessage @ Scope[
  ocell = NotebookRead @ PreviousCell[];
  If[Head[ocell] =!= Cell, ReturnFailed["exportmdnocell"]];
  UnpackOptions[maxWidth];
  image = rasterizeCells[maxWidth, ocell];
  exportImageToMarkdown[relativePath, image, FilterOptions @ opts]
];

PackageExport["RasterizePreviousInputOutputAndExportToMarkdown"]

SetUsage @ Evaluate["
RasterizePreviousInputOutputAndExportToMarkdown['path$'] will read the previous input and output cell from the \
current notebook, rasterize the output, write the result to 'path$', and return an markdown code block containing \
the input and an HTML <img> tag containing the output rasterize, that can be pasted directly into a markdown file.
* If the input cell does not contain purely textual boxes, it cannot be faithfully represented as text, and so \
it will be included in the rasterized image instead.
* The option 'RasterizeInput' -> True will force the input to be rasterized, and will not create a markdown \
code block." <> $usageSuffix];

Options[RasterizePreviousInputOutputAndExportToMarkdown] = Append[$exportOptions, "RasterizeInput" -> False];

SyntaxInformation[RasterizePreviousInputOutputAndExportToMarkdown] = {"ArgumentsPattern" -> {_, OptionsPattern[]}};

(* this detects whether formatting boxes have been embedded into the input string via so-called
"Linear Syntax" (which is an insane thing that shouldn't exist) *)
$inlineSyntaxPattern = StringJoin["\!", "\(", "\*"];

$dummyICell = Cell[BoxData[""], "Input"]; (* needed to ensure CellTag gets included for a single cell *)

$maxWidthCompensation = 0.9;
rasterize[maxWidth_, epxr_Image] := expr;
rasterize[maxWidth_, expr_] := Rasterize[expr, ImageFormattingWidth -> maxWidth * $maxWidthCompensation];
rasterizeCells[maxWidth_, cell_] := ImageTake[rasterize[maxWidth, Notebook[{$dummyICell, cell}]], {60, -1}];
rasterizeCells[maxWidth_, cells__] := rasterize[maxWidth, Notebook[{cells}]];

cellToString[cell_] := Scope[
  packet = FrontEnd`ExportPacket[Notebook[{cell}], "InputText", "AllowExportAutoReplacements" -> False];
  result = MathLink`CallFrontEnd @ packet;
  If[!MatchQ[result, {_String, _, _}], ReturnFailed[]];
  string = First[result];
  If[StringContainsQ[string, $inlineSyntaxPattern], ReturnFailed[]];
  string
];

RasterizePreviousInputOutputAndExportToMarkdown[relativePath_, opts:OptionsPattern[]] := CatchFailureAsMessage @ Scope[
  ocell = PreviousCell[]; icell = PreviousCell @ ocell;
  ocell = NotebookRead[ocell]; icell = NotebookRead[icell];
  If[Head[icell] =!= Cell || Head[ocell] =!= Cell, ReturnFailed["exportmdnocell"]];
  UnpackOptions[rasterizeInput, maxWidth];
  If[TrueQ[rasterizeInput],
    icellString = $Failed;
  ,
    icellString = cellToString[icell];
  ];
  If[StringQ[icellString],
    mdPrefix = "```wl\n" <> icellString <> "\n```\n\n";
    image = rasterizeCells[maxWidth, ocell];
  ,
    mdPrefix = "";
    image = rasterizeCells[maxWidth, icell, ocell];
  ];
  mdPrefix <> exportImageToMarkdown[relativePath, image, FilterOptions @ opts]
];

(* This is the general driver code that the above functions share *)

General::exportmdnocell =
  "Could not obtain previous cell(s) in order to rasterize them.";
General::exportmdnoparentdir =
  "The parent directory for the image `` does not appear to exist. Please create it before calling this function.";
General::exportmdbadfilename =
  "The filename \"``\" should start with a capital letter, not contain any spaces, and end with '.png'.";
General::exportmdfail =
  "The image could not be exported.";

Options[exportImageToMarkdown] = $exportOptions;

exportImageToMarkdown[relativePath_, image_, OptionsPattern[]] := Scope[
  filename = FileNameTake[relativePath];
  relativeDir = FileNameDrop[relativePath];
  If[Or[filename === "",!UpperCaseQ[StringTake[filename, 1]],
    StringContainsQ[filename, " "], !StringEndsQ[filename, ".png", IgnoreCase -> True]],
    ThrowFailure["exportmdbadfilename", filename]];
  If[relativeDir === "", relativeDir = FileNameJoin[{"Documentation", "Images"}]];
  absoluteDir = FileNameJoin[{$SetReplaceRoot, relativeDir}];
  If[FileType[absoluteDir] =!= Directory, ThrowFailure["exportmdnoparentdir", absoluteDir]];
  path = FileNameJoin[{absoluteDir, filename}];
  UnpackOptions[compressionLevel, magnification, colorMapLength];
  exportResult = Export[path, image, CompressionLevel -> compressionLevel, "ColorMapLength" -> colorMapLength];
  If[!StringQ[exportResult], ThrowFailure["exportmdfail"]];
  width = First @ ImageDimensions[image];
  relativePath = StringDrop[path, StringLength[$SetReplaceRoot]];
  $imageMarkdownTemplate[relativePath, width * magnification]
];

$imageMarkdownTemplate = StringTemplate["<img src=\"``\" width=\"``\">"];
