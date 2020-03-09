<|
  "HypergraphAutomorphismGroup" -> <|
    "init" -> (
      Attributes[Global`testUnevaluated] = Attributes[Global`testSymbolLeak] = {HoldAll};
      Global`testUnevaluated[args___] := SetReplace`PackageScope`testUnevaluated[VerificationTest, args];
      Global`testSymbolLeak[args___] := SetReplace`PackageScope`testSymbolLeak[VerificationTest, args];
    ),
    "tests" -> {
      testSymbolLeak[
        HypergraphAutomorphismGroup[{{1, 2}, {2, 3}, {3, 1}}]
      ],
      
      testUnevaluated[
        HypergraphAutomorphismGroup[],
        {HypergraphAutomorphismGroup::argx}
      ],

      testUnevaluated[
        HypergraphAutomorphismGroup[1, 2],
        {HypergraphAutomorphismGroup::argx}
      ],

      testUnevaluated[
        HypergraphAutomorphismGroup[#],
        {HypergraphAutomorphismGroup::invalidHypergraph}
      ] & /@ {1, {1}, {1, 2}, {{1, 2}, 3}, {{{1, 2}, {3, 4}}, {5, 6}}},

      VerificationTest[
        GroupOrder[HypergraphAutomorphismGroup[#]],
        1
      ] & /@ {{}, {{1}}, {{1, 2}}, {{1, 2}, {2, 3}}, {{1, 2, 3}, {1, 2, 3}}},

      VerificationTest[
        Sort[GroupElements[HypergraphAutomorphismGroup[#]]],
        {Cycles[{}], Cycles[{{1, 2}}]}
      ] & /@ {{{1, 2}, {2, 1}}, {{1}, {2}}, {{1}, {2}, {1, 2}, {2, 1}}, {{1, 1}, {2, 2}}},

      VerificationTest[
        Sort[GroupElements[HypergraphAutomorphismGroup[{{1, 2}, {2, 3}, {3, 1}}]]],
        {Cycles[{}], Cycles[{{1, 2, 3}}], Cycles[{{1, 3, 2}}]}
      ],

      VerificationTest[
        Sort[GroupElements[HypergraphAutomorphismGroup[{{1, 2, 3}, {3, 4, 1}}]]],
        {Cycles[{}], Cycles[{{1, 3}, {2, 4}}]}
      ],

      VerificationTest[
        Sort[GroupElements[HypergraphAutomorphismGroup[#]]],
        {Cycles[{}], Cycles[{{1, 3}}]}
      ] & /@ {{{1, 2, 3}, {3, 2, 1}}, {{1, 2, 4}, {3, 2, 4}}},

      VerificationTest[
        Sort[GroupElements[HypergraphAutomorphismGroup[{{7, 2, 3, 1}, {8, 5, 6, 4}, {2, 5}, {5, 2}}]]],
        {Cycles[{}], Cycles[{{1, 4}, {2, 5}, {3, 6}, {7, 8}}]}
      ],

      VerificationTest[
        Sort[GroupElements[HypergraphAutomorphismGroup[
          {{1, 6, 5}, {2, 8, 7}, {3, 10, 9}, {4, 12, 11}, {6, 10}, {5, 7}, {8, 12}, {7, 5}, {10, 6}, {9, 11}, {12, 8},
          {11, 9}}]]],
        {Cycles[{}], 
          Cycles[{{1, 2}, {3, 4}, {5, 7}, {6, 8}, {9, 11}, {10, 12}}], 
          Cycles[{{1, 3}, {2, 4}, {5, 9}, {6, 10}, {7, 11}, {8, 12}}], 
          Cycles[{{1, 4}, {2, 3}, {5, 11}, {6, 12}, {7, 9}, {8, 10}}]}
      ],

      VerificationTest[
        Sort[GroupElements[HypergraphAutomorphismGroup[{{1, 2, 3, 4, 5}, {5, 6, 7, 8, 1}}]]],
        {Cycles[{}], Cycles[{{1, 5}, {2, 6}, {3, 7}, {4, 8}}]}
      ],

      VerificationTest[
        Sort[GroupElements[HypergraphAutomorphismGroup[
          {{1, 2}, {1, 3}, {1, 4}, {2, 1}, {2, 3}, {2, 4}, {3, 1}, {3, 2}, {3, 4}, {4, 1}, {4, 2}, {4, 3}}]]],
        {Cycles[{}], Cycles[{{1, 2}}], Cycles[{{1, 3}}], Cycles[{{1, 4}}], 
          Cycles[{{2, 3}}], Cycles[{{2, 4}}], Cycles[{{3, 4}}], 
          Cycles[{{1, 2, 3}}], Cycles[{{1, 2, 4}}], Cycles[{{1, 3, 2}}], 
          Cycles[{{1, 3, 4}}], Cycles[{{1, 4, 2}}], Cycles[{{1, 4, 3}}], 
          Cycles[{{2, 3, 4}}], Cycles[{{2, 4, 3}}], Cycles[{{1, 2, 3, 4}}], 
          Cycles[{{1, 2, 4, 3}}], Cycles[{{1, 3, 2, 4}}], 
          Cycles[{{1, 3, 4, 2}}], Cycles[{{1, 4, 2, 3}}], 
          Cycles[{{1, 4, 3, 2}}], Cycles[{{1, 2}, {3, 4}}], 
          Cycles[{{1, 3}, {2, 4}}], Cycles[{{1, 4}, {2, 3}}]}
      ],

      VerificationTest[
        GroupOrder[HypergraphAutomorphismGroup[{{1, 2, 3}, {3, 4, 5}, {5, 6, 1}, {1, 7, 3}, {3, 8, 5}, {5, 9, 1}}]],
        24
      ],

      SeedRandom[117];
      VerificationTest[
        Sort[GroupElements[GraphAutomorphismGroup[Graph[Union[Catenate[List @@@ EdgeList[#]]], EdgeList[#]]]]],
        Sort[GroupElements[HypergraphAutomorphismGroup[Join[List @@@ EdgeList[#]]]]]
      ] & /@ RandomGraph[{10, 10}, 100, DirectedEdges -> True]
    }
  |>
|>
