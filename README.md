# Set Substitution System

This is an implementation of the set substitution system that can be used for fundamental physics models described in Stephen Wolfram's A New Kind of Science: https://www.wolframscience.com/nks/chap-9--fundamental-physics/.

It can also be used for manipulating triple- (or tuple-)stores for semantic web applications.

Package can be imported directly without installing as: `<< "https://raw.githubusercontent.com/maxitg/SetReplace/master/SetReplace.wl"`

Then, to list available functions, use ``?SetReplace`*``

Usage example:
```
HypergraphPlot[SetReplaceAll[
    {{0, 1}, {0, 2}, {0, 3}},
    FromAnonymousRules[{
        {0, 1}, {0, 2}, {0, 3}} ->
        {{4, 5}, {5, 4}, {4, 6}, {6, 4}, {5, 6}, {6, 5}, {4, 1}, {5, 2}, {6, 3}, {1, 6}, {3, 4}}], 4]]
```
will produce

![image](https://user-images.githubusercontent.com/1479325/51068982-e6c16a80-15da-11e9-9d92-df00c5b3cf1a.png)
