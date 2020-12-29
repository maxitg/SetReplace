Begin["`LLU`"];

System`Private`NewContextPath[{"System`", $Context}];

(* Store the private paclet context that this file was loaded in for later use *)
`Private`$LLULoadingContext = $Context;

(* ::Section:: *)
(*Exported Symbols*)
(* ------------------------------------------------------------------------- *)
(* ------------------------------------------------------------------------- *)

InitializePacletLibrary::usage = "InitializePacletLibrary[libPath_]
	Initialization of LLU that involves loading the main paclet library.
	This or LazyInitializePacletLibrary must be called by every paclet that uses LLU
	and will be evaluated only once unless it fails by Throwing.
	libPath - path to the main paclet library (the one that LLU was linked into)";
LazyInitializePacletLibrary::usage = "Lazy version of InitializePacletLibrary
	which loads the library at the time the first library function is loaded.";

(* ---------------- Paclet errors ------------------------------------------ *)

RegisterPacletErrors::usage = "RegisterPacletErrors[errors_?AssociationQ]
	Adds custom top-level errors. Errors are specified in the form
	<| \"ErrorName\" -> \"Message\" |>";

CreatePacletFailure::usage = "CreatePacletFailure[type_?StringQ, opts]
	Emits a Failure object for the custom error named by type.";

ThrowPacletFailure::usage = "ThrowPacletFailure[type_?StringQ, opts]
Throws a tagged Failure object for the custom error named by type. The tag is provided by LLU`$ExceptionTagFunction, which is a function that operates
on the to-be-thrown Failure object and can be customized.
ThrowPacletFailure[type_?StringQ, tag_, opts]
Throws a Failure object for the custom error named by type with explicitly specified tag (second argument to Throw).";

(* ---------------- Configuration ------------------------------------------ *)

$Throws::usage = "Default value for the \"Throws\" option for loading library functions. Notice that this setting does not affect LLU API functions
(e.g. RegisterPacletErrors, InitializePacletLibrary, etc.) as they always throw on failure.";

$ExceptionTagFunction::usage = "Function to be applied to a Failure returned by a library function to determine the second argument to Throw[].";

(* ---------------- Loading libraries and library functions ---------------- *)

SafeLibraryLoad::usage = "SafeLibraryLoad[lib_]
	Quietly attempts to load the dynamic library lib, and Throws if it cannot be loaded.";

PacletFunctionSet::usage = "PacletFunctionSet[resultSymbol_, fParams_, fResultType_, opts___]
	Attempts to load an exported function from a dynamic library and assign the result to resultSymbol.
	By default, the dynamic library name is taken from the library given to InitializePacletLibrary (\"Paclet Library\").
	A caveat is that if Paclet Library has been lazily initialized and PacletFunctionSet is called with a path to it, then
	auto-loading of Paclet Library will not be triggered.
	By default, the name of the library function is assumed to be the same as the symbol name (sans any leading or trailing $'s).
	Arguments:
	- resultSymbol_ - a WL symbol to represent the loaded function
	- lib_String - name of the dynamic library
	- f_String - name of the function to load from the dynamic library
	- fParams_ - parameter types of the library function to be loaded
	- fResultType_ - result type
	Options:
	All options for PacletFunctionLoad and SafeLibraryFunctionLoad are accepted.";
LazyPacletFunctionSet::usage = "LazyPacletFunctionSet[resultSymbol_, fParams_, fResultType_, opts___]
	Lazy version of PacletFunctionSet which loads the function upon the first evaluation of resultSymbol.";

WSTPFunctionSet::usage = "WSTPFunctionSet[resultSymbol_, opts : OptionsPattern[PacletFunctionSet]]
	A convenient wrapper around PacletFunctionSet for easier loading of WSTP functions.";
LazyWSTPFunctionSet::usage = "LazyWSTPFunctionSet[resultSymbol_, opts : OptionsPattern[PacletFunctionSet]]
	Lazy version of WSTPFunctionSet which loads the function upon the first evaluation of resultSymbol.";

MemberFunctionSet::usage = "MemberFunctionSet[exprHead_][memberSymbol_?Developer`SymbolQ, fParams_, retType_, opts : OptionsPattern[PacletFunctionSet]]
	Loads a library function into memberSymbol that can be invoked on instances of exprHead like so: instance @ memberSymbol[...]";
LazyMemberFunctionSet::usage = "LazyMemberFunctionSet[exprHead_][memberSymbol_?Developer`SymbolQ, fParams_, retType_, opts : OptionsPattern[PacletFunctionSet]]
	Lazy version of MemberFunctionSet which loads the function upon the first evaluation of memberSymbol.";

WSTPMemberFunctionSet::usage = "WSTPMemberFunctionSet[exprHead_][memberSymbol_, opts : OptionsPattern[PacletFunctionSet]]
	A convenient wrapper around MemberFunctionSet for easier loading of WSTP functions.";
LazyWSTPMemberFunctionSet::usage = "LazyWSTPMemberFunctionSet[exprHead_][memberSymbol_, opts : OptionsPattern[PacletFunctionSet]]
	Lazy version of WSTPMemberFunctionSet which loads the function upon the first evaluation of memberSymbol.";

PacletFunctionLoad::usage = "PacletFunctionLoad[fname_?StringQ, fParams_, retType_, opts___]
	By default, the dynamic library name is taken from the library given to InitializePacletLibrary. Alternatively,
	a library name can be specified as the first argument. Unlike PacletFunctionSet, there is no mechanism
	by which to avoid eager loading of the default paclet library.";

(* ---------------- Managed Library Expressions ---------------------------- *)

Constructor::usage = "Constructor[exprHead_] shall evaluate to a function that takes an instanceID (Integer) and an arbitrary number of additional arguments.
	This function is responsible for creating an instance of managed expression for given ID in the corresponding ManagedExpressionStore on the C++ side";
Managed::usage = "Managed[exprHead_]
	represents a MLE instance.";
NewManagedExpression::usage = "NewManagedExpression[exprHead_][args___]
	Creates a MLE instance.";
ManagedQ::usage = "ManagedQ[exprHead_][expr]
	Checks whether expr is a valid MLE instance.";
ManagedIDQ::usage = "ManagedIDQ[exprHead_][expr]
	Checks whether expr is a valid id of a MLE instance.";
GetManagedID::usage = "GetManagedID[instance_]
	returns the id associated with a valid MLE instance.";

(* ---------------- User-defined argument and result types ----------------- *)

