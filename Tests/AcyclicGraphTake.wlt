<|
  "AcyclicGraphTake" -> <|
    "init" -> (
      Attributes[Global`testUnevaluated] = {HoldAll};
      Global`testUnevaluated[args___] := SetReplace`PackageScope`testUnevaluated[VerificationTest, args];
    ),
    "tests" -> {
      
      VerificationTest[
          AcyclicGraphTake[CycleGraph[10,]]
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
      