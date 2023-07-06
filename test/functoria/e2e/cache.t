Test that the cache is escaping entries correctly:

  $ ./test.exe configure --file app/config.ml --vote="foo;;bar;;;\n\nllll;;;sdaads;;\n\t\0"
  $ make build
  dune build --root . app/dist
  $ cat app/test/vote
  foo;;bar;;;\n\nllll;;;sdaads;;\n\t\0
