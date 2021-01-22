<|
  "AcyclicGraphTake" -> <|
    "init" -> (
      Attributes[Global`testUnevaluated] = {HoldAll};
      Global`testUnevaluated[args___] := SetReplace`PackageScope`testUnevaluated[VerificationTest, args];
    ),
    "tests" -> {
      (* Verification tests *)
      VerificationTest[
        EdgeList[AcyclicGraphTake[Graph[{1 -> 2, 2 -> 3, 2 -> 4, 3 -> 4, 4 -> 5, 5 -> 6}], {2, 5}]],
        EdgeList[Graph[{2 -> 3, 2 -> 4, 3 -> 4, 4 -> 5}]]
      ],

      VerificationTest[
        EdgeList[AcyclicGraphTake[Graph[{1 -> 2, 2 -> 3, 3 -> 4, 4 -> 5}], {2, 5}]],
        EdgeList[Graph[{2 -> 3, 3 -> 4, 4 -> 5}]]
      ],

      VerificationTest[
        AcyclicGraphTake[Graph[{1 -> 2, 2 -> 3, 3 -> 4}], {1, 1}],
        Graph[{1}, {}]
      ],

      VerificationTest[
        EdgeList[AcyclicGraphTake[Graph[{1 -> 2, 2 -> 3, 4 -> 3}], {1, 4}]],
        {}
      ],

      (* unevaluated *)

      (* argument count *)
      With[{
        dag = Graph[{1 -> 2, 2 -> 3}],
        loopGraph = Graph[{1 -> 1, 1 -> 2}],
        undirectedGraph = Graph[{1 <-> 2, 2 <-> 3}],
        cyclicGraph = Graph[{1 -> 2, 2 -> 1}]
      },
      {
        testUnevaluated[
          AcyclicGraphTake[],
          {AcyclicGraphTake::argrx}
        ],

        testUnevaluated[
          AcyclicGraphTake[x],
          {AcyclicGraphTake::argr}
        ],

        (* first argument: graph *)
        testUnevaluated[
          AcyclicGraphTake[x, ],
          {AcyclicGraphTake::invalidGraph}
        ],

        testUnevaluated[
          AcyclicGraphTake[loopGraph, x],
          {AcyclicGraphTake::invalidGraph}
        ],

        testUnevaluated[
          AcyclicGraphTake[undirectedGraph, x],
          {AcyclicGraphTake::invalidGraph}
        ],

        testUnevaluated[
          AcyclicGraphTake[cyclicGraph, x],
          {AcyclicGraphTake::invalidGraph}
        ],

        (* second argument: vertex list *)
        testUnevaluated[
          AcyclicGraphTake[dag, x],
          {AcyclicGraphTake::invalidVertexList}
        ],

        testUnevaluated[
          AcyclicGraphTake[dag, {x, y, z}],
          {AcyclicGraphTake::invalidVertexList}
        ],

        testUnevaluated[
          AcyclicGraphTake[dag, {6, 1}],
          {AcyclicGraphTake::invalidVertex}
        ],

        testUnevaluated[
          AcyclicGraphTake[dag, {1, 6}],
          {AcyclicGraphTake::invalidVertex}
        ]
        }
      ]
    }
  |>
|>
      