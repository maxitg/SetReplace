<|
  "Rasterization" -> <|
    "init" -> (
      $dummyImage = RandomImage[1, ImageSize -> {5,5}];
      $dummyImagePath = FileNameJoin[{$SetReplaceBaseDirectory, "Documentation", "Images", "DummyImageForTestingPurposes.png"}];
      If[FileExistsQ[$dummyImagePath], DeleteFile[$dummyImagePath]];
    ),
    "options" -> <|
      "Parallel" -> False, (* <- because we need to write a file and then read it *)
      "RequiresFrontEnd" -> True
    |>,
    "tests" -> {

      (* test that MakeFormattedCodeBoxes works on two simple cases *)
      VerificationTest[
        MakeFormattedCodeBoxes[Evaluate @ Range[5]] === RowBox[{"{", RowBox[{"1", ",", " ", "2", ",", " ", "3", ",", " ", "4", ",", " ", "5"}], "}"}]
      ],

      VerificationTest[
        MakeFormattedCodeBoxes["hello \"world\""] === "\"hello \\\"world\\\"\""
      ],

      (* test it respects the character limit *)
      VerificationTest[
        MakeFormattedCodeBoxes[Evaluate@Range[5], 10] === RowBox[{"{",RowBox[{"\n","\t","1",",","\n","\t","2",",","\n","\t","3",",","\n","\t","4",",","\n","\t","5","\n",""}],"}"}]
      ],

      (* test it doesn't evaluate its contents *)
      VerificationTest[
        $z = 0;
        MakeFormattedCodeBoxes[$z++];
        $z == 0
      ],

      (* test it fully qualifies (most) symbols *)
      VerificationTest[
	      MakeFormattedCodeBoxes[Foo`Bar`Baz] === "Foo`Bar`Baz"
      ],

      (* test it doesn't fully qualify SetReplace` context *)
      VerificationTest[
	      MakeFormattedCodeBoxes[MakeFormattedCodeBoxes] === "MakeFormattedCodeBoxes"
      ],

      (* test the rasterization functions actually produce an Image *)
      VerificationTest[ImageQ[RasterizeExpression[Graphics[{}]]]],
      VerificationTest[ImageQ[RasterizeExpressionAsInput[Graphics[{}]]]],
      VerificationTest[ImageQ[RasterizeExpressionAsOutput[Graphics[{}]]]],
      VerificationTest[ImageQ[RasterizeExpressionAsInputOutputPair[Graphics[{}]]]],

      (* test that RasterizeAsInput doesn't evaluate its argument *)
      VerificationTest[
        $z = 0;
        RasterizeExpressionAsInput[$z++];
        $z == 0
      ],

      (* test image size *)
      VerificationTest[
        ImageDimensions[RasterizeExpressionAsOutput[Graphics[{}, ImageSize -> {200, 200}]]] == {495, 400}
      ],

      (* test for grayscale *)
      VerificationTest[
        Equal @@ Transpose @ Flatten[ImageData[RasterizeExpressionAsOutput[""]], 1]
      ],

     (* test that ExportImageForEmbedding produces a markdown string result *)
      VerificationTest[
        StringQ @ ExportImageForEmbedding["DummyImageForTestingPurposes", $dummyImage]
      ],

      (* test that the previous test produced a right file *)
      VerificationTest[
        FileExistsQ[$dummyImagePath]
      ],

      (* test that the image was correct *)
      VerificationTest[
        ImageDistance[Import[$dummyImagePath], $dummyImage] < 0.01
      ]
    },
    "cleanup" -> (
      If[FileExistsQ[$dummyImagePath], DeleteFile[$dummyImagePath]]
    )
  |>
|>
