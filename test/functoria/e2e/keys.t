Test keys.

  $ ./test.exe configure --file app/config.ml
  $ make build
  dune build --root . app/dist
  $ cat app/test/vote
  cat
  $ ./test.exe clean --file app/config.ml

Change the key at configure time:

  $ ./test.exe configure --file app/config.ml --vote=dog
  $ make build
  dune build --root . app/dist
  $ cat app/test/vote
  dog
