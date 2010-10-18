lib/std/ contains the core modules used by all Mirage backends.
It implements:

* a close approximation of the standard OCaml compiler distribution,
  but with a few OS-specific abstractions removed such as channels.

* the core of the LWT cooperative threading library.

