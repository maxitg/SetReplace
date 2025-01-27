###### [Symbols and Functions](/README.md#symbols-and-functions) > Utility Functions >

# Build Data

There are two constants containing information about the build. **`$SetReplaceGitSHA`** is a git SHA of the
currently-used version of *SetReplace*:

```wl
In[] := $SetReplaceGitSHA
Out[] = "320b91b5ca1d91b9b7890aa181ad457de3e38939"
```

If the build directory were not clean, it would have "\*" at the end.

**`$SetReplaceBuildTime`** gives a date object of when the paclet was created:

```wl
In[] := $SetReplaceBuildTime
```

<img src="/Documentation/Images/BuildTime.png"
     width="277"
     alt="Out[] = ... [Sun 12 Apr 2020 16:06:38 UTC] ...">

These constants are particularly useful for reporting issues with the code.