MArgumentType::usage = "MArgumentType[customType_, actualType_, transformation_]
extends the set of basic LibraryLink argument types. Three parameters must be provided:
 - customType - new argument type, can be a Symbol, String, or some other expression
 - actualType - a type or a list of basic LibraryLink argument types that correspond to a single argument of customType
 - transformation - a function that takes a single expression of customType and returns a sequence of corresponding values of actualType";

MResultType::usage = "MResultType[customType_, actualType_, transformation_]
extends the set of basic LibraryLink return types. Three parameters must be provided:
 - customType - new return type, can be a Symbol, String, or some other expression
 - actualType - a single basic LibraryLink type that corresponds to an expression of customType
 - transformation - a function that takes an expression of actualType and returns a value of customType";

CustomMArgumentTypeQ::usage = "CustomMArgumentTypeQ[t] returns True iff t has been registered as a user-defined library function argument type.";

CustomMResultTypeQ::usage = "CustomMResultTypeQ[t] returns True iff t has been registered as a user-defined library function return type.";

MArgumentCustomType::usage = "MArgumentCustomType[t] must evaluate to a sequence of basic LibraryLink types that corresponds to a single argument of type t.
DownValues for this symbol can be provided by developers either directly or, preferably, by calling MArgumentType.";

MResultCustomType::usage = "MResultCustomType[t] must evaluate to a single basic LibraryLink type that corresponds to a library function return value of type t.
DownValues for this symbol can be provided by developers either directly or, preferably, by calling MResultType.";

MArgumentTransform::usage = "MArgumentTransform[t] must evaluate to a one-argument function that takes an expression of \"type\" t and returns a sequence of
LibraryLink-compatible expressions (String, Integer, NumericArray, etc.). DownValues for this symbol can be provided by developers either directly or,
preferably, by calling MArgumentType.";

MResultTransform::usage = "MResultTransform[t] must evaluate to a one-argument function that takes a LibraryLink-compatible expression
and returns an expression of \"type\" t. DownValues for this symbol can be provided by developers either directly or, preferably, by calling MResultType.";

(* ---------------- Logging ------------------------------------------------ *)

`Logger`LogToList::usage = "LogToList[args___]
	Put all message parts in a list unstyled";
`Logger`LogToAssociation::usage = "LogToAssociation[logLevel_, line_, file_, fn_, args___]
	Put all message parts in Association";
`Logger`LogToString::usage = "LogToString[logLevel_, line_, file_, fn_, args___]
	Combine all log parts to a String. No styling, contains a newline character.";
`Logger`LogToShortString::usage = "LogToShortString[logLevel_, line_, file_, fn_, args___]
	Combine all log parts to a condensed String. No styling, single line (unless message text contains newlines).";
`Logger`LogToGrid::usage = "LogToGrid[logLevel_, line_, file_, fn_, args___]
	Place fully styled log message in a TextGrid. Looks nice, good default choice for printing to the notebook.";
`Logger`LogToRow::usage = "LogToRow[logLevel_, line_, file_, fn_, args___]
	Fully styled, condensed log message in a Row. Good choice if you expect many log messages and want to see them all in the notebook.";

`Logger`LogFiltered::usage = "A symbol for filtered-out messages";
`Logger`FilterAcceptAll::usage = "FilterAcceptAll[args___]
	Simple filter that does no filtering";
`Logger`FilterRejectAll::usage = "FilterRejectAll[___]
	Filter that rejects everything";
`Logger`FilterBySingleFeature::usage = "FilterBySingleFeature[featureIndex_][test_]
	Meta function for defining filters that filter by a single element of a log: level, line, file name or function name";
`Logger`FilterByLevel::usage = "FilterByLevel[test_]
	Single element filter which discriminates by severity level.";
`Logger`FilterByLine::usage = "FilterByLine[test_]
	Single element filter which discriminates by line number.";
`Logger`FilterByFile::usage = "FilterByFile[test_]
	Single element filter which discriminates by file name.";
`Logger`FilterByFunction::usage = "FilterByFunction[test_]
	Single element filter which discriminates by function name.";
`Logger`FilterCustom::usage = "FilterCustom[test_]
	Define custom filter - test function have access to all elements of the log";
`Logger`LogFilterSelector::usage = "This is a \"selector\" called by other functions below. Feel free to modify/Block this symbol, see examples.";

`Logger`DiscardLog::usage = "DiscardLog[___]
	Discard the log";
`Logger`PrintLogToNotebook::usage = "PrintLogToNotebook[args___]
	Print to current notebook";
`Logger`PrintLogToMessagesWindow::usage = "PrintLogToMessagesWindow[args___]
	Print to Messages window. Remember that this window may be hidden by default.";
`Logger`PrintLogToSymbol::usage = "PrintLogToSymbol[x_]
	Append to a list and assign to given symbol. Good choice if you don't want to see the logs immediately, but want to store them for later analysis.";
`Logger`PrintLogFunctionSelector::usage = "This is a \"selector\" called by other functions below. Feel free to modify/Block this symbol, see examples.";
`Logger`LogHandler::usage = "This is a function WSTP will call from the C++ code. It all starts here. Feel free to modify/Block this symbol, see examples.";

(* ::Section:: *)
(* Load Dependencies *)
(* ------------------------------------------------------------------------- *)
(* ------------------------------------------------------------------------- *)

Begin["`Private`"];

(* LLU depends on WSTP, so WSTP must be loaded before the paclet library.
 * Paclets are not required to carry their own copy of WSTP shared library,
 * instead every paclet attempts to load the WSTP located within the current installation of Mathematica.
 * This may cause problems if paclet was built with different WSTP interface version but this should be extremely rare.
 * On MacOS WSTP is a framework and it is on the Kernel's rpath so the loading should happen automatically.
 *)
LoadWSTPLibrary[] :=
	Block[{wstpName, wstpPath},
		wstpName = "WSTP" <> ToString[$SystemWordLength] <> "i" <> ToString[MathLink`Information`$InterfaceNumber];
		wstpPath = System`Private`LocateDynamicLibrary[wstpName];
		SafeLibraryLoad @ wstpPath
	] /; ($OperatingSystem =!= "MacOSX");

(* Initialization of LLU that involves loading the main paclet library. Must be called by every paclet that uses LLU and will be evaluated only once
 * unless it failed. Failures are indicated by Throwing. In the lazy version, loading is triggered when the first library function is loaded.
 * libPath - path to the main paclet library (the one that LLU was linked into)
 *)
SetAttributes[LazyInitializePacletLibrary, HoldFirst];
LazyInitializePacletLibrary[libPath_] := LazyLoad[$PacletLibrary, $InitializePacletLibrary[libPath]];

InitializePacletLibrary[libPath_?StringQ] := (LazyInitializePacletLibrary[libPath]; $PacletLibrary);

