Package["SetReplace`"]

PackageImport["GeneralUtilities`"]

PackageScope["declareMessage"]
PackageScope["message"]
PackageScope["throw"]

$messageSlotNames = <||>;

Attributes[declareMessage] = {HoldFirst};
declareMessage[messageName_, template_] := Module[{templateObject, argumentNames, namesToIndices},
  templateObject = StringTemplate[template];
  argumentNames = First /@ Cases[templateObject[[1]], _TemplateSlot];
  namesToIndices = Association[Thread[argumentNames -> Range[Length[argumentNames]]]];
  AssociateTo[$messageSlotNames, Hold[messageName] -> argumentNames];
  messageName = StringJoin[Replace[templateObject[[1]],
                                   TemplateSlot[name_] :> "`" <> ToString[namesToIndices[name]] <> "`",
                                   1]];
];

message::messageNotFound = "Message `` could not be found. Messages need to be declared first with declareMessage.";
message::extraArgs = "Arguments `2` not expected for message `1`.";
message::missingArgs = "Arguments `2` missing for message `1`.";

Attributes[message] = {HoldFirst};
message[messageName_, args_] := ModuleScope[
  argumentsOrder =
    Lookup[$messageSlotNames, Hold[messageName], $messageSlotNames[ReplacePart[Hold[messageName], {1, 1} -> General]]];
  If[MissingQ[argumentsOrder],
    Message[message::messageNotFound, HoldForm[messageName]]
  ,
    extraArgs = Complement[Keys[args], argumentsOrder];
    missingArgs = Complement[argumentsOrder, Keys[args]];
    If[#1 =!= {},
      Message[MessageName[message, #2], HoldForm[messageName], #1]
    ] & @@@ {{extraArgs, "extraArgs"}, {missingArgs, "missingArgs"}};
    If[extraArgs === {} && missingArgs === {},
      Message[messageName, ##] & @@ Replace[argumentsOrder, args, 1];
    ];
  ];
];

message[head_, failure_ ? FailureQ] := With[{messageName = failure[[1]], messageArguments = failure[[2]]},
  message[MessageName[head, messageName], messageArguments];
];

message[head_][failure_ ? FailureQ, ___] := message[head, failure];

(* Throws identical value and tag so that the value can be caught with the second argument of Catch *)

throw[exception_] := Throw[exception, exception];
