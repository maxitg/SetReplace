Package["SetReplaceDevUtils`"]

PackageImport["GeneralUtilities`"]


PackageExport["ExportPreviousInputOutputToMarkdown"]

SetUsage @ "
ExportPreviousInputOutputToMarkdown['path$'] will read the previous input and output cell from the current \
notebook, rasterize the output, write the result to 'path$', and return an HTML <img> tag that can be pasted \
directly into a markdown file.
* 'path$' should be a path, releative to the repository root, with a CamelCased filename ending in '.png'.
* If 'path$' consists of only a file name, the subdirectory 'Documentation/Images' will be used.
* The resulting markdown will contain an absolute path relative to the root of the repository. It will \
correctly render on e.g. GitHub but may not render in e.g. VSCode.
* If the input cell does not contain purely textual boxes, it cannot be faithfully represented as text, and so \
it will be included in the rasterized image instead.
"

Options[ExportPreviousInputOutputToMarkdown] = {
  Magnification -> 0.6,
  "CompressionLevel" -> 1.0,
  "ColorMapLength" -> Automatic
};

SyntaxInformation[ExportPreviousInputOutputToMarkdown] = {"ArgumentsPattern" -> {_, OptionsPattern[]}};

$inlineCellSentinel = StringJoin["\!", "\(", "\*"];

cellToString[cell_] := Scope[
  packet = FrontEnd`ExportPacket[Notebook[{cell}], "InputText", "AllowExportAutoReplacements" -> False];
  result = MathLink`CallFrontEnd @ packet;
  If[!MatchQ[result, {_String, _, _}], ReturnFailed[]];
  string = First[result];
  If[StringContainsQ[string, $inlineCellSentinel], ReturnFailed[]];
  string
];

$dummyICell = Cell[BoxData[""], "Input"];

ExportPreviousInputOutputToMarkdown::noparentdir = "The parent directory for the image `` does not appear to exist. Please create it before calling this function.";
ExportPreviousInputOutputToMarkdown::badfilename = "The filename \"``\" should start with a capital letter, not contain any spaces, and end with '.png'.";
ExportPreviousInputOutputToMarkdown::noexport = "The image could not be exported.";

ExportPreviousInputOutputToMarkdown[relativePath_, OptionsPattern[]] := Scope[
  filename = FileNameTake[relativePath];
  relativeDir = FileNameDrop[relativePath];
  If[Or[filename === "",!UpperCaseQ[StringTake[filename, 1]],
    StringContainsQ[filename, " "], !StringEndsQ[filename, ".png", IgnoreCase -> True]],
    ReturnFailed["badfilename", filename]];
  If[relativeDir === "", relativeDir = FileNameJoin[{"Documentation", "Images"}]];
  absoluteDir = FileNameJoin[{$SetReplaceRoot, relativeDir}];
  If[FileType[absoluteDir] =!= Directory, ReturnFailed["noparentdir", absoluteDir]];
  path = FileNameJoin[{absoluteDir, filename}];
  ocell = PreviousCell[]; icell = PreviousCell @ ocell;
  ocell = NotebookRead[ocell]; icell = NotebookRead[icell];
  If[Head[icell] =!= Cell || Head[ocell] =!= Cell, Return[$Failed]];
  icellString = cellToString[icell];
  If[StringQ[icellString],
    image = ImageTake[Rasterize @ Notebook[{$dummyICell, ocell}], {60, -1}];
    result = "```wl\n" <> icellString <> "\n```\n\n";
  ,
    image = Rasterize @ Notebook[{icell, ocell}];
    result = "";
  ];
  UnpackOptions[compressionLevel, magnification, colorMapLength];
  exportResult = Export[path, image, CompressionLevel -> compressionLevel, "ColorMapLength" -> colorMapLength];
  If[!StringQ[exportResult], ReturnFailed["noexport"]];
  width = First @ ImageDimensions[image];
  relativePath = StringDrop[path, StringLength[$SetReplaceRoot]];
  result <> $imageMarkdownTemplate[relativePath, width * magnification]
];

$imageMarkdownTemplate = StringTemplate["<img src=\"``\" width=\"``\">"];

