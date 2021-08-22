Package["SetReplace`"]

PackageImport["GeneralUtilities`"]

PackageExport["Subhypergraph"]
PackageExport["WeakSubhypergraph"]

(* Documentation *)
SetUsage @ "
Subhypergraph[hypergraph$, vertexList$] selects hyperedges from hypergraph$ that are subsets of vertexList$.
Subhypergraph[vertexList$] represents the operator form for a hypergraph.
";

SetUsage @ "
WeakSubhypergraph[hypergraph$, vertexList$] selects hyperedges from hypergraph$ such that any of their elements are \
contained in vertexList$.
WeakSubhypergraph[vertexList$] represents the operator form for a hypergraph.
";

(* SyntaxInformation *)
SyntaxInformation[Subhypergraph] =
  {"ArgumentsPattern" -> {hypergraph_, vertexList_.}};

SyntaxInformation[WeakSubhypergraph] =
  {"ArgumentsPattern" -> {hypergraph_, vertexList_.}};

(* Argument count *)
Subhypergraph[args___] := 0 /;
  !CheckArguments[Subhypergraph[args], {1, 2}] && False;

WeakSubhypergraph[args___] := 0 /;
  !CheckArguments[WeakSubhypergraph[args], {1, 2}] && False;

(* main *)
expr : Subhypergraph[hypergraph_, vertexList_] :=
  With[{
      result = Catch[subhypergraph[hypergraph, vertexList],
                     _ ? FailureQ,
                     message[Subhypergraph, #, <|"expr" -> HoldForm[expr]|>] &]
    },
    result /; !FailureQ[result]
  ];

expr : WeakSubhypergraph[hypergraph_, vertexList_] :=
  With[{
      result = Catch[weakSubhypergraph[hypergraph, vertexList],
                     _ ? FailureQ,
                     message[WeakSubhypergraph, #, <|"expr" -> HoldForm[expr]|>] &]
    },
    result /; !FailureQ[result]
  ];

(* operator form *)
expr : Subhypergraph[args0___][args1___] :=
  With[{
      result = Catch[subhypergraph[args0][args1],
                     _ ? FailureQ,
                     message[Subhypergraph, #, <|"expr" -> HoldForm[expr]|>] &]
    },
    result /; !FailureQ[result]
  ];

expr : WeakSubhypergraph[args0___][args1___] :=
  With[{
      result = Catch[weakSubhypergraph[args0][args1],
                     _ ? FailureQ,
                     message[WeakSubhypergraph, #, <|"expr" -> HoldForm[expr]|>] &]
    },
    result /; !FailureQ[result]
  ];

(* Validation *)
$supportedHypergraphSymmetries = {"Ordered", "Unordered", "Cyclic"};

validHypergraph[hypergraph_ ? HypergraphQ] := MemberQ[$supportedHypergraphSymmetries, HypergraphSymmetry[hypergraph]];
validHypergraph[hyperedges : {___List}] := True;
validHypergraph[_] = False;

(* Normal form *)

subhypergraph[h_Hypergraph ? validHypergraph, vertices_List] :=
  Hypergraph[Select[Normal[h], SubsetQ[vertices, #] &], HypergraphSymmetry[h]];

weakSubhypergraph[h_Hypergraph ? validHypergraph, vertices_List] :=
  Hypergraph[Select[Normal[h], ContainsAny[#, vertices] &], HypergraphSymmetry[h]];

subhypergraph[h_List ? validHypergraph, vertices_List] :=
  Normal[subhypergraph[Hypergraph[h], vertices]];

weakSubhypergraph[h_List ? validHypergraph, vertices_List] :=
  Normal[weakSubhypergraph[Hypergraph[h], vertices]];

(* Incorrect arguments messages *)

(** hypergraph **)
With[{sym = #},
  declareMessage[sym::invalidHypergraph,
                 "The argument at position `pos` in `expr` should be a Hypergraph object or a lists of lists."]
] & /@ {Subhypergraph, WeakSubhypergraph};

subhypergraph[h_ ? (Not @* validHypergraph), _] :=
  throw[Failure["invalidHypergraph", <|"pos" -> 1|>]];

weakSubhypergraph[h_ ? (Not @* validHypergraph), _] :=
  throw[Failure["invalidHypergraph", <|"pos" -> 1|>]];

(** vertices **)
With[{sym = #},
  declareMessage[sym::invalidVertices,
                 "The argument at position `pos` in `expr` should be a list representing vertices."]
] & /@ {Subhypergraph, WeakSubhypergraph};

subhypergraph[_ , v : Except[_List]] :=
  throw[Failure["invalidVertices", <|"pos" -> 2|>]];

weakSubhypergraph[_ , v : Except[_List]] :=
  throw[Failure["invalidVertices", <|"pos" -> 2|>]];

(* operator form *)
subhypergraph[vertices_List][h_ ? validHypergraph] := subhypergraph[h, vertices];

weakSubhypergraph[vertices_List][h_ ? validHypergraph] := weakSubhypergraph[h, vertices];

(* Incorrect arguments messages *)

(** vertices **)
subhypergraph[Except[_List]][_] :=
  throw[Failure["invalidVertices", <|"pos" -> {0, 1}|>]];

weakSubhypergraph[Except[_List]][_] :=
  throw[Failure["invalidVertices", <|"pos" -> {0, 1}|>]];

(** hypergraph **)
subhypergraph[args0___][h_ ? (Not @* validHypergraph)] :=
  throw[Failure["invalidHypergraph", <|"pos" -> 1|>]];

weakSubhypergraph[args0___][h_ ? (Not @* validHypergraph)] :=
  throw[Failure["invalidHypergraph", <|"pos" -> 1|>]];

(** length **)
With[{sym = #},
  declareMessage[sym::invalidArgumentLength,
                 "`expr` called with `received` arguments; `expected` argument is expected."]
] & /@ {Subhypergraph, WeakSubhypergraph};

subhypergraph[args0___][args1___] /; (Length[{args1}] =!= 1) :=
  throw[Failure["invalidArgumentLength", <|"received" -> Length[{args1}], "expected" -> 1|>]];

weakSubhypergraph[args0___][args1___] /; (Length[{args1}] =!= 1) :=
  throw[Failure["invalidArgumentLength", <|"received" -> Length[{args1}], "expected" -> 1|>]];
