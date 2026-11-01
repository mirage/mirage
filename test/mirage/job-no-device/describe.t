  $ export MIRAGE_DEFAULT_TARGET=unix

Describe must not print the 'adding unit argument' hint (mirage/mirage#1608):
  $ ./config.exe describe
  Name       noop
  Keys       target=unix (default)
