Test that the cache is escaping entries correctly:

  $ ./test.exe configure --file app/config.ml --vote="foo;;bar;;;\n\nllll;;;sdaads;;\n\t\0"
  test.exe: [WARNING] Skipping version check, since our_version ("1.0~test") fails to parse: only digits and . allowed in version
  $ make build
  dune build --profile release --root . app/dist
  Your unikernel binary is now ready in app/dist/noop
  Execute the binary using solo5-hvt, solo5-spt, xl, ...
  $ cat app/test/vote
  foo;;bar;;;\n\nllll;;;sdaads;;\n\t\0
