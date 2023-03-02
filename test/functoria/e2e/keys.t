Test keys.

  $ ./test.exe configure --file app/config.ml
  $ ./test.exe build --file app/config.ml
  config.exe: [WARNING] Deprecated, use 'make build' instead
  $ cat app/test/vote
  cat
  $ ./test.exe clean --file app/config.ml

Change the key at configure time:

  $ ./test.exe configure --file app/config.ml --vote=dog
  $ ./test.exe build --file app/config.ml
  config.exe: [WARNING] Deprecated, use 'make build' instead
  $ cat app/test/vote
  dog
