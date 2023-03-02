Test that the cache is escaping entries correctly:

  $ ./test.exe configure --file app/config.ml --vote="foo;;bar;;;\n\nllll;;;sdaads;;\n\t\0"
  $ ./test.exe build --file app/config.ml
  config.exe: [WARNING] Deprecated, use 'make build' instead
  $ cat app/test/vote
  foo;;bar;;;\n\nllll;;;sdaads;;\n\t\0
