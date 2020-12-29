(* Wolfram Language Test file *)
TestRequirement[$VersionNumber >= 12.0];
(***************************************************************************************************************************************)
(*
	Set of test cases to test LLU functionality related to asynchronous tasks and thread pools
*)
(***************************************************************************************************************************************)
TestExecute[
	Needs["CCompilerDriver`"];
	currentDirectory = DirectoryName[$TestFileName];

	(* Get configuration (path to LLU sources, compilation options, etc.) *)
	Get[FileNameJoin[{ParentDirectory[currentDirectory], "TestConfig.wl"}]];

	(* Thread pool functionality requires C++17 *)
	$CppVersion = "c++17";

	Get[FileNameJoin[{$LLUSharedDir, "LibraryLinkUtilities.wl"}]];

	(* A function that will build the test library and load it initializing LLU. We don't want it to run immediately. It must be evaluated only once,
	 * right before any of the library functions is first used. *)
	loader[] := With[
		{
			(* Compile the test library *)
			lib = CCompilerDriver`CreateLibrary[
				FileNameJoin[{currentDirectory, "TestSources", #}]& /@ {"PoolTest.cpp"},
				"Async",
				options,
				"Defines" -> {"LLU_LOG_DEBUG"}
			]
		},
		loader::init = "Initializing Async unit test library.";
		Message[loader::init];
		`LLU`Logger`FormattedLog := `LLU`Logger`LogToShortString;
		lib
	];
	`LLU`LazyInitializePacletLibrary[loader[]];

	`LLU`LazyPacletFunctionSet @@@ {
		(* SleepyThreads[n, m, t] spawns n threads and performs m jobs on them, where each job is just sleeping t milliseconds *)
		{SleepyThreads, {Integer, Integer, Integer}, "Void"},
		(* SleepyThreadsWithPause[n, m, t] works same as SleepyThreads but pauses the pool for 1 second, submits all tasks and then resumes. *)
		{SleepyThreadsWithPause, {Integer, Integer, Integer}, "Void"},
		(* Same as SleepyThreads only using Basic thread pool. *)
		{SleepyThreadsBasic, {Integer, Integer, Integer}, "Void"},

		(* ParallelAccumulate[NA, n, bs] separates a NumericArray NA into blocks of bs elements and sums them in parallel on n threads.
		 * Returns a one-element NumericArray with the sum of all elements of NA *)
		{ParallelAccumulate, "Accumulate", {{NumericArray, "Constant"}, Integer, Integer}, NumericArray},
		{SequentialAccumulate, "AccumulateSequential", {{NumericArray, "Constant"}}, NumericArray},
		{ParallelAccumulateBasic, "AccumulateBasic", {{NumericArray, "Constant"}, Integer, Integer}, NumericArray},

		(* ParallelLcm[NA, n, bs] calculates LCM of all "UnsignedIntegers64" in NA recursively, running in parallel on n threads.
	     * This function tests running async jobs on a thread pool that can themselves submit new jobs to the pool. *)
		{ParallelLcm, "LcmParallel", {{NumericArray, "Constant"}, Integer, Integer}, NumericArray},
		{SequentialLcm, "LcmSequential", {{NumericArray, "Constant"}}, NumericArray}
	};
];

Test[
	(* At this point the library has not been initialized and not even compiled yet.
	 * Evaluating $PacletLibrary will cause the library (set in LazyInitializePacletLibrary) to be loaded. *)
	Select[Compile`LoadedLibraries[], FileBaseName[#] === "Async" &]
	,
	{}
	,
	TestID -> "AsyncTestSuite-20190718-I7S1K0"
];

TestMatch[
	(* First evaluation of a library function symbol will load that function after it builds and loads the library as part of the pre-load routine. *)
	SleepyThreads
	,
	Composition[`LLU`Private`CatchAndThrowLibraryFunctionError, LibraryFunction[___]]
	,
	loader::init (* The loader function issues a message so that we can easily identify all places where it runs. *)
	,
	TestID -> "AsyncTestSuite-20200401-Z5G9U3"
];

TestMatch[
	AbsoluteTiming[SleepyThreads[8, 40, 100]] (* sleep 100ms 40 times which totals to 4s, divided onto 8 threads, so it should take slightly more than 0.5s *)
	,
	{ t_, Null } /; (t >= 0.49 && t < 0.6)
	,
	TestID -> "AsyncTestSuite-20200401-Y8E2H0"
];

TestMatch[
	AbsoluteTiming[SleepyThreadsWithPause[8, 40, 100]] (* it should take slightly more than 0.5s + 1s paused, so >1.5s *)
	,
	{ t_, Null } /; (t >= 1.49 && t < 2)
	,
	TestID -> "AsyncTestSuite-20200113-X6B2Q8"
];

TestMatch[
	AbsoluteTiming[SleepyThreadsBasic[8, 40, 100]]
	,
	{ t_, Null } /; (t >= 0.49 && t < 0.6)
	,
	TestID -> "AsyncTestSuite-20200115-S8F3X4"
];

VerificationTest[
	data = NumericArray[RandomInteger[{-100, 100}, 10000000], "Integer16"];
	{systemTime, sum} = RepeatedTiming @ SequentialAccumulate[data];
	Print["SequentialAccumulate[] time for Integer16 = ", systemTime];
	{parallelTime, parallelSum} = RepeatedTiming @ ParallelAccumulate[data, 8, 5000];
	Print["ParallelAccumulate[] time for Integer16 = ", parallelTime];
	parallelSum == sum
	,
	TestID -> "AsyncTestSuite-20191219-Y8B1L5"
];

VerificationTest[
	data = NumericArray[RandomComplex[{-100 - 100I, 100 + 100I}, 10000000], "ComplexReal64"];
	{systemTime, sum} = RepeatedTiming @ SequentialAccumulate[data];
	Print["SequentialAccumulate[] time for ComplexReal64 = ", systemTime];
	{parallelTime, parallelSum} = RepeatedTiming @ ParallelAccumulate[data, 8, 5000];
	Print["ParallelAccumulate[] time for ComplexReal64 = ", parallelTime];
	Abs[First @ Normal[parallelSum - sum]] < 0.00001
	,
	TestID -> "AsyncTestSuite-20191219-O4K0H1"
];

VerificationTest[
	data = NumericArray[RandomInteger[{-100, 100}, 10000000], "Integer32"];
	{systemTime, sum} = RepeatedTiming @ SequentialAccumulate[data];
	Print["SequentialAccumulate[] time for Integer32 = ", systemTime];
	parallelTime = First @ RepeatedTiming @ ParallelAccumulate[data, 8, 5000];
	Print["ParallelAccumulate[] time for Integer32 = ", parallelTime];
	{parallelTime, parallelSum} = RepeatedTiming @ ParallelAccumulateBasic[data, 8, 5000];
	Print["ParallelAccumulate[] with basic pool time for Integer32 = ", parallelTime];
	parallelSum == sum
	,
	TestID -> "AsyncTestSuite-20200115-P8I3W8"
];

(* Uncomment to see how parallel accumulate compares to Total. *)
(*
VerificationTest[
	data = NumericArray[RandomInteger[{-100, 100}, 50000000], "Integer64"];
	{systemTime, sum} = RepeatedTiming @ Total[data, Infinity];
	Print["Total[] time = ", systemTime];
	{parallelTime, parallelSum} = RepeatedTiming @ ParallelAccumulate[data, 8, 50000];
	Print["ParallelAccumulate[] time = ", parallelTime];
	First @ Normal @ parallelSum == sum
	,
	TestID -> "AsyncTestSuite-20191223-T8T9H1"
];

VerificationTest[
	data = NumericArray[RandomComplex[{-100 - 100I, 100 + 100I}, 50000000], "ComplexReal64"];
	{systemTime, sum} = RepeatedTiming @ Total[data, Infinity];
	Print["Total[] time = ", systemTime];
	{parallelTime, parallelSum} = RepeatedTiming @ ParallelAccumulate[data, 8, 50000];
	Print["ParallelAccumulate[] time = ", parallelTime];
	Abs[First @ Normal @ parallelSum - sum] < 0.00001
	,
	TestID -> "AsyncTestSuite-20191223-J9V5Q1"
];
*)

VerificationTest[
	data = NumericArray[RandomInteger[{0, 40}, 10000000], "UnsignedInteger64"];
	{systemTime, lcmSeq} = RepeatedTiming @ SequentialLcm[data];
	Print["SequentialLcm[] time = ", systemTime];
	{parallelTime, parallelLcm} = RepeatedTiming @ ParallelLcm[data, 12, 5000];
	Print["ParallelLcm[] time = ", parallelTime];
	(parallelLcm == lcmSeq) && (First @ Normal[parallelLcm] == LCM @@ Normal[data])
	,
	TestID -> "AsyncTestSuite-20191227-Y7R7Q4"
];
