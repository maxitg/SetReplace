Package["SetReplaceDevUtils`"]

PackageImport["GeneralUtilities`"]


PackageExport["FileTreeHashes"]

SetUsage @ "
FileTreeHashes['path$', pattern$, depth$, excludeList$] returns a list of pairs consisting of {'filename', hash}.
* The files found are those matching pattern$ that are within 'path$'.
* The file pattern pattern$ is as used by FileNames, and can be a list.
* depth$ instructs FileTreeHash how many directories to preserve from the returned absolute paths to ensure they
are independent of the overall location of a file tree on disk.
* excludeList$ can contain a list of file names to exclude.
"

FileTreeHashes[path_, pattern_, depth_:1, exclude_:{}] := ModuleScope[
  path = AbsoluteFileName[path];
  If[FailureQ[path] || !DirectoryQ[path], Return[$Failed]];
  fileNames = FileNames[pattern, path, IgnoreCase -> True];
  If[exclude =!= {},
    fileNames = Discard[fileNames, StringEndsQ[#, exclude, IgnoreCase -> True]&]];
  hashes = FileHash[fileNames, "SHA"];
  (* strip off *depth* subdirs to get the canonical path *)
  fileNames = StringDrop[fileNames, StringLength @ FileNameDrop[path, -depth]];
  Transpose[{fileNames, hashes}]
];