$InitializePacletLibrary[libPath_?StringQ] := (
	(* Load WSTP *)
	LoadWSTPLibrary[];

	(* Load paclet library. This has to be done, because LLU needs its own init functions in the C++ code, that are part of paclet library. *)
	SetPacletLibrary[SafeLibraryLoad[libPath]];

	(* Initialize error handling part of LLU by loading errors from the C++ code *)
	WSTPFunctionSet[$GetCErrorCodes, "sendRegisteredErrors"];
	RegisterCppErrors[];

	(* Load library functions for initializing different parts of LLU. *)
	PacletFunctionSet[$SetLoggerContext, "setLoggerContext", {String}, String, "Optional" -> True];
	PacletFunctionSet[$SetExceptionDetailsContext, "setExceptionDetailsContext", {String}, String];
	(* Tell C++ part of LLU in which context were top-level symbols loaded. *)
	SetContexts[$LLULoadingContext, $LLULoadingContext <> "Private`"];
	$PacletLibrary
);

(* ::Section:: *)
(* Internal Utilities *)
(* ------------------------------------------------------------------------- *)
(* ------------------------------------------------------------------------- *)

(* ::SubSection:: *)
(* Globals *)
(* ------------------------------------------------------------------------- *)
(* ------------------------------------------------------------------------- *)

(* Path to the paclet library *)
Clear @ $PacletLibrary;

SetPacletLibrary[lib_?StringQ] := $PacletLibrary = lib;

(* Count how many failures was produced by the paclet during current Kernel session *)
$ErrorCount = 0;

(* Global association for all registered errors *)
$CorePacletFailureLUT = <|
	"LibraryLoadFailure" -> {20, "Failed to load library `LibraryName`. Details: `Details`."},
	"FunctionLoadFailure" -> {21, "Failed to load the function `FunctionName` from `LibraryName`. Details: `Details`."},
	"RegisterFailure" -> {22, "Incorrect arguments to RegisterPacletErrors."},
	"UnknownFailure" -> {23, "The error `ErrorName` has not been registered."},
	"ProgressMonInvalidValue" -> {24, "Expecting None or a Symbol for the option \"ProgressMonitor\"."},
	"InvalidManagedExpressionID" -> {25, "`Expr` is not a valid ManagedExpression." },
	"UnexpectedManagedExpression" -> {26, "Expected managed `Expected`, got `Actual`." }
|>;

(* Every error used in the paclet must have unique ID. We distinguish 4 ranges of IDs:
 * (-Infinity, 0) - for errors returned from the C++ code,
 * [0, 20) - reserved for LibraryLink
 * [20, $MaxLLUBuiltinErrorID] - reserved for built-in LLU top-level errors
 * [$MaxLLUBuiltinErrorID + 1, Infinity) - for user-defined top-level errors
 *
 * IMPORTANT!
 * Developers never explicitly specify IDs for their errors. This is done internally by LLU.
 *)
$MaxLLUBuiltinErrorID = 99;

(* ::SubSection:: *)
(* Utility Functions *)
(* ------------------------------------------------------------------------- *)
(* ------------------------------------------------------------------------- *)

