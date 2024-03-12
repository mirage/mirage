Help query --man-format=plain
  $ ./test.exe help query --man-format=plain > d1

Help query --help=plain
  $ ./test.exe query --help=plain > d2

No difference
  $ diff d1 d2
