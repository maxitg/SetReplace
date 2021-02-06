<|
  "GraphDimension" -> <|
    "init" -> (
      Attributes[Global`testUnevaluated] = {HoldAll};
      Global`testUnevaluated[args___] := SetReplace`PackageScope`testUnevaluated[VerificationTest, args];
    ),
    "tests" -> {
      With[{
        dag = Graph[{1 -> 2, 2 -> 3}],
        loopGraph = Graph[{1 -> 1, 1 -> 2}],
        undirectedGraph = Graph[{1 <-> 2, 2 <-> 3}],
        cyclicGraph = Graph[{1 -> 2, 2 -> 1}],
        $flatRelationProb = "FlatCausalDiamondRelationProbability"
      },
      {
        (* Verification tests *)
        VerificationTest[
          GraphDimension[Graph[{1 -> 2, 2 -> 3}], $flatRelationProb, {1, 2}],
          2,
          SameTest -> Equal
        ],

        Module[{d},
          {
            VerificationTest[
              GraphDimension[DirectedGraph[PathGraph[Range[100]], "Acyclic"], $flatRelationProb, {1, 90}],
              Replace[d, FindRoot[(Gamma[d + 1]*Gamma[d/2])/(4 Gamma[3 d/2]) == Binomial[90, 2]/(90^2), {d, 1, 5}]],
              SameTest -> Equal
            ],

            VerificationTest[
              GraphDimension[IndexGraph[Graph[Join["i" -> # & /@ Range[1000], # -> "o" & /@ Range[1000]]]], 
                "FlatCausalDiamondRelationProbability", {1, 1002}],
              Replace[d, FindRoot[(Gamma[d + 1]*Gamma[d/2])/(4 Gamma[3 d/2]) == (2*(1002 - 2) + 1)/(1002^2), {d,1, 10}]]
            ]
          }
        ],

        VerificationTest[
          GraphDimension[Graph[{1 -> 2, 2 -> 3, 4 -> 5}], $flatRelationProb, {1, 5}],
          Infinity
        ],

        VerificationTest[
          GraphDimension[Graph[{1 -> 2, 2 -> 3}], $flatRelationProb, {1, 1}],
          Infinity
        ],

        (* unevaluated *)

        (* argument count *)
        testUnevaluated[
          GraphDimension[],
          {GraphDimension::argrx}
        ],

        testUnevaluated[
          GraphDimension[dag, ],
          {GraphDimension::argrx}
        ],

        (* First argument *)
        testUnevaluated[
          GraphDimension[loopGraph, $flatRelationProb, {1, 2}],
          {GraphDimension::invalidGraph}
        ],

        testUnevaluated[
          GraphDimension[undirectedGraph, $flatRelationProb, {1, 2}],
          {GraphDimension::invalidGraph}
        ],

        testUnevaluated[
          GraphDimension[cyclicGraph, $flatRelationProb, {1, 2}],
          {GraphDimension::invalidGraph}
        ],

        (* Second argument *)
        testUnevaluated[
          GraphDimension[dag, "TestMethod", {1, 2}],
          {GraphDimension::invalidMethod}
        ],

        testUnevaluated[
          GraphDimension[dag, {}, {1, 2}],
          {GraphDimension::invalidMethod}
        ],

        (* Third argument *)
        testUnevaluated[
          GraphDimension[dag, $flatRelationProb, {}],
          {GraphDimension::invalidVertexList}
        ],

        testUnevaluated[
          GraphDimension[dag, $flatRelationProb, {1, 50}],
          {GraphDimension::invalidVertex}
        ],

        testUnevaluated[
          GraphDimension[dag, $flatRelationProb, {50, 1}],
          {GraphDimension::invalidVertex}
        ]
        }
      ]
    },
    "options" -> <|"Parallel" -> False|>
  |>
|>
