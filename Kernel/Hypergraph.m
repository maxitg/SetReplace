Package["SetReplace`"]

PackageImport["GeneralUtilities`"]

PackageExport["Hypergraph"]
PackageExport["HypergraphQ"]
PackageExport["HypergraphSymmetry"]

SetRelatedSymbolGroup[Hypergraph, HypergraphQ, HypergraphSymmetry, EdgeList, VertexList];

(* HypergraphQ *)

SetUsage @ "HypergraphQ[hg$] yields True if hg$ is a valid Hypergraph object and False otherwise.";

SyntaxInformation[HypergraphQ] = {"ArgumentsPattern" -> {expr_}};

HypergraphQ[expr_Hypergraph] := System`Private`HoldNoEntryQ[expr];
HypergraphQ[_] = False;

(* HypergraphSymmetry *)

$hypergraphSymmetries = {"Ordered", "Unordered", "Cyclic"(*, "Directed"*)};

SetUsage @ "HypergraphSymmetry[hg$] returns the symmetry of the hypergraph hg$.";

HypergraphSymmetry[HoldPattern[Hypergraph[hyperedges_, symmetry_] ? HypergraphQ]] := symmetry;

(* Hypergraph *)

SetUsage[Hypergraph, "
Hypergraph[{he$1, he$2, $$}] yields an ordered hypergraph with hyperedges he$j.
Hypergraph[$$, sym$] returns a hypergraph with symmetry sym$.
* Valid hypergraph symmetries include: " <> listToSentence[$hypergraphSymmetries] <> ".
"];

SyntaxInformation[Hypergraph] = {"ArgumentsPattern" -> {hyperedges_, symmetry_.}};

Hypergraph /: Information`GetInformation[obj_Hypergraph ? HypergraphQ] :=
  <|
    "ObjectType" -> Hypergraph,
    "Symmetry" -> HypergraphSymmetry[obj],
    "VertexCount" -> VertexCount[obj],
    "EdgeCount" -> EdgeCount[obj]
  |>;

((expr : Hypergraph[args___]) ? System`Private`HoldEntryQ) /; CheckArguments[expr, {1, 2}] :=
  With[{
      result = Catch[hypergraph[args],
                     _ ? FailureQ,
                     message[Hypergraph, #, <|"expr" -> HoldForm[expr]|>] &]
    },
    result /; !FailureQ[result]
  ];

hypergraph[h_] := hypergraph[h, "Ordered"];

hypergraph[hyperedges : {___List}, symmetry : Alternatives @@ $hypergraphSymmetries] :=
  System`Private`ConstructNoEntry[Hypergraph, hyperedges, symmetry];

declareMessage[Hypergraph::invalidHyperedges,
               "The argument at position 1 in `expr` should be a list of of lists."];

hypergraph[hyperedges_, symmetry : Alternatives @@ $hypergraphSymmetries] :=
  throw[Failure["invalidHyperedges", <||>]];

declareMessage[Hypergraph::invalidSymmetry,
               "The argument at position 2 in `expr` should be a supported symmetry: `symmetries`."];

hypergraph[hyperedges_, symmetry_] :=
  throw[Failure["invalidSymmetry", <|"symmetries" -> $hypergraphSymmetries|>]];

(* Accessors *)

Hypergraph /: EdgeList[HoldPattern[Hypergraph[hyperedges_, _] ? HypergraphQ]] := hyperedges;

Hypergraph /: EdgeCount[hg_Hypergraph ? HypergraphQ] := Length[EdgeList[hg]];

Hypergraph /: VertexList[hg_Hypergraph ? HypergraphQ] := DeleteDuplicates[Catenate[EdgeList[hg]]];

Hypergraph /: VertexCount[hg_Hypergraph ? HypergraphQ] := Length[VertexList[hg]];

(* Normal *)

Hypergraph /: Normal[hg_Hypergraph ? HypergraphQ] := EdgeList[hg];

(* SameQ *)

Hypergraph /: SameQ[hg1_Hypergraph, hg2_Hypergraph] := Normal[hg1] === Normal[hg2];

(* Boxes *)

disablePlotQ = TrueQ[EdgeCount[#] > 100] &;

$iconSize = Dynamic[{Automatic, 3.5` CurrentValue["FontCapHeight"]/ AbsoluteCurrentValue[Magnification]}];

getIcon[hg_] /; (!disablePlotQ[hg] && MemberQ[$edgeTypes, HypergraphSymmetry[hg]]) :=
  HypergraphPlot[EdgeList[hg], HypergraphSymmetry[hg], ImageSize -> $iconSize];

getIcon[_] = style[$lightTheme][$evolutionObjectIcon];

Hypergraph /: MakeBoxes[hg_Hypergraph ? HypergraphQ, fmt_] :=
  Module[{collapsed, expanded},
    collapsed = BoxForm`SummaryItem /@ {
      {"VertexCount: ", VertexCount[hg]},
      {"EdgeCount: ", EdgeCount[hg]}
    };
    expanded = BoxForm`SummaryItem /@ {
      {"Symmetry: ", HypergraphSymmetry[hg]}
    };
    BoxForm`ArrangeSummaryBox[
      Hypergraph,
      hg,
      getIcon[hg],
      collapsed,
      expanded,
      fmt,
      "Interpretable" -> True
    ]
  ];
