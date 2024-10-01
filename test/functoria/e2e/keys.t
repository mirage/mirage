Test keys.

  $ ./test.exe configure --file app/config.ml
  test.exe: [WARNING] Skipping version check, since our_version ("1.0~test") fails to parse: only digits and . allowed in version
  $ make build
  dune build --profile release --root . app/dist
  $ cat app/test/vote
  cat
  $ ./test.exe clean --file app/config.ml

Change the key at configure time:

  $ ./test.exe configure --file app/config.ml --vote=dog
  test.exe: [WARNING] Skipping version check, since our_version ("1.0~test") fails to parse: only digits and . allowed in version
  $ make build
  dune build --profile release --root . app/dist
  $ cat app/test/vote
  dog
