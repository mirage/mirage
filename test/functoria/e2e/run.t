Run an application

  $ ./test.exe configure --file app/config.ml
  $ dune exec -- ./app/main.exe --arg=yo
  Success: hello=Hello World! arg=yo
  $ dune exec -- ./app/main.exe --help=plain
  NAME
         noop
  
  SYNOPSIS
         noop [--hello=VAL] [OPTION]…
  
  APPLICATION OPTIONS
         --arg=VAL (absent=-)
             A runtime argument.
  
  OPTIONS
         --hello=VAL (absent=Hello World!)
             How to say hello.
  
  COMMON OPTIONS
         --help[=FMT] (default=auto)
             Show this help in format FMT. The value FMT must be one of auto,
             pager, groff or plain. With auto, the format is pager or plain
             whenever the TERM env var is dumb or undefined.
  
  EXIT STATUS
         noop exits with:
  
         0   on success.
  
         123 on indiscriminate errors reported on standard error.
  
         124 on command line parsing errors.
  
         125 on unexpected internal errors (bugs).
  
  [63]
