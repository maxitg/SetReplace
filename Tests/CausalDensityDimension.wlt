<|
  "CausalDensityDimension" -> <|
    "init" -> (
      Attributes[Global`testUnevaluated] = {HoldAll};
      Global`testUnevaluated[args___] := SetReplace`PackageScope`testUnevaluated[VerificationTest, args];
    ),
    "tests" -> {
      With[{
        dag = Graph[{1 -> 2, 2 -> 3}],
        loopGraph = Graph[{1 -> 1, 1 -> 2}],
        undirectedGraph = Graph[{1 <-> 2, 2 <-> 3}],
        cyclicGraph = Graph[{1 -> 2, 2 -> 1}]
      },
      {
        (* Verification tests *)

        VerificationTest[
          CausalDensityDimension[Graph[{1 -> 2, 2 -> 3}], {1, 2}],
          2,
          SameTest -> Equal
        ],

        Module[{d},
          {
            VerificationTest[
              CausalDensityDimension[DirectedGraph[PathGraph[Range[100]], "Acyclic"], {1, 90}],
              Replace[d, FindRoot[
                (Gamma[d + 1] * Gamma[d / 2]) / (4 Gamma[3 d / 2]) == Binomial[90, 2] / (90^2), {d, 1, 5}]],
              SameTest -> Equal
            ],

            VerificationTest[
              CausalDensityDimension[IndexGraph[Graph[Join["i" -> # & /@ Range[1000], # -> "o" & /@ Range[1000]]]],
                {1, 1002}], Replace[d, FindRoot[
                  (Gamma[d + 1] * Gamma[d / 2]) / (4 Gamma[3 d / 2]) == (2 * (1002 - 2) + 1)/(1002^2), {d, 1, 10}]],
              SameTest -> Equal
            ]
          }
        ],

        VerificationTest[
          CausalDensityDimension[Graph[{1 -> 2, 2 -> 3, 4 -> 5}],{1, 5}],
          Infinity
        ],

        VerificationTest[
          CausalDensityDimension[Graph[{1 -> 2, 2 -> 3}], {1, 1}],
          Infinity
        ],

        (* unevaluated *)

        (* argument count *)
        testUnevaluated[
          CausalDensityDimension[],
          {CausalDensityDimension::argrx}
        ],

        testUnevaluated[
          CausalDensityDimension[dag],
          {CausalDensityDimension::argr}
        ],

        (* First argument *)

        testUnevaluated[
          CausalDensityDimension[loopGraph, {1, 2}],
          {CausalDensityDimension::invalidGraph}
        ],

        testUnevaluated[
          CausalDensityDimension[undirectedGraph, {1, 2}],
          {CausalDensityDimension::invalidGraph}
        ],

        testUnevaluated[
          CausalDensityDimension[cyclicGraph, {1, 2}],
          {CausalDensityDimension::invalidGraph}
        ],

        (* Second argument *)

        testUnevaluated[
          CausalDensityDimension[dag, {}],
          {CausalDensityDimension::invalidVertexList}
        ],

        testUnevaluated[
          CausalDensityDimension[dag, {1, 50}],
          {CausalDensityDimension::invalidVertex}
        ],

        testUnevaluated[
          CausalDensityDimension[dag, {50, 1}],
          {CausalDensityDimension::invalidVertex}
        ]
        }
      ]
    },
    "options" -> <|"Parallel" -> False|>
  |>
|>
