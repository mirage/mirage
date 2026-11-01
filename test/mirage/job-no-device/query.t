  $ export MIRAGE_DEFAULT_TARGET=unix

Query must not print the 'adding unit argument' hint (mirage/mirage#1608):
  $ ./config.exe query name
  noop
