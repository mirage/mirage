  $ export MIRAGE_DEFAULT_TARGET=unix

Configure prints the 'adding unit argument' hint:
  $ ./config.exe configure
  adding unit argument to 'start ()' (to delay execution)
  Successfully configured the unikernel. Now run 'make' (or more fine-grained steps: 'make all', 'make depends', or 'make lock').

Clean must not print it (mirage/mirage#1608):
  $ ./config.exe clean
