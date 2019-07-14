(* ::Package:: *)

Paclet[
	Name -> "SetReplace",
	Version -> "0.2",
	MathematicaVersion -> "12.0+",
	Description -> "SetReplace is a Wolfram Language package that implements a substitution system such that in each step an unordered subset matching a given pattern is deleted from a multiset and replaced with different subset. If each element of the set consists of pairs of elements, this set can be thought of as a directed graph, and the system becomes a network substitution (aka graph rewrite) system.",
	Creator -> "Maksim Piskunov",
	URL -> "https://github.com/maxitg/SetReplace",
	SystemID -> {"MacOSX-x86-64", "Linux-x86-64", "Windows-x86-64"},
	Extensions -> {
		{"Application", Context -> "SetReplace`"},
		{"LibraryLink"}
	}
]
