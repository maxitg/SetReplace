Needs["Demo`"];
Needs["MUnit`"];

$tests = Hold @ {
	Test[
		Demo`CaesarCipherDecode::usage
		,
		"CaesarCipherDecode[cipherText_String, shift_Integer] restores the original message encoded with Caesar's cipher given the encoded text and the shift."
	],

	Test[
		Demo`CaesarCipherDecode[Demo`CaesarCipherEncode["HelloWorld", 3], 3]
		,
		"HelloWorld"
	],

	Test[
		Demo`CaesarCipherDecode[Demo`CaesarCipherEncode["HelloWorld", 25], 25]
		,
		"HelloWorld"
	],

	VerificationTest[
		f = Catch[Demo`CaesarCipherEncode["HelloWorld", -1], "LLUExceptionTag"];
		FailureQ[f] && First[f] === "NegativeShiftError"
	],

	VerificationTest[
		f = Catch[Demo`CaesarCipherEncode["HelloWorld\[HappySmiley]", 2], "LLUExceptionTag"];
		FailureQ[f] && First[f] === "InvalidCharacterError"
	]
};

TestRun[
	Evaluate @ $tests,
	Loggers :> {VerbosePrintLogger[]},
	TestRunTitle -> "Basic test suite of the Demo paclet",
	MemoryConstraint -> Quantity[100, "Megabytes"],
	TimeConstraint -> Quantity[60, "Seconds"]
]
