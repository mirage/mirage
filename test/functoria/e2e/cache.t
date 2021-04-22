Test that the cache is escaping entries correctly:

  $ ./test.exe configure --file app/config.ml --vote="foo;;bar;;;\n\nllll;;;sdaads;;\n\t\0"
  $ ./test.exe build --file app/config.ml
  $ cat app/test/vote
  foo;;bar;;;\n\nllll;;;sdaads;;\n\t\0
