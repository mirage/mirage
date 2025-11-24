Check the locations of error messages when something is wrong in the body
of a device's connect function:

  $ ./test.exe configure -f errors/in_device.ml
  test.exe: [WARNING] Skipping version check, since our_version ("1.0~test") fails to parse: only digits and . allowed in version
  $ dune build 2>&1 | head -n1 | cut -d, -f-2
  File "errors/in_device.ml", line 6
  $ ./test.exe clean -f errors/in_device.ml

Check what happens when the number of the arguments passed to the functor is
not the right ones. First, too many parameters:

  $ ./test.exe configure -f errors/in_functor_too_many.ml
  test.exe: [WARNING] Skipping version check, since our_version ("1.0~test") fails to parse: only digits and . allowed in version
  $ dune build 2>&1 | head -n1 | cut -d',' -f'-2'
  File "errors/test/main.ml", line 10
  $ ./test.exe clean -f errors/in_functor_too_many.ml

Then, not enough:

  $ ./test.exe configure -f errors/in_functor_not_enough.ml
  test.exe: [WARNING] Skipping version check, since our_version ("1.0~test") fails to parse: only digits and . allowed in version
  $ dune build 2>&1 | grep '^Error:'
  Error: The module Unikernel_make__4 is a functor, it cannot have any components
  $ ./test.exe clean -f errors/in_functor_not_enough.ml

Also check that we have proper errors when the config file is missing:

Configure failure
  $ ./test.exe configure --vote=dog
  configuration file config.ml missing
  [1]

Query failure
  $ ./test.exe query --vote=dog
  configuration file config.ml missing
  [1]

Describe failure
  $ ./test.exe describe --vote=dog
  configuration file config.ml missing
  [1]

Clean does not fail
  $ ./test.exe clean --vote=dog

Help does not fail
  $ ./test.exe help --man-format=plain > /dev/null
