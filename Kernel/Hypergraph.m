Package["SetReplace`"]

PackageImport["GeneralUtilities`"]

PackageExport["Hypergraph"]
PackageExport["HypergraphQ"]
PackageExport["HypergraphOrderedQ"]

SetRelatedSymbolGroup[Hypergraph, HypergraphQ, HypergraphOrderedQ, EdgeList, VertexList];

(* HypergraphQ *)

SetUsage @ "HypergraphQ[hg$] yields True if hg$ is a valid Hypergraph object and False otherwise.";

SyntaxInformation[HypergraphQ] = {"ArgumentsPattern" -> {expr_}};

HypergraphQ[hypergraph_Hypergraph] := System`Private`HoldNoEntryQ[hypergraph];
HypergraphQ[_] = False;

(* HypergraphOrderedQ *)

SetUsage @ "HypergraphOrderedQ[hg$] yields True if hg$ is a ordered Hypergraph object and False otherwise.";

SyntaxInformation[HypergraphOrderedQ] = {"ArgumentsPattern" -> {hypergraph_}};

HypergraphOrderedQ[HoldPattern[Hypergraph[_, orderedQ_] ? HypergraphQ]] := orderedQ;

HypergraphOrderedQ[_] = False;

(* Hypergraph *)

SetUsage @ "
Hypergraph[{he$1, he$2, $$}] yields a hypergraph with hyperedges he$j.
Hypergraph[$$, ord$] returns an ordered hypergraph if ord$ is True, and an unordered hypergraph if False.
";

SyntaxInformation[Hypergraph] = {"ArgumentsPattern" -> {hyperedges_, orderedQ_.}};

Hypergraph[hyperedges_, orderedQ : (True | False) : False] ? System`Private`HoldEntryQ :=
  If[hypergraphQ[hyperedges],
    System`Private`ConstructNoEntry[Hypergraph, Hyperedge @@@ hyperedges, orderedQ]
  ,
    $Failed
  ];

hypergraphQ = MatchQ[{(_List | _Hyperedge) ...}];

(* EdgeList, EdgeCount, VertexList, VertexCount *)

Hypergraph /: EdgeList[HoldPattern[Hypergraph[hyperedgeList_, _] ? HypergraphQ]] :=
  hyperedgeList;

Hypergraph /: EdgeCount[hypergraph_Hypergraph ? HypergraphQ] :=
  Length[EdgeList[hypergraph]];

Hypergraph /: VertexList[hypergraph_Hypergraph ? HypergraphQ] :=
  DeleteDuplicates[Catenate[Cases[EdgeList[hypergraph], Hyperedge[x___] :> {x}, {1}]]];

Hypergraph /: VertexCount[hypergraph_Hypergraph ? HypergraphQ] :=
  Length[VertexList[hypergraph]];

(* Normal *)

Hypergraph /: Normal[hypergraph_Hypergraph ? HypergraphQ] := List @@@ EdgeList[hypergraph];

(* SameQ *)

Hypergraph /: SameQ[hg1_Hypergraph, hg2_Hypergraph] := Normal[hg1] === Normal[hg2];

(* HypergraphPlot *)

Hypergraph /: HypergraphPlot[hypergraph_Hypergraph ? HypergraphQ, opts___] := HypergraphPlot[Normal[hypergraph], opts];

(* Boxes *)

Hypergraph /: MakeBoxes[hypergraph_Hypergraph, fmt_] /; HypergraphQ[hypergraph] :=
  Module[{collapsed, expanded},
    collapsed = BoxForm`SummaryItem /@ {
      {"VertexCount: ", VertexCount[hypergraph]},
      {"EdgeCount: ", EdgeCount[hypergraph]}
    };
    expanded = BoxForm`SummaryItem /@ {
      {"OrderedQ: ", HypergraphOrderedQ[hypergraph]}
    };
    BoxForm`ArrangeSummaryBox[
      Hypergraph,
      hypergraph,
      HypergraphPlot[hypergraph, ImageSize -> {29, 29}],
      collapsed,
      expanded,
      fmt,
      "Interpretable" -> True
    ]
  ];

(* WolframModel *)

Hypergraph /: WolframModel[rule_, hypergraph_Hypergraph, args___] :=
  WolframModel[rule, Normal[hypergraph], args];

(* HypergraphToGraph *)

Hypergraph /: HypergraphToGraph[hypergraph_Hypergraph, args___] :=
  HypergraphToGraph[Normal[hypergraph], args];

(*
(* CanonicalHypergraph *)

(* ::Text:: *)
(*Does CanonicalHypergraph take into consideration if the hypergraph is ordered?*)

Hypergraph /: (func : ResourceFunction["CanonicalHypergraph"])[hypergraph_Hypergraph ? HypergraphQ] :=
  Hypergraph[func[Normal[hypergraph]]]

(*AdjacencyTensor*)

AdjacencyTensor = ResourceFunction["AdjacencyTensor"][Normal[#], "OrderedHyperedges" -> HypergraphOrderedQ[#]] &;

Hypergraph /: (func : ResourceFunction["AdjacencyTensor"])[hypergraph_Hypergraph ? HypergraphQ, opts : OptionsPattern[]] :=
  func[Normal[hypergraph], opts, "OrderedHyperedges" -> HypergraphOrderedQ[hypergraph]]

(*KirchhoffTensor*)

Hypergraph /: (func : ResourceFunction["KirchhoffTensor"])[hypergraph_Hypergraph ? HypergraphQ, opts : OptionsPattern[]] :=
  func[Normal[hypergraph], opts, "OrderedHyperedges" -> HypergraphOrderedQ[hypergraph]]
*)
