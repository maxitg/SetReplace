Package["SetReplaceDevUtils`"]

PackageImport["GeneralUtilities`"]

SetRelatedSymbolGroup[
  RasterizeExpressionAndExportToMarkdown,
  RasterizeCellsAndExportToMarkdown,
  RasterizePreviousInputOutputAndExportToMarkdown
];

$usageSuffix = "
* 'path$' should be a path, relative to the repository root, with a CamelCased filename ending in '.png'.
* If 'path$' consists of only a file name, the subdirectory 'Documentation/Images' will be used.
* The resulting markdown will contain an absolute path relative to the root of the repository. It will \
correctly render on e.g. GitHub but may not render in e.g. VSCode.
* The option 'MaxWidth' controls the desired maximum width of the resulting raster. If possible, the expression \
being rasterized will line-break so as not to exceed this width. Note that this width can occassionally be exceeded.
* With the option 'DryRun' -> True, the resulting image will be printed, but not written to disk.
";

$exportOptions = {
  Magnification -> 0.6,
  "MaxWidth" -> 700,
  "CompressionLevel" -> 1.0,
  "ColorMapLength" -> Automatic,
  "DryRun" -> False
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

PackageExport["RasterizeCellsAndExportToMarkdown"]

SetUsage @ Evaluate["
RasterizeCellsAndExportToMarkdown['path$', cells$] will rasterize a cell or set of cells, write the result to 'path$', \
and return an HTML <img> tag that can be pasted directly into a markdown file.
* Cells can be Cell[$$] expressions or CellObject[$$] expressions (which will be read with NotebookRead).
* The resulting image WILL include cell labels (In[]:=, Out[]=, etc)." <> $usageSuffix
];

SyntaxInformation[RasterizeCellsAndExportToMarkdown] = {"ArgumentsPattern" -> {_, OptionsPattern[]}};

Options[RasterizeCellsAndExportToMarkdown] = $exportOptions;

$cellP = HoldPattern[Cell[_, __]] | HoldPattern[CellObject[_]];

RasterizeCellsAndExportToMarkdown[relativePath_, cells_, opts:OptionsPattern[]] := CatchFailureAsMessage @ Scope[
  If[!MatchQ[cells, $cellP | {$cellP..}], ReturnFailed["exportmdnotcells"]];
  cells = Developer`ToList[cells] /. co_CellObject :> NotebookRead[co];
  If[!MatchQ[cells, {__Cell}] , ReturnFailed["exportmdnotcells"]];
  UnpackOptions[maxWidth];
  image = rasterizeCells[maxWidth, cells];
  exportImageToMarkdown[relativePath, image, FilterOptions @ opts]
];

PackageExport["RasterizePreviousInputOutputAndExportToMarkdown"]

SetUsage @ Evaluate["
RasterizePreviousInputOutputAndExportToMarkdown['path$'] will read the previous input and output cell from the \
current notebook, rasterize the output, write the result to 'path$', and return a markdown code block containing \
the input and an HTML <img> tag containing the rasterized output, that can be pasted directly into a markdown file.
* If the input cell does not contain purely textual boxes, it cannot be faithfully represented as text, and so \
it will be included in the rasterized image instead.
* The option 'RasterizeInput' -> True will force the input to be rasterized, and will not create a markdown \
code block.
* Any Message or Print cells between the output and the input will be included in the rasterization." <> $usageSuffix];

Options[RasterizePreviousInputOutputAndExportToMarkdown] = Append[$exportOptions, "RasterizeInput" -> False];

SyntaxInformation[RasterizePreviousInputOutputAndExportToMarkdown] = {"ArgumentsPattern" -> {_, OptionsPattern[]}};

(* this detects whether formatting boxes have been embedded into the input string via so-called
"Linear Syntax" (which is an insane thing that shouldn't exist) *)
$inlineSyntaxPattern = StringJoin["\!", "\(", "\*"];

$dummyICell = Cell[BoxData[""], "Input"]; (* needed to ensure CellTag gets included for a single cell *)

$maxWidthCompensation = 0.9;
rasterize[maxWidth_, expr_Image] := expr;
rasterize[maxWidth_, expr_] := Rasterize[expr, ImageFormattingWidth -> maxWidth * $maxWidthCompensation];
rasterizeCells[maxWidth_, {cell_}] := ImageTake[rasterize[maxWidth, Notebook[{$dummyICell, cell}]], {60, -1}];
rasterizeCells[maxWidth_, {cells__}] := rasterize[maxWidth, Notebook[{cells}]];

findFinalExpressionStart[str_String] := Scope[
  stream = StringToStream[str];
  expr = Hold[];
  pos = 0;
  While[MatchQ[expr, _Hold],
    {lastPos, pos} = {pos, StreamPosition[stream]};
    expr = Quiet @ Check[
      Read[stream, Hold[Expression]],
      Return[$Failed]
    ];
  ];
  lastPos + 1
];

cellToString[cell_] := Scope[
  packet = FrontEnd`ExportPacket[Notebook[{cell}], "InputText", "AllowExportAutoReplacements" -> False];
  result = MathLink`CallFrontEnd @ packet;
  If[!MatchQ[result, {_String, _, _}], ReturnFailed[]];
  string = First[result];
  If[StringContainsQ[string, $inlineSyntaxPattern], ReturnFailed[]];
  cursor = findFinalExpressionStart[string];
  If[!FailureQ[cursor], string = StringInsert[string, "In[] := ", cursor]];
  string
];

previousCellData[cell_, requiredType_] := Scope[
  cellObject = If[cell === None, PreviousCell[], PreviousCell @ cell];
    cellExpr = NotebookRead[cellObject];
  If[Head[cellExpr] =!= Cell, ThrowFailure["exportmdnocell"]];
  cellType = Replace[cellExpr, {Cell[_, type_String, ___] :> type, _ :> $Failed}];
  If[!MatchQ[cellType, requiredType], ThrowFailure["exportmdiotype", cellType]];
  {cellType, cellExpr, cellObject}
];

RasterizePreviousInputOutputAndExportToMarkdown[relativePath_, opts:OptionsPattern[]] := CatchFailureAsMessage @ Scope[
  {cellType, cellExpr, cellObj} = previousCellData[None, "Output"];
  rasterCells = {cellExpr};
  While[True,
    {cellType, cellExpr, cellObj} = previousCellData[cellObj, "Input" | "Output" | "Message" | "Print" | "Echo"];
    If[cellType === "Input", Break[]];
    PrependTo[rasterCells, cellExpr];
  ];
  UnpackOptions[rasterizeInput, maxWidth];
  If[TrueQ[rasterizeInput],
    icellString = $Failed;
  ,
    icellString = cellToString[cellExpr];
  ];
  If[StringQ[icellString],
    mdPrefix = "```wl\n" <> icellString <> "\n```\n\n";
    image = rasterizeCells[maxWidth, rasterCells];
  ,
    mdPrefix = "";
    image = rasterizeCells[maxWidth, Prepend[rasterCells, cellExpr]];
  ];
  mdPrefix <> exportImageToMarkdown[relativePath, image, FilterOptions @ opts]
];

General::exportmdnotcells =
  "The second argument should be a CellObject, Cell expression, or list of these.";
General::exportmdiotype =
  "The previous cell(s) were not of the appropriate types for this function: the cell type `` is not allowed.";
General::exportmdrelpathstr =
  "Path to export to (the first argument) should be a string.";
General::exportmdnocell =
  "Could not obtain previous cell(s) in order to rasterize them.";
General::exportmdnoparentdir =
  "The parent directory for the image `` does not appear to exist. Please create it before calling this function.";
General::exportmdbadfilename =
  "The filename \"``\" should start with a capital letter, not contain any spaces, and end with '.png'.";
General::exportmdfail =
  "The image could not be exported.";

Options[exportImageToMarkdown] = $exportOptions;

(* This is the general driver code that the above functions share *)

exportImageToMarkdown[relativePath_, image_, OptionsPattern[]] := Scope[
  If[!StringQ[relativePath], ThrowFailure["exportmdrelpathstr"]];
  filename = FileNameTake[relativePath];
  relativeDir = FileNameDrop[relativePath];
  If[
    Or[
      filename === "",
      Not @ UpperCaseQ @ StringTake[filename, 1],
      StringContainsQ[filename, " "],
      Not @ StringEndsQ[filename, ".png", IgnoreCase -> True]
    ],
    ThrowFailure["exportmdbadfilename", filename]];
  If[relativeDir === "", relativeDir = FileNameJoin[{"Documentation", "Images"}]];
  absoluteDir = FileNameJoin[{$SetReplaceRoot, relativeDir}];
  If[FileType[absoluteDir] =!= Directory, ThrowFailure["exportmdnoparentdir", absoluteDir]];
  path = FileNameJoin[{absoluteDir, filename}];
  UnpackOptions[compressionLevel, magnification, colorMapLength, dryRun];
  If[TrueQ[dryRun],
    Print["Image would be written to: ", path];
    Print[image];
  ,
    exportResult = Export[path, image, CompressionLevel -> compressionLevel, "ColorMapLength" -> colorMapLength];
    If[!StringQ[exportResult], ThrowFailure["exportmdfail"]];
  ];
  width = First @ ImageDimensions[image];
  relativePath = StringDrop[path, StringLength[$SetReplaceRoot]];
  $imageMarkdownTemplate[relativePath, width * magnification]
];

$imageMarkdownTemplate = StringTemplate["<img src=\"``\" width=\"``\">"];
