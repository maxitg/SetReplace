Needs["MUnit`"]

testFiles = FileNames["*TestSuite.mt", { DirectoryName[$TestFileName] }, 2];
TestSuite[testFiles];