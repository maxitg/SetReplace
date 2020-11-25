Package["SetReplaceDevUtils`"]

PackageImport["GeneralUtilities`"]

PackageExport["$GitLinkAvailableQ"]

(* unfortunately, owing to a bug in GitLink, GitLink *needs* to be on the $ContextPath or GitRepo objects
end up in the wrong context, since they are generated in a loopback link unqualified *)
$GitLinkAvailableQ := $GitLinkAvailableQ = !FailureQ[Quiet @ Check[Needs["GitLink`"], $Failed]];

PackageExport["GitSHAWithDirtyStar"]

Clear[GitSHAWithDirtyStar];

SetUsage @ "
GitSHAWithDirtyStar['path$'] returns the SHA hash of the commit that is currently checked on \
for the Git repository at 'path$'. Unlike the GitSHA function, this will include a '*' character \
if the current working tree is dirty.
"

GitSHAWithDirtyStar[rootDir_] /; TrueQ[$GitLinkAvailableQ] := ModuleScope[
  repo = GitLink`GitOpen[rootDir];
  sha = GitLink`GitSHA[repo, repo["HEAD"]];
  cleanQ = AllTrue[# === {} &] @ GitLink`GitStatus[repo];
  If[cleanQ, sha, sha <> "*"]
]

GitSHAWithDirtyStar[rootDir_] /; FalseQ[$GitLinkAvailableQ] := Missing["NotAvailable"];

PackageExport["InstallGitLink"]

SetUsage @ "
InstallGitLink[] will attempt to install GitLink on the current system (if necessary).
"

InstallGitLink[] := If[PacletFind["GitLink", "Internal" -> All] === {},
  If[NameQ["AntProperty"] && Symbol["AntProperty"]["build_target"] === "internal",
    PacletInstall["GitLink", "Site" -> "http://paclet-int.wolfram.com:8080/PacletServerInternal"],
    PacletInstall["https://www.wolframcloud.com/obj/maxp1/GitLink-2019.11.26.01.paclet"]
  ];
];

PackageExport["CalculateMinorVersionNumber"]

SetUsage @ "
CalculateMinorVersionNumber[rootDirectory$, masterBranch$] will calculate a minor version \
derived from the number of commits between the last checkpoint and the 'master' branch, \
which can be overriden with the 'MasterBranch' option. The checkpoint is defined in scripts/version.wl.
"

CalculateMinorVersionNumber[rootDirectory_, masterBranch_] := ModuleScope[
  versionInformation = Import[FileNameJoin[{rootDirectory, "scripts", "version.wl"}]];
  gitRepo = GitLink`GitOpen[rootDirectory];
  If[$internalBuildQ, GitLink`GitFetch[gitRepo, "origin"]];
  minorVersionNumber = Max[0, Length[GitLink`GitRange[
    gitRepo,
    Except[versionInformation["Checkpoint"]],
    GitLink`GitMergeBase[gitRepo, "HEAD", masterBranch]]] - 1];
  minorVersionNumber
];
