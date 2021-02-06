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
  namesToIndices = AssociationThread[argumentNames -> Range[Length[argumentNames]]];
  AssociateTo[$messageSlotNames, Hold[messageName] -> argumentNames];
  messageName = StringJoin[Replace[templateObject[[1]],
                                   TemplateSlot[name_] :> "`" <> ToString[namesToIndices[name]] <> "`",
                                   1]];
];

message::messageNotFound = "Message `` could not be found. Messages need to be declared first with declareMessage.";
message::missingArgs = "Arguments `2` missing for message `1`.";

Attributes[message] = {HoldFirst};
message[messageName_, args_ ? AssociationQ] := ModuleScope[
  (* Look for the specific message first, e.g., symb::msg. If not found, look for General::msg.
     General:: messages should be possible to generate for any symbol. *)
  argumentsOrder =
    Lookup[$messageSlotNames, Hold[messageName], $messageSlotNames[ReplacePart[Hold[messageName], {1, 1} -> General]]];
  If[MissingQ[argumentsOrder],
    Message[message::messageNotFound, HoldForm[messageName]]
  ,
    missingArgs = Complement[argumentsOrder, Keys[args]];
    If[missingArgs =!= {},
      Message[message::missingArgs, HoldForm[messageName], missingArgs];
    ,
      Message[messageName, ##] & @@ Replace[argumentsOrder, args, 1];
    ];
  ];
];

(* extraArgs is useful for passing public symbol-specific information such as the public function call. *)

message[head_, failure_ ? FailureQ, extraArgs : _ ? AssociationQ : <||>] := With[{
    messageName = failure[[1]],
    messageArguments = Join[failure[[2]], extraArgs]},
  message[MessageName[head, messageName], messageArguments];
  Failure[messageName, messageArguments]
];

message[head_][failure_ ? FailureQ, ___] := message[head, failure];

(* Throws identical value and tag so that the value can be caught with the second argument of Catch *)

throw[exception_] := Throw[exception, exception];
