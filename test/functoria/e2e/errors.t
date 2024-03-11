Check the locations of error messages when something is wrong in the body
of a device's connect function:

  $ ./test.exe configure -f errors/in_device.ml
  $ dune build
  File "errors/config.ml", line 6, characters 2-26:
  Error: Unbound value Unikernel_make__4.start'
  Hint: Did you mean start?
  [1]
  $ ./test.exe clean -f errors/in_device.ml

Check what happens when the number of the arguments passed to the functor is
not the right ones. First, too many parameters:

  $ ./test.exe configure -f errors/in_functor_too_many.ml
  $ dune build 2>&1 | head -n1 | cut -d',' -f'-2'
  File "errors/test/main.ml", line 7
  $ ./test.exe clean -f errors/in_functor_too_many.ml

Then, not enough:

  $ ./test.exe configure -f errors/in_functor_not_enough.ml
  $ dune build
  File "errors/test/main.ml", line 33, characters 2-25:
  Error: The module Unikernel_make__4 is a functor, it cannot have any components
  [1]
  $ ./test.exe clean -f errors/in_functor_not_enough.ml
