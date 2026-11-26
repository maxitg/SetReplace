from pathlib import Path

# Temporary probe: reuse the existing timed assertion without running unrelated tests.
source = Path("Tests/HypergraphPlot.wlt").read_text()
start = source.index("      Global`timedLargeGraph[events_]")
end = source.index("      $edgeTypes", start)
helper = source[start:end]
assert helper.count("Global`timedLargeGraph[events_]") == 1

Path("Tests/HypergraphPlotLargeOnly.wlt").write_text('''<|
  "HypergraphPlotLargeOnly" -> <|
    "init" -> (
      Global`graphicsQ[args___] := SetReplace`PackageScope`graphicsQ[args];
''' + helper + '''    ),
    "options" -> {"Parallel" -> False, "RequiresFrontEnd" -> True},
    "tests" -> {VerificationTest[timedLargeGraph[5000]]}
  |>
|>
''')
