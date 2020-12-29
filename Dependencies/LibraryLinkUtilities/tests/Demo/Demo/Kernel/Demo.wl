BeginPackage["Demo`"];

CaesarCipherEncode::usage = "CaesarCipherEncode[message_String, shift_Integer] encodes given message by shifting every character by shift positions in the \
English alphabet.";

CaesarCipherDecode::usage = "CaesarCipherDecode[cipherText_String, shift_Integer] restores the original message encoded with Caesar's cipher given \
the encoded text and the shift.";

Begin["`Private`"];

$BaseDemoDirectory = FileNameDrop[$InputFileName, -2];
Get[FileNameJoin[{$BaseDemoDirectory, "LibraryResources", "LibraryLinkUtilities.wl"}]];

`LLU`InitializePacletLibrary["Demo"];

`LLU`LazyPacletFunctionSet @@@ {
	{CaesarCipherEncode, "CaesarCipherEncode", {String, Integer}, String},
	{CaesarCipherDecode, "CaesarCipherDecode", {String, Integer}, String}
};

End[];

EndPackage[];