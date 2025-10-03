Run an application

  $ ./test.exe configure --file app/config.ml
  test.exe: [WARNING] Skipping version check, since our_version ("1.0~test") fails to parse: only digits and . allowed in version
  $ dune exec -- ./app/main.exe --arg=yo --required=bar
  Success: hello=Hello World! arg=yo
  $ dune exec -- ./app/main.exe --help=plain
  NAME
         noop
  
  SYNOPSIS
         noop [OPTION]…
  
  APPLICATION OPTIONS
         --arg=VAL (absent=-)
             A runtime argument.
  
  OPTIONS
         --flag
             A flag.
  
         --hello=VAL (absent=Hello World!)
             How to say hello.
  
         --opt=VAL (absent=default)
             An optional key.
  
         --opt-all=VAL
             All the optional keys.
  
         --required=VAL (required)
             A required key.
  
  COMMON OPTIONS
         --help[=FMT] (default=auto)
             Show this help in format FMT. The value FMT must be one of auto,
             pager, groff or plain. With auto, the format is pager or plain
             whenever the TERM env var is dumb or undefined.
  
  EXIT STATUS
         noop exits with:
  
         0   on success.
  
         1   on Solo5 internal error.
  
         63  on showing this help.
  
         64  on any argument parsing error.
  
         125 on unexpected internal errors (bugs) while processing the boot
             parameters.
  
         255 on OCaml uncaught exception.
  
  [63]
