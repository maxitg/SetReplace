<|
  "AcyclicGraphTake" -> <|
    "init" -> (
      Attributes[Global`testUnevaluated] = {HoldAll};
      Global`testUnevaluated[args___] := SetReplace`PackageScope`testUnevaluated[VerificationTest, args];
    ),
    "tests" -> {

      (* Verification tests *)
      VerificationTest[
        Sort[EdgeList[AcyclicGraphTake[Graph[{1 -> 2, 2 -> 3, 2 -> 4, 3 -> 4, 4 -> 5, 5 -> 6}], {2, 5}]]],
        Sort[EdgeList[Graph[{2 -> 3, 2 -> 4, 3 -> 4, 4 -> 5}]]]
      ]

      VerificationTest[
        Sort[EdgeList[AcyclicGraphTake[Graph[{1 -> 1, 1 -> 2, 2 -> 3, 4 -> 5}], {1, 3}]]],
        Sort[EdgeList[Graph[{1 -> 1, 1 -> 2, 2 -> 3}]]]
      ]


      (* unevaluated *)

      (* argument count *)
      testUnevaluated[
        AcyclicGraphTake[],
        {AcyclicGraphTake::argr}
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
        AcyclicGraphTake[DirectedGraph[RandomGraph[{5, 5}]], x],
        {AcyclicGraphTake::invalidGraph}
      ],

      (* second argument: vertex list *)
      testUnevaluated[
        AcyclicGraphTake[DirectedGraph[RandomGraph[{5, 5}], "Acyclic"], x],
        {AcyclicGraphTake::invalidVertexList}
      ],

      testUnevaluated[
        AcyclicGraphTake[DirectedGraph[RandomGraph[{5, 5}], "Acyclic"], {x, y, z}],
        {AcyclicGraphTake::invalidVertexList}
      ],

      testUnevaluated[
        AcyclicGraphTake[DirectedGraph[RandomGraph[{5, 5}], "Acyclic"], {6, 1}],
        {AcyclicGraphTake::invalidVertex}
      ],

       testUnevaluated[
        AcyclicGraphTake[DirectedGraph[RandomGraph[{5, 5}], "Acyclic"], {1, 6}],
        {AcyclicGraphTake::invalidVertex}
      ]
    }
  |>
|>
      