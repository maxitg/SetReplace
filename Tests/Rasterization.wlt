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

      (* test it actually produces an image *)
      VerificationTest[ImageQ[RasterizeAsInput[Graphics[{}]]]],
      VerificationTest[ImageQ[RasterizeAsOutput[Graphics[{}]]]],
      VerificationTest[ImageQ[RasterizeAsInputOutputPair[Graphics[{}]]]],

      (* test that RasterizeAsInput doesn't evaluate its argument *)
      VerificationTest[
        $z = 0;
        RasterizeAsInput[$z++];
        $z == 0
      ],

      (* test image size *)
      VerificationTest[
        ImageDimensions[RasterizeAsOutput[Graphics[{}, ImageSize -> {200, 200}]]] == {495, 400}
      ],

      (* test for grayscale *)
      VerificationTest[
        Equal @@ Transpose @ Flatten[ImageData[RasterizeAsOutput[""]], 1]
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
