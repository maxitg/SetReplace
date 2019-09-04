BeginTestSection["FromAnonymousRules"]

(* Argument Checks *)

(** Argument count **)

VerificationTest[
  FromAnonymousRules[],
  FromAnonymousRules[],
  {FromAnonymousRules::argx}
]

VerificationTest[
  FromAnonymousRules[1, 2],
  FromAnonymousRules[1, 2],
  {FromAnonymousRules::argx}
]

(** Argument is a list of rules or a single rule **)

VerificationTest[
  FromAnonymousRules[1],
  FromAnonymousRules[1],
  {FromAnonymousRules::notRules}
]

(* Implementation *)

(** Simple examples **)

VerificationTest[
  FromAnonymousRules[{{} -> {}}],
  {{} :> {}}
]

VerificationTest[
  SetReplace[{{1, 2}, {2, 3}}, FromAnonymousRules[{{} -> {}}], 3],
  {{1, 2}, {2, 3}}
]

VerificationTest[
  SetReplace[{{"v1", "v2"}}, FromAnonymousRules[{{1, 2}} -> {{1}}]],
  {{"v1"}}
]

VerificationTest[
  SetReplace[
    {{"v1", "v2"}, {"v2", "v3"}},
    FromAnonymousRules[{{1, 2}, {2, 3}} -> {{1, 3}}]],
  {{"v1", "v3"}}
]

(** Multiple rules **)

VerificationTest[
  SetReplace[
    {{"v1", "v2"}, {"v2", "v3"}},
    FromAnonymousRules[{
      {{1, 2}, {2, 3}} -> {{1, 3}},
      {{1, 2}} -> {{1, 1, 2, 2}}}], 2],
  {{"v1", "v1", "v3", "v3"}}
]

(** Creating vertices **)

VerificationTest[
  SetReplace[
    SetReplace[{{"v1", "v2"}}, FromAnonymousRules[{{1, 2}} -> {{1, 2, 3}}]],
    {{"v1", "v2", z_}} :> {{"v1", "v2"}}],
  {{"v1", "v2"}}
]

(** Check new vertices are being held **)

VerificationTest[
  Module[{v1 = v2 = v3 = v4 = v5 = 1},
    SetReplace[{z + z^z, y + y^y}, FromAnonymousRules[x + x^x -> x]]
  ],
  {y + y^y, z}
]

(** Non-list rule structures **)

VerificationTest[
  SetReplace[
    {{10 -> 30} -> 20, {30, 40}},
    FromAnonymousRules[{{1 -> 3} -> 2, {3, 4}} -> {{1, 2, 3}, {3, 4, 5}}]][[1]],
  {10, 20, 30}
]

VerificationTest[
  SetReplace[{{2, 2}, 1},
    FromAnonymousRules[{
      {{Graph[{3 -> 4}], Graph[{3 -> 4}]}, Graph[{1 -> 2}]} ->
      {Graph[{3 -> 4}], Graph[{1 -> 2}], Graph[{3 -> 4}]}}]],
  {2, 1, 2}
]

EndTestSection[]
