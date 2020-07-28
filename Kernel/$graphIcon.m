(* ::Package:: *)

(* ::Title:: *)
(*$graphIcon*)


(* ::Text:: *)
(*This is an icon that is used for objects such as Graph if one sets GraphLayout -> None. Extracted from boxes of that object.*)


Package["SetReplace`"]


PackageScope["$graphIcon"]


(* ::Section:: *)
(*Implementation*)


$graphIcon = Graphics[
  GraphicsComplexBox[
    {{0.1`, -3.31951456589972`},
      {-0.14816751450286603`, -2.625037331552915`},
      {0.6310524421714278`, -1.3`},
      {0.9405108616213151`, -2.8841601437046225`},
      {0.4967448863824806`, -2.092358403567382`},
      {-0.846735323402297`, -1.466588600696043`},
      {0.8846460183439665`, -0.5107506168284197`},
      {1.8939086566530445`, -2.50980168725566`},
      {1.756629266633539`, -3.4622764737192444`},
      {2.119361963550152`, -2.99`},
      {-0.5709741939515942`, -4.632295267644082`},
      {0.20977925607671288`, -4.647162049737781`},
      {-1.0861820131541373`, -4.047493574735101`},
      {-1.2223073729506904`, -2.2040562174063485`}},
    {Hue[0.6`,0.7`,0.5`],
      Opacity[0.7`],
      Arrowheads[0.`],
      ArrowBox[
        {{1, 2},
          {1, 4},
          {1, 11},
          {1, 12},
          {1, 13},
          {2, 3},
          {2, 4},
          {2, 5},
          {2, 6},
          {2, 14},
          {3, 4},
          {3, 7},
          {4, 5},
          {4, 8},
          {4, 9},
          {8, 10},
          {9, 10}},
        0.0378698213750627`],
      Hue[0.6`, 0.2`, 0.8`],
      EdgeForm[{GrayLevel[0], Opacity[0.7`]}],
      DiskBox[1, 0.05`],
      DiskBox[2, 0.05`],
      DiskBox[3, 0.05`],
      DiskBox[4, 0.05`],
      DiskBox[5, 0.05`],
      DiskBox[6, 0.05`],
      DiskBox[7, 0.05`],
      DiskBox[8, 0.05`],
      DiskBox[9, 0.05`],
      DiskBox[10, 0.05`],
      DiskBox[11, 0.05`],
      DiskBox[12, 0.05`],
      DiskBox[13, 0.05`],
      DiskBox[14, 0.05`]}],
  AspectRatio -> 1,
  Background -> GrayLevel[0.93`],
  ImagePadding -> 0,
  FrameStyle -> Directive[
    Opacity[0.5`],
    Thickness[Tiny],
    RGBColor[0.368417`, 0.506779`, 0.709798`]],
  Frame -> True,
  FrameTicks -> None,
  ImageSize -> Dynamic[{
    Automatic,
    3.5` CurrentValue["FontCapHeight"] / AbsoluteCurrentValue[Magnification]}],
  PlotRange -> {{-1.1`, 2.4`}, {-4.4`, -0.7`}}];