ErrorCodeToName[errorCode_Integer]:=
Block[{name = Select[$CorePacletFailureLUT, MatchQ[#, {errorCode, _}] &]},
	If[Length[name] > 0 && Depth[name] > 2,
		First @ Keys @ name
		,
		""
	]
];

AppendBacktickIfNeeded[s_?StringQ] := If[StringEndsQ[s, "`"], s, s <> "`"];

SetLoggerContext[context_?StringQ] :=
	$SetLoggerContext @ AppendBacktickIfNeeded @ context;

SetExceptionDetailsContext[context_?StringQ] :=
	$SetExceptionDetailsContext @ AppendBacktickIfNeeded @ context;

SetContexts[context_?StringQ] := SetContexts[context, context];
SetContexts[loggerContext_?StringQ, exceptionContext_?StringQ] := (
	SetLoggerContext[loggerContext];
	SetExceptionDetailsContext[exceptionContext];
);

(* ::Section:: *)
(* Developer API *)
(* ------------------------------------------------------------------------- *)
(* ------------------------------------------------------------------------- *)

(* ::SubSection:: *)
(* User-defined library function argument types *)
(* ------------------------------------------------------------------------- *)

(* Function to extend the set of basic LibraryLink argument types. Developers can register their custom types. Three parameters must be provided:
 * - customType - new argument type, can be a Symbol, String, or some other expression
 * - actualType - a type or a list of basic LibraryLink argument types that correspond to a single argument of customType
 * - transformation - a function that takes a single expression of customType and returns a sequence of corresponding values of actualType
 *)
MArgumentType[customType_, actualType_, transformation_] := (
	CustomMArgumentTypeQ[customType] := True;
	MArgumentCustomType[customType] := Sequence @@ actualType;
	MArgumentTransform[customType] := transformation;
);

(* Function to extend the set of basic LibraryLink return types. Developers can register their custom types. Three parameters must be provided:
 * - customType - new return type, can be a Symbol, String, or some other expression
 * - actualType - a single basic LibraryLink type that corresponds to an expression of customType
 * - transformation - a function that takes an expression of actualType and returns a value of customType
 *)
MResultType[customType_, actualType_, transformation_] := (
	CustomMResultTypeQ[customType] := True;
	MResultCustomType[customType] := actualType;
	MResultTransform[customType] := transformation;
);

(* Decide whether given LibraryFunction argument/return type is a user-defined type and needs special treatment.
 * Downvalues for these symbols can be provided by developers either directly or by calling MArgumentType/MResultType
 *)
CustomMArgumentTypeQ[_] := False;
CustomMResultTypeQ[_] := False;

(* Get basic LibraryLink type(s) corresponding to a given user-defined type.
 * MArgumentCustomType[t] must evaluate to a sequence of basic LibraryLink types that corresponds to a single argument of "type" t.
 * MResultCustomType[t] must evaluate to a single basic LibraryLink type that corresponds to a library function return value of "type" t.
 * Downvalues for these symbols can be provided by developers either directly or by calling MArgumentType/MResultType
 *)
MArgumentCustomType[t_] := t;
MResultCustomType[t_] := t;

(* Get transformation function for user-defined argument/return type.
 * MArgumentTransform[t] must be a one-argument function that takes an expression of "type" t and returns
 * a sequence of LibraryLink-compatible expressions (String, Integer, NumericArray, etc.).
 * MResultTransform[t] shall be a one-argument function that takes a LibraryLink-compatible expression and returns an expression of "type" t.
 * Downvalues for these symbols can be provided by developers either directly or by calling MArgumentType/MResultType
 *)
MArgumentTransform[_] := Identity;
MResultTransform[_] := Identity;

(* Simple function expected to select all user-defined arguments from a list of argument types for a LibraryFunction. *)
SelectSpecialArgs[argTypes_List] := Select[AssociationThread[Range[Length[#]], #]& @ argTypes, CustomMArgumentTypeQ];
SelectSpecialArgs[LinkObject] = {};

(* Parse user-defined arguments before they are passed to a LibraryFunction. Parsing is based on MArgumentTransform function.
 * NOTE: This function is invoked before every call to a LibraryFunction so efficiency is top concern here!
 *)
ArgumentParser[specialArgs_?AssociationQ] := Sequence @@ MapIndexed[MArgumentTransform[specialArgs[First @ #2]][#1] &, {##}]&;

(* ::SubSection:: *)
(* Loading dynamic libraries and library functions *)
(* ------------------------------------------------------------------------- *)

SafeLibraryLoad[lib_] :=
	Quiet[
		If[FailureQ @ LibraryLoad[lib],
			ThrowPacletFailure[
				"LibraryLoadFailure",
				"MessageParameters" -> <|"LibraryName" -> lib, "Details" -> ToString @ LibraryLink`$LibraryError|>
			];
		];
		lib
	];

Options[SafeLibraryFunctionLoad] = {
	"Optional" -> False
};

(* 
 *	SafeLibraryFunctionLoad[libName_, fname_?StringQ, fParams_, retType_, opts___]
 *	Quietly tries to load a function fname from the dynamic library libName, and Throws if the loading does not succeed.
 *)
SafeLibraryFunctionLoad[fname_?StringQ, fParams_, retType : Except[_?OptionQ], opts : OptionsPattern[SafeLibraryFunctionLoad]] :=
	SafeLibraryFunctionLoad[$PacletLibrary, fname, fParams, retType, opts];

SafeLibraryFunctionLoad[libName_?StringQ, fname_?StringQ, fParams_, retType : Except[_?OptionQ], opts : OptionsPattern[SafeLibraryFunctionLoad]] :=
	Quiet[
		(* There are 2 categories of function arguments:
		 * - regular - supported by LibraryLink (String, Integer, NumericArray, etc.)
		 * - special - extensions added by LLU or paclet developers that need extra parsing before they can be passed to LibraryLink,
		 *             for example Managed Expressions
		 *)
		Block[{specialArgs = SelectSpecialArgs[fParams], specialRetQ = CustomMResultTypeQ[retType], actualRetType, libFunction},
			actualRetType = If[specialRetQ, MResultCustomType[retType], retType];
			libFunction = If[Length @ specialArgs > 0,
				(* If the function that we are registering takes special arguments, we need to compose it with argumentParser function,
				 * which will parse input arguments before every call, so that they are accepted by LibraryLink.*)
				LibraryFunctionLoad[libName, fname, MArgumentCustomType /@ fParams, actualRetType] @* ArgumentParser[specialArgs]
				,
				LibraryFunctionLoad[libName, fname, fParams, actualRetType]
			];
			If[FailureQ[libFunction],
				If[TrueQ @ OptionValue["Optional"],
					Missing["NotInLibrary"]
					,
					ThrowPacletFailure[
						"FunctionLoadFailure",
						"MessageParameters" -> <|"FunctionName" -> fname, "LibraryName" -> libName, "Details" -> ToString @ LibraryLink`$LibraryError|>]
				]
			];
			If[specialRetQ,
				MResultTransform[retType] @* libFunction
				,
				libFunction
			]
		]
	];

Options[PacletFunctionLoad] = SortBy[ToString] @ Join[
	Options[SafeLibraryFunctionLoad],
	{
		"ProgressMonitor" -> None,
		"Throws" :> $Throws
	}
];

holdSet[Hold[sym_], rhs_] := sym = rhs;

PacletFunctionLoad[fname_?StringQ, fParams_, retType : Except[_?OptionQ], opts : OptionsPattern[]] :=
    PacletFunctionLoad[$PacletLibrary, fname, fParams, retType, opts];

PacletFunctionLoad[libName_?StringQ, fname_?StringQ, fParams_, retType : Except[_?OptionQ], opts : OptionsPattern[]] :=
Module[{errorHandler, pmSymbol, newParams, f, functionOptions, loadOptions},
	functionOptions = FilterRules[{opts}, Options[PacletFunctionLoad]];
    errorHandler = If[TrueQ[OptionValue[Automatic, functionOptions, "Throws"]],
	    CatchAndThrowLibraryFunctionError
		,
	    CatchLibraryFunctionError
    ];
    pmSymbol = OptionValue[Automatic, functionOptions, "ProgressMonitor", Hold];
	loadOptions = FilterRules[{opts}, Options[SafeLibraryFunctionLoad]];
    If[fParams === LinkObject || pmSymbol === Hold[None],
	    errorHandler @* SafeLibraryFunctionLoad[libName, fname, fParams, retType, loadOptions]
	    , (* else *)
	    If[Not @ Developer`SymbolQ @ ReleaseHold @ pmSymbol,
		    ThrowPacletFailure["ProgressMonInvalidValue"];
	    ];
	    newParams = Append[fParams, {Real, 1, "Shared"}];
	    f = errorHandler @* SafeLibraryFunctionLoad[libName, fname, newParams, retType, loadOptions];
	    (
		    holdSet[pmSymbol, Developer`ToPackedArray[{0.0}]];
		    f[##, ReleaseHold[pmSymbol]]
	    )&
    ]
];

MemberFunctionLoad[exprHead_][libName_, fname_String, fParams_, retType : Except[_?OptionQ], opts : OptionsPattern[PacletFunctionLoad]] :=
	Block[{params = fParams},
		If[params =!= LinkObject, PrependTo[params, Managed[exprHead]]];
		PacletFunctionLoad[libName, fname, params, retType, opts]
	];

MemberFunctionLoad[exprHead_][fname_String, fParams_, retType : Except[_?OptionQ], opts : OptionsPattern[PacletFunctionLoad]] :=
	MemberFunctionLoad[exprHead][$PacletLibrary, fname, fParams, retType, opts];

Attributes[iLoadLibraryFunction] = {HoldFirst};
iLoadLibraryFunction[symbol_, assignmentHead_, loader_, libraryName_, args___, opts : OptionsPattern[]] :=
	Module[{loadingOpts},

		(* For member function loading, get Options[MemberFunctionSet] *)
		loadingOpts = FilterRules[{opts}, Options[Replace[loader, _MemberFunctionLoad -> MemberFunctionSet]]];

		clearLHS[symbol];
		assignmentHead[
			symbol,
			(
				If[libraryName === None,
					(* Library name is evaluated at the point of calling LoadLibraryFunction and it may be None if the library has not been loaded yet.
					 * In this case, we do not pass it to a loading function, but instead we let the loading function use $PacletLibrary, which must be
					 * initialized by the time the function is actually being loaded. *)
					loader[$PacletLibrary, args, loadingOpts]
					,
					loader[libraryName, args, loadingOpts]
				]
			)
		]
	];

Attributes[guessFunctionNameFromSymbol] = {HoldFirst};
guessFunctionNameFromSymbol[symbol_] := StringReplace["$" ~~ s_ :> s] @ SymbolName[Unevaluated[symbol]];

(* symbol could be a general LHS, such as Constructor[MyExpression] *)
Attributes[clearLHS] = {HoldFirst};
clearLHS[symbol_] :=
	If[Developer`HoldSymbolQ[symbol],
		Clear[symbol];
		,
		(* this is quieted to avoid messaging when symbol has no definitions *)
		Quiet[Unset[symbol], Unset::norep];
	];


(* PacletFunctionSet[resultSymbol_, lib_, f_, fParams_, fResultType_, opts___] attempts to load an exported function f from a dynamic library lib and assign
 * the result to resultSymbol. In the lazy version, the function will be loaded on the first evaluation of resultSymbol.
 * Arguments:
 * - resultSymbol_ - a WL symbol to represent the loaded function
 * - lib_String - name of the dynamic library
 * - f_String - name of the function to load from the dynamic library
 * - fParams_ - parameter types of the library function to be loaded
 * - fResultType_ - result type
 * Options:
 * All options for PacletFunctionLoad and SafeLibraryFunctionLoad are accepted.
 *)
Options[PacletFunctionSet] = Options[PacletFunctionLoad];
Options[LazyPacletFunctionSet] = Options[PacletFunctionSet];

Attributes[PacletFunctionSet] = {HoldFirst};
Attributes[LazyPacletFunctionSet] = Attributes[PacletFunctionSet];
PacletFunctionSet[symbol_, libraryName_, funcNameInLib_?StringQ, paramTypes_, retType : Except[_?OptionQ], opts : OptionsPattern[]] :=
	iLoadLibraryFunction[symbol, Set, PacletFunctionLoad, libraryName, funcNameInLib, paramTypes, retType, opts];
LazyPacletFunctionSet[symbol_, libraryName_, funcNameInLib_?StringQ, paramTypes_, retType : Except[_?OptionQ], opts : OptionsPattern[]] :=
	iLoadLibraryFunction[symbol, LazyLoad, PacletFunctionLoad, libraryName, funcNameInLib, paramTypes, retType, opts];

PacletFunctionSet[symbol_, funcNameInLib_?StringQ, paramTypes_, retType : Except[_?OptionQ], opts : OptionsPattern[]] :=
	PacletFunctionSet[symbol, $PacletLibrary, funcNameInLib, paramTypes, retType, opts];
LazyPacletFunctionSet[symbol_, funcNameInLib_?StringQ, paramTypes_, retType : Except[_?OptionQ], opts : OptionsPattern[]] :=
	LazyPacletFunctionSet[symbol, None, funcNameInLib, paramTypes, retType, opts];

PacletFunctionSet[symbol_, paramTypes_, retType : Except[_?OptionQ], opts : OptionsPattern[]] :=
	PacletFunctionSet[symbol, guessFunctionNameFromSymbol[symbol], paramTypes, retType, opts];
LazyPacletFunctionSet[symbol_, paramTypes_, retType : Except[_?OptionQ], opts : OptionsPattern[]] :=
	LazyPacletFunctionSet[symbol, guessFunctionNameFromSymbol[symbol], paramTypes, retType, opts];

Options[WSTPFunctionSet] = Options[PacletFunctionSet];
Options[LazyWSTPFunctionSet] = Options[WSTPFunctionSet];

(* WSTPFunctionSet[resultSymbol_, lib_, f_, opts___] - convenient wrapper around PacletFunctionSet for easier loading of WSTP functions. *)
Attributes[WSTPFunctionSet] = {HoldFirst};
Attributes[LazyWSTPFunctionSet] = Attributes[WSTPFunctionSet];
WSTPFunctionSet[symbol_, libraryName_, funcNameInLib_?StringQ, opts : OptionsPattern[]] :=
	PacletFunctionSet[symbol, libraryName, funcNameInLib, LinkObject, LinkObject, opts];
LazyWSTPFunctionSet[symbol_, libraryName_, funcNameInLib_?StringQ, opts : OptionsPattern[]] :=
	LazyPacletFunctionSet[symbol, libraryName, funcNameInLib, LinkObject, LinkObject, opts];

WSTPFunctionSet[symbol_, funcNameInLib_?StringQ, opts : OptionsPattern[]] :=
	WSTPFunctionSet[symbol, $PacletLibrary, funcNameInLib, opts];
LazyWSTPFunctionSet[symbol_, funcNameInLib_?StringQ, opts : OptionsPattern[]] :=
	LazyWSTPFunctionSet[symbol, None, funcNameInLib, opts];

WSTPFunctionSet[symbol_, opts : OptionsPattern[]] :=
	WSTPFunctionSet[symbol, guessFunctionNameFromSymbol[symbol], opts];
LazyWSTPFunctionSet[symbol_, opts : OptionsPattern[]] :=
	LazyWSTPFunctionSet[symbol, guessFunctionNameFromSymbol[symbol], opts];

(* ::SubSection:: *)
(* Lazy loading library functions *)
(* ------------------------------------------------------------------------- *)

(* Here is a typical way to load a library function and assign it to a symbol:
 *     f = PacletFunctionLoad["functionName", {Integer}, String];
 * This code will immediately evaluate PacletFunctionLoad call and assign the result to f.
 * If your paclet loads 50 functions during initialization, it may be frustrating for the users to wait that long. Even worse,
 * if you initialized LLU with a relative path to the dynamic library, you will end up calling FindLibrary 50 times, which takes considerable amount of time.
 *
 * One possible solution is to replace "f = " with "f := " ta avoid immediate evaluation of the RHS, but this would result in evaluating RHS every time
 * f is used. To address this, LLU defines a helper function LazyLoad, which can be used in the following way:
 *     LazyLoad[f, PacletFunctionLoad["functionName", {Integer}, String]];
 * This will evaluate the second argument only once, when f is first used.
 *)
Attributes[LazyLoad] = {HoldAll};
LazyLoad[f_, expr_] := (f := f = expr);


(* ::SubSection:: *)
(* RegisterPacletErrors *)
(* ------------------------------------------------------------------------- *)
(* ------------------------------------------------------------------------- *)

RegisterCppErrors[] := AssociateTo[$CorePacletFailureLUT, $GetCErrorCodes[]];

RegisterPacletErrors[errors_?AssociationQ] :=
	Block[{maxIDError, maxID},
		maxIDError = First[MaximalBy[$CorePacletFailureLUT, First], {}];
		maxID = Max[First[maxIDError, 0], $MaxLLUBuiltinErrorID];
		AssociateTo[$CorePacletFailureLUT, MapIndexed[#[[1]] -> {(First[#2] + maxID), #[[2]]} &, Normal[errors]]]
	];

RegisterPacletErrors[___] :=
	ThrowPacletFailure["RegisterFailure"];


(* ::SubSection:: *)
(* CreatePacletFailure *)
(* ------------------------------------------------------------------------- *)
(* ------------------------------------------------------------------------- *)

Options[CreatePacletFailure] = {
	"MessageParameters" -> <||>,
	"Parameters" -> {}
};

CreatePacletFailure[type_?StringQ, opts:OptionsPattern[]] :=
Block[{msgParam, param, errorCode, msgTemplate, errorType},
	msgParam = Replace[OptionValue["MessageParameters"], Except[_?AssociationQ | _List] -> <||>];
	param = Replace[OptionValue["Parameters"], {p_?StringQ :> {p}, Except[{_?StringQ.. }] -> {}}];
	{errorCode, msgTemplate} =
		Lookup[
			$CorePacletFailureLUT
			,
			errorType = type
			,
			(
				AppendTo[msgParam, "ErrorName" -> type];
				$CorePacletFailureLUT[errorType = "UnknownFailure"]
			)
		];
	$ErrorCount++;
	If[errorCode < 0, (* if failure comes from the C++ code, extract message template parameters *)
		{msgParam, param} = GetCCodeFailureParams[msgTemplate];
	];
	Failure[errorType,
		<|
			"MessageTemplate" -> msgTemplate,
			"MessageParameters" -> msgParam,
			"ErrorCode" -> errorCode,
			"Parameters" -> param
		|>
	]
];

(* We need a symbol that will store values for TemplateSlots in the most recently thrown exception. Exceptions are thrown in C++ and slots values provided
 * in ErrorManager::throwException are transferred in a List via WSTP and assigned to this symbol.
 * Later, the error handling routine in WL, CatchLibraryFunctionError, checks this symbol and creates Failure object.
 *)
Clear @ $LastFailureParameters;

GetCCodeFailureParams[msgTemplate_String?StringQ] :=
Block[{slotNames, slotValues, msgParams, selectedSlotValues, params = {}},
	slotNames = Cases[First @ StringTemplate[msgTemplate], TemplateSlot[s_] -> s];
	slotNames = DeleteDuplicates[slotNames];
	slotValues = If[ListQ[$LastFailureParameters], $LastFailureParameters, {}];
	$LastFailureParameters = {};
 	msgParams = If[MatchQ[slotNames, {_Integer..}],
		(* for numbered slots return just a list of slot template values *)
	    slotValues
		, (* otherwise, return an Association with slot names as keys *)
		(* If too many slot values came from C++ code - store the excess in "Params", otherwise - pad with empty strings *)
		{selectedSlotValues, params} = TakeList[slotValues, {UpTo[Length[slotNames]], All}];
		selectedSlotValues = PadRight[slotValues, Length[slotNames], ""];
		If[VectorQ[slotNames, StringQ],
			AssociationThread[slotNames, selectedSlotValues]
			, (* mixed slots are not officially supported but let's do the best we can *)
			MapThread[If[StringQ[#1], <|#1 -> #2|>, #2]&, {slotNames, selectedSlotValues}]
		]
	];
	{msgParams, params}
];


ThrowPacletFailure[type_?StringQ, opts : OptionsPattern[CreatePacletFailure]] :=
	With[{failure = CreatePacletFailure[type, opts]},
		Throw @@ {failure, $ExceptionTagFunction[failure]};
	];

ThrowPacletFailure[type_?StringQ, tag_, opts : OptionsPattern[CreatePacletFailure]] :=
	With[{failure = CreatePacletFailure[type, opts]},
		Throw[failure, tag];
	];

(* ::SubSection:: *)
(* CatchLibraryLinkError *)
(* ------------------------------------------------------------------------- *)
(* ------------------------------------------------------------------------- *)

Attributes[CatchLibraryFunctionError] = {HoldAll};
Attributes[CatchAndThrowLibraryFunctionError] = {HoldAll};

CatchLibraryFunctionError[f_] :=
With[{result = Quiet[f, {
		LibraryFunction::typerr,
		LibraryFunction::rnkerr,
		LibraryFunction::dimerr,
		LibraryFunction::numerr,
		LibraryFunction::memerr,
		LibraryFunction::verserr,
		LibraryFunction::rterr
	}]},

	If[Head[result] === LibraryFunctionError,
		CreatePacletFailure[ErrorCodeToName[result[[2]]]]
		, (* else *)
		result
	]
];

CatchAndThrowLibraryFunctionError[f_] :=
With[{result = Quiet[f, {
		LibraryFunction::typerr,
		LibraryFunction::rnkerr,
		LibraryFunction::dimerr,
		LibraryFunction::numerr,
		LibraryFunction::memerr,
		LibraryFunction::verserr,
		LibraryFunction::rterr
	}]},

	If[Head[result] === LibraryFunctionError,
		ThrowPacletFailure[ErrorCodeToName[result[[2]]]]
		, (* else *)
		result
	]
];

End[]; (* `Private` *)

(* ::SubSection:: *)
(* Config *)
(* ------------------------------------------------------------------------- *)
(* Symbols intended to be modified by paclet developers to better fit their needs. *)

$Throws = True;

$ExceptionTagString = "LLUExceptionTag";

$ExceptionTagFunction := $ExceptionTagString&;

(* ::SubSection:: *)
(* Logging *)
(* ------------------------------------------------------------------------- *)
(* ------------------------------------------------------------------------- *)

Begin["`Logger`"];

(************** Functions defining how to style different parts of a log message *************)

(* Colors associated with different log severities *)
LevelColorMapForLLULogs = <|"Error" -> Red, "Warning" -> Orange, "Debug" -> Darker[Green]|>;

(* Styled part of a message containing log level description *)
StyledLLULogLevel[logLevel_] :=
		Style["[" <> ToString @ logLevel <> "]", LevelColorMapForLLULogs[logLevel]];

(* Styled part of a message containing info on where the log was issued *)
StyledLLULogMessageLocation[file_, line_, fn_] :=
		Tooltip[Style["Line " <> ToString[line] <> " in " <> FileNameTake[file] <> ", function " <> fn, Darker[Gray]], file];

(* Styled part of a message containing the actual log text *)
StyledLLULogMessageText[args_List, size_:Inherited] :=
		Style[StringJoin @@ ToString /@ args, FontSize -> size];

(************* Functions defining how to format a log message *************)

(* Put all message parts in a list unstyled *)
LogToList[args___] := {args};

(* Put all message parts in Association *)
LogToAssociation[logLevel_, line_, file_, fn_, args___] :=
		Association["Level" -> logLevel, "Line" -> line, "File" -> file, "Function" -> fn, "Message" -> StyledLLULogMessageText[{args}]];

(* Combine all log parts to a String. No styling, contains a newline character. *)
LogToString[logLevel_, line_, file_, fn_, args___] :=
	"[" <> ToString @ logLevel <> "] In file " <> file <> ", line " <> ToString[line] <> ", function " <> fn <> ":\n" <> (StringJoin @@ ToString /@ {args});

(* Combine all log parts to a condensed String. No styling, single line (unless message text contains newlines). *)
LogToShortString[logLevel_, line_, file_, fn_, args___] :=
	"[" <> ToString @ logLevel <> "] " <> FileNameTake[file] <> ":" <> ToString[line] <> " (" <> fn <> "): " <> (StringJoin @@ ToString /@ {args});

(* Place fully styled log message in a TextGrid. Looks nice, good default choice for printing to the notebook. *)
LogToGrid[logLevel_, line_, file_, fn_, args___] :=
		TextGrid[{
			{StyledLLULogLevel[logLevel], StyledLLULogMessageLocation[file, line, fn]},
			{SpanFromAbove, StyledLLULogMessageText[{args}, 14]}
		}];

(* Fully styled, condensed log message in a Row. Good choice if you expect many log messages and want to see them all in the notebook. *)
LogToRow[logLevel_, line_, file_, fn_, args___] :=
    Row[{Style["(" <> FileNameTake[file] <> ":" <> ToString[line] <> ")", LevelColorMapForLLULogs[logLevel]], StyledLLULogMessageText[{args}]}];

(* This is a "selector" called by other functions below. Feel free to modify/Block this symbol, see examples. *)
FormattedLog := LogToGrid;


(************* Functions filtering log messages *************)

(* Define a symbol for filtered-out messages *)
LogFiltered = Missing["FilteredOut"];

(* Simple filter that does no filtering *)
FilterAcceptAll[args___] := args;

(* Filter that rejects everything *)
FilterRejectAll[___] := LogFiltered;

(* Meta function for defining filters that filter by a single element of a log: level, line, file name or function name *)
FilterBySingleFeature[featureIndex_][test_] := Sequence @@ If[TrueQ @ test[Slot[featureIndex]], {##}, {LogFiltered}]&;

(* Define single element filters *)
{FilterByLevel, FilterByLine, FilterByFile, FilterByFunction} = (FilterBySingleFeature /@ Range[4]);

(* Define custom filter - test function have access to all elements of the log *)
FilterCustom[test_] := Sequence @@ If[TrueQ @ test[##], {##}, {LogFiltered}]&;

(* This is a "selector" called by other functions below. Feel free to modify/Block this symbol, see examples. *)
LogFilterSelector := FilterAcceptAll;

(************* Functions defining where to place a log message *************)

(* Discard the log *)
DiscardLog[___] := Null;

(* Print to current notebook *)
PrintLogToNotebook[args___] :=
	Print @ FormattedLog[args];
PrintLogToNotebook[LogFiltered] := DiscardLog[];

(* Print to Messages window. Remember that this window may be hidden by default. *)
PrintLogToMessagesWindow[args___] :=
    NotebookWrite[MessagesNotebook[], Cell[RawBoxes @ ToBoxes[FormattedLog[args]], "Output"]];
PrintLogToMessagesWindow[LogFiltered] := DiscardLog[];

(* Append to a list and assign to given symbol. Good choice if you don't want to see the logs immediately, but want to store them for later analysis. *)
Attributes[PrintLogToSymbol] = {HoldFirst};
PrintLogToSymbol[x_] := (
	If[Not @ ListQ @ x,
		x = {}
	];
	AppendTo[x, FormattedLog[##]];
)&;
PrintLogToSymbol[LogFiltered] := DiscardLog[];

(* This is a "selector" called by other functions below. Feel free to modify/Block this symbol, see examples. *)
PrintLogFunctionSelector := PrintLogToNotebook;


(* This is a function WSTP will call from the C++ code. It all starts here. Feel free to modify/Block this symbol, see examples. *)
LogHandler := PrintLogFunctionSelector @* LogFilterSelector;

End[]; (* `Logger` *)


(************* Examples of overriding default logger behavior *************)

(***
	Make logger format logs as Association and append to a list under a symbol TestLogSymbol:

		Logger`PrintLogFunctionSelector := Block[{Logger`FormattedLog = Logger`LogToAssociation},
			Logger`PrintLogToSymbol[TestLogSymbol][##]
		]&

	after you evaluate some library function the TestLogSymbol may be a list similar this:

		{
			<|
				"Level" -> "Debug",
				"Line" -> 17,
				"File" -> "main.cpp",
				"Function" -> "ReadData",
				"Message" -> Style["Library function entered with 4 arguments.", Automatic]
			|>,
			<|
				"Level" -> "Warning",
				"Line" -> 20,
				"File" -> "Utilities.cpp",
				"Function" -> "validateDimensions",
				"Message" -> Style["Dimensions are too large.", Automatic]
			|>,
			...
		}
***)

(***
	Log styled condensed logs to Messages window:

		Logger`PrintLogFunctionSelector := Block[{Logger`FormattedLog = Logger`LogToRow},
			Logger`PrintLogToMessagesWindow[##]
		]&
***)

(***
	Sow logs formatted as short Strings instead of printing:

		Logger`PrintLogFunctionSelector :=
			If[## =!= Logger`LogFiltered,
				Sow @ Logger`LogToShortString[##]
			]&;

	Remember that in this case library functions must be wrapped with Reap.

	You could theoretically write simply

		LLU`Logger`PrintLogFunctionSelector := Sow @* LLU`Logger`LogToShortString;

	But in this case, you are loosing the correct handling of filtered-out messages so it's only fine with the default "accept-all" filter.
***)

Begin["`Private`"];

(* ::SubSection:: *)
(* Managed Expressions *)
(* ------------------------------------------------------------------------- *)
(* ------------------------------------------------------------------------- *)

(* Register Managed Expressions as custom argument type *)
CustomMArgumentTypeQ[a_Managed] := True;

(* When ManagedExpression is passed to a library function it will be translated to an Integer *)
MArgumentCustomType[_Managed] := Integer;

(* Parse ManagedExpression before it is passed to a LibraryFunction. First argument is expected ManagedExpression type and the second is actual instance
 * of a MangedExpression. If the instance type does not match the expected type a paclet Failure will be thrown.
 *)
MArgumentTransform[Managed[expectedHead_]] := Replace[{
	expectedHead[id_Integer] :> If[ManagedLibraryExpressionQ[expectedHead[id]],
		id
		,
		ThrowPacletFailure["InvalidManagedExpressionID", "MessageParameters" -> <|"Expr" -> expectedHead[id]|>]
	]
	,
	id_Integer :> id (* Passing bare IDs of Managed Expressions is supported but may be more error prone than passing proper MLEs *)
	,
	e_ :> ThrowPacletFailure["UnexpectedManagedExpression", "MessageParameters" -> <|"Expected" -> expectedHead, "Actual" -> e|>]
}];

Constructor;

NewManagedExpression[exprHead_][args___] :=
	Block[{res, constructor = Constructor[exprHead]},
		res = CreateManagedLibraryExpression[SymbolName[exprHead], exprHead];
		constructor[ManagedLibraryExpressionID[res], args];
		res
	];

ManagedQ[exprHead_] := ManagedLibraryExpressionQ[#, SymbolName[exprHead]]&;
ManagedIDQ[exprHead_] := ManagedLibraryExpressionQ[exprHead[#], SymbolName[exprHead]]&;

GetManagedID[instance_] := ManagedLibraryExpressionID[instance];

SetAttributes[ClassMemberName, HoldAll];
ClassMemberName[className_, f_] := SymbolName[className] <> "`" <> SymbolName[Unevaluated[f]];

SetAttributes[ClassMember, HoldAll];
ClassMember[className_, f_] := Symbol @ ClassMemberName[className, f];

Options[MemberFunctionSet] = Options[PacletFunctionSet];
Options[LazyMemberFunctionSet] = Options[MemberFunctionSet];

MemberFunctionSet[exprHead_][memberSymbol_?Developer`SymbolQ, libraryName_, fname_, fParams_, retType : Except[_?OptionQ], opts : OptionsPattern[]] := (
	If[Not @ Developer`SymbolQ @ ClassMember[exprHead, memberSymbol],
		Clear @ Evaluate @ ClassMemberName[exprHead, memberSymbol];
	];
	exprHead /: exprHead[id_][memberSymbol[args___]] := ClassMember[exprHead, memberSymbol][exprHead[id], args];
	iLoadLibraryFunction[Evaluate @ ClassMember[exprHead, memberSymbol], Set, MemberFunctionLoad[exprHead], libraryName, fname, fParams, retType, opts];
);
LazyMemberFunctionSet[exprHead_][memberSymbol_?Developer`SymbolQ, libraryName_, fname_, fParams_, retType : Except[_?OptionQ], opts : OptionsPattern[]] := (
	If[Not @ Developer`SymbolQ @ ClassMember[exprHead, memberSymbol],
		Clear @ Evaluate @ ClassMemberName[exprHead, memberSymbol];
	];
	exprHead /: exprHead[id_][memberSymbol[args___]] := ClassMember[exprHead, memberSymbol][exprHead[id], args];
	iLoadLibraryFunction[Evaluate @ ClassMember[exprHead, memberSymbol], LazyLoad, MemberFunctionLoad[exprHead], libraryName, fname, fParams, retType, opts];
);

MemberFunctionSet[exprHead_][memberSymbol_, fname_, fParams_, retType : Except[_?OptionQ], opts : OptionsPattern[]] :=
	MemberFunctionSet[exprHead][memberSymbol, $PacletLibrary, fname, fParams, retType, opts];
LazyMemberFunctionSet[exprHead_][memberSymbol_, fname_, fParams_, retType : Except[_?OptionQ], opts : OptionsPattern[]] :=
	LazyMemberFunctionSet[exprHead][memberSymbol, None, fname, fParams, retType, opts];

MemberFunctionSet[exprHead_][memberSymbol_, fParams_, retType : Except[_?OptionQ], opts : OptionsPattern[]] :=
	MemberFunctionSet[exprHead][memberSymbol, guessFunctionNameFromSymbol[memberSymbol], fParams, retType, opts];
LazyMemberFunctionSet[exprHead_][memberSymbol_, fParams_, retType : Except[_?OptionQ], opts : OptionsPattern[]] :=
	LazyMemberFunctionSet[exprHead][memberSymbol, guessFunctionNameFromSymbol[memberSymbol], fParams, retType, opts];

Options[WSTPMemberFunctionSet] = Options[MemberFunctionSet];
Options[LazyWSTPMemberFunctionSet] = Options[WSTPMemberFunctionSet];

WSTPMemberFunctionSet[exprHead_][memberSymbol_, libraryName_, fname_?StringQ, opts : OptionsPattern[]] :=
	MemberFunctionSet[exprHead][memberSymbol, libraryName, fname, LinkObject, LinkObject, opts];
LazyWSTPMemberFunctionSet[exprHead_][memberSymbol_, libraryName_, fname_?StringQ, opts : OptionsPattern[]] :=
	LazyMemberFunctionSet[exprHead][memberSymbol, libraryName, fname, LinkObject, LinkObject, opts];

WSTPMemberFunctionSet[exprHead_][memberSymbol_, fname_?StringQ, opts : OptionsPattern[]] :=
	MemberFunctionSet[exprHead][memberSymbol, $PacletLibrary, fname, LinkObject, LinkObject, opts];
LazyWSTPMemberFunctionSet[exprHead_][memberSymbol_, fname_?StringQ, opts : OptionsPattern[]] :=
	LazyMemberFunctionSet[exprHead][memberSymbol, None, fname, LinkObject, LinkObject, opts];

WSTPMemberFunctionSet[exprHead_][memberSymbol_, opts : OptionsPattern[]] :=
	MemberFunctionSet[exprHead][memberSymbol, guessFunctionNameFromSymbol[memberSymbol], LinkObject, LinkObject, opts];
LazyWSTPMemberFunctionSet[exprHead_][memberSymbol_, opts : OptionsPattern[]] :=
	LazyMemberFunctionSet[exprHead][memberSymbol, guessFunctionNameFromSymbol[memberSymbol], LinkObject, LinkObject, opts];

End[]; (* `Private` *)

System`Private`RestoreContextPath[];

End[]; (* `LLU` *)
