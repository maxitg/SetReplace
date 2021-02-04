Package["SetReplaceDevUtils`"]

PackageImport["GeneralUtilities`"]

PackageExport["TestDelayed"]
PackageExport["TestUnevaluated"]
PackageExport["TestSymbolLeak"]

PackageExport["FrontEndErrors"]
PackageExport["CheckGraphics"]
PackageExport["GraphicsQ"]

PackageExport["RunTests"]

$notImmediateEvaluationUsage = StringTemplate["* `` does not evaluate immediately. Use RunTests to evaluate."];

SetUsage @ Evaluate["
TestDelayed[input$] tests if input$ evaluates to True.
TestDelayed[input$, expectedOutput$] tests if input$ evaluates to expectedOutput$.
TestDelayed[input$, expectedOutput$, messages$] also checks that messages$ were produced during the evaluation.
" <> $notImmediateEvaluationUsage["TestDelayed"]];

Options[TestDelayed] = Options[VerificationTest];

SyntaxInformation[TestDelayed] = {"ArgumentsPattern" -> {input_, expectedOutput_., messages_.},
                                  "OptionNames" -> First /@ Options[VerificationTest]};

SetUsage @ Evaluate["
TestUnevaluated[input$, messages$] checks that input$ does not evaluate and generates given messages$.
" <> $notImmediateEvaluationUsage["TestUnevaluated"]];

Options[TestUnevaluated] = Options[VerificationTest];

SyntaxInformation[TestUnevaluated] = {"ArgumentsPattern" -> {input_, messages_.},
                                      "OptionNames" -> First /@ Options[VerificationTest]};

SetUsage @ Evaluate["
TestSymbolLeak[input$] tests that no new symbols are created after a repeated evaluation of input$.
" <> $notImmediateEvaluationUsage["TestSymbolLeak"]];

Options[TestSymbolLeak] = Options[VerificationTest];

SyntaxInformation[TestSymbolLeak] = {"ArgumentsPattern" -> {input_},
                                     "OptionNames" -> First /@ Options[VerificationTest]};

SetUsage @ "
FrontEndErrors[expr$] returns a list of errors (pink boxes) generated while displaying expr$ by the Mathematica Front \
End.
";

SyntaxInformation[FrontEndErrors] = {"ArgumentsPattern" -> {expr_}};

FrontEndErrors[expr_] := ModuleScope[UsingFrontEnd[
  notebook = CreateDocument[ExpressionCell[expr]];
  SelectionMove[notebook, All, Notebook];
  result = MathLink`CallFrontEnd[FrontEnd`GetErrorsInSelectionPacket[notebook]];
  NotebookClose[notebook];
  result
]];

SetUsage @ "
CheckGraphics[graphics$] turns Mathematica Front End errors (boxes) into messages and returns its argument.
";

SyntaxInformation[CheckGraphics] = {"ArgumentsPattern" -> {graphics_}};

CheckGraphics::frontEndErrors := "``";

CheckGraphics[graphics_] := (
  Message[CheckGraphics::frontEndErrors, #] & /@ Flatten[FrontEndErrors[graphics]];
  graphics
);

SetUsage @ "
GraphicsQ[graphics$] yields True if graphics$ is a valid Graphics object with no Mathematica Front End (pink) errors, \
and False otherwise.
";

SyntaxInformation[GraphicsQ] = {"ArgumentsPattern" -> {graphics_}};

GraphicsQ[graphics_] := Head[graphics] === Graphics && FrontEndErrors[graphics] === {};

SetUsage @ "
RunTests[testFile$] runs the tests from testFile$ and returns a TestReport.
RunTests[{testFile$1, testFile$2, $$}] runs multiple test files.
";

SyntaxInformation[RunTests] = {"ArgumentsPattern" -> {testFile_}};

$testsDirectory = FileNameJoin[{$SetReplaceRoot, "Tests"}];
$testFiles = FileNameDrop[#, FileNameDepth[$testsDirectory]] & /@ FileNames["*", $testsDirectory, Infinity];

With[{testFiles = $testFiles},
  FE`Evaluate[FEPrivate`AddSpecialArgCompletion["RunTests" -> {testFiles}]]
];

RunTests[testFile_String] := RunTests[{testFile}];

RunTests[testFileList : {___String}] := ModuleScope[

]
