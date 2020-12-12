Package["SetReplaceDevUtils`"]

PackageImport["GeneralUtilities`"]

PackageImport["PacletManager`"] (* for PacletFind, PacletInstall in versions prior to 12.1 *)

PackageExport["$GitLinkAvailableQ"]

(* unfortunately, owing to a bug in GitLink, GitLink *needs* to be on the $ContextPath or GitRepo objects
end up in the wrong context, since they are generated in a loopback link unqualified *)
$GitLinkAvailableQ := !FailureQ[Quiet @ Check[Needs["GitLink`"], $Failed]];

PackageExport["GitSHAWithDirtyStar"]

Clear[GitSHAWithDirtyStar];

SetUsage @ "
GitSHAWithDirtyStar['path$'] returns the SHA hash of the commit that is currently checked on \
for the Git repository at 'path$'. Unlike the GitSHA function, this will include a '*' character \
if the current working tree is dirty.
"

GitSHAWithDirtyStar[repoDir_] /; TrueQ[$GitLinkAvailableQ] := ModuleScope[
  repo = GitLink`GitOpen[repoDir];
  sha = GitLink`GitSHA[repo, repo["HEAD"]];
  cleanQ = AllTrue[# === {} &] @ GitLink`GitStatus[repo];
  If[cleanQ, sha, sha <> "*"]
]

GitSHAWithDirtyStar[_] /; FalseQ[$GitLinkAvailableQ] := Missing["NotAvailable"];

PackageExport["InstallGitLink"]

SetUsage @ "
InstallGitLink[] will attempt to install GitLink on the current system (if necessary).
"

InstallGitLink[] := If[PacletFind["GitLink", "Internal" -> All] === {},
  PacletInstall["https://www.wolframcloud.com/obj/maxp1/GitLink-2019.11.26.01.paclet"];
];

PackageExport["CalculateMinorVersionNumber"]

SetUsage @ "
CalculateMinorVersionNumber[repositoryDirectory$, masterBranch$] will calculate a minor version \
derived from the number of commits between the last checkpoint and the 'master' branch, \
which can be overriden with the 'MasterBranch' option. The checkpoint is defined in scripts/version.wl.
"

CalculateMinorVersionNumber[repoDir_, masterBranch_] := ModuleScope[
  versionInformation = Import[FileNameJoin[{repoDir, "scripts", "version.wl"}]];
  gitRepo = GitLink`GitOpen[repoDir];
  If[$internalBuildQ, GitLink`GitFetch[gitRepo, "origin"]];
  minorVersionNumber = Max[0, Length[GitLink`GitRange[
    gitRepo,
    Except[versionInformation["Checkpoint"]],
    GitLink`GitMergeBase[gitRepo, "HEAD", masterBranch]]] - 1];
  minorVersionNumber
];
