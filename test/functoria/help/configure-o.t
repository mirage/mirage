Help configure -o --man-format=plain
  $ ./config.exe help configure -o foo --man-format=plain | tee d1
  NAME
         test-configure - Configure a test application.
  
  SYNOPSIS
         test configure [OPTION]… 
  
  DESCRIPTION
         The configure command initializes a fresh test application.
  
  CONFIGURE OPTIONS
         --context-file=FILE (absent=test.context)
             The context file to use.
  
         --depext
             Enable call to `opam depext' in the project Makefile.
  
         --dry-run
             Display I/O actions instead of executing them.
  
         --extra-repos=NAME1:URL1,NAME2:URL2,...
         (absent=opam-overlays:https://github.com/dune-universe/opam-overlays.git,mirage-overlays:https://github.com/dune-universe/mirage-opam-overlays.git
         or MIRAGE_EXTRA_REPOS env)
             Additional opam-repositories to use when using `opam monorepo
             lock' to gather local sources. Default:
             https://github.com/dune-universe/opam-overlays.git &
             https://github.com/dune-universe/mirage-opam-overlays.git.
  
         -f FILE, --file=FILE, --config-file=FILE (absent=config.ml)
             The configuration file to use.
  
         --no-depext
             Disable call to `opam depext' in the project Makefile.
  
         --no-extra-repo
             Disable the use of any overlay repository.
  
         -o FILE, --output=FILE
             Name of the output file.
  
  APPLICATION OPTIONS
         --hello=VAL (absent=Hello World!)
             How to say hello. 
  
         --vote=VOTE (absent=cat)
             Vote. 
  
         --warn-error=BOOL (absent=false)
             Enable -warn-error when compiling OCaml sources. 
  
  COMMON OPTIONS
         --color=WHEN (absent=auto)
             Colorize the output. WHEN must be one of auto, always or never.
  
         --help[=FMT] (default=auto)
             Show this help in format FMT. The value FMT must be one of auto,
             pager, groff or plain. With auto, the format is pager or plain
             whenever the TERM env var is dumb or undefined.
  
         -q, --quiet
             Be quiet. Takes over -v and --verbosity.
  
         -v, --verbose
             Increase verbosity. Repeatable, but more than twice does not bring
             more.
  
         --verbosity=LEVEL (absent=warning)
             Be more or less verbose. LEVEL must be one of quiet, error,
             warning, info or debug. Takes over -v.
  
         --version
             Show version information.
  
  EXIT STATUS
         configure exits with the following status:
  
         0   on success.
  
         123 on indiscriminate errors reported on standard error.
  
         124 on command line parsing errors.
  
         125 on unexpected internal errors (bugs).
  
  ENVIRONMENT
         These environment variables affect the execution of configure:
  
         MIRAGE_EXTRA_REPOS
             See option --extra-repos.
  
  SEE ALSO
         test(1)
  

Help configure -o --help=plain
  $ ./config.exe configure -o foo --help=plain | tee d2
  NAME
         test-configure - Configure a test application.
  
  SYNOPSIS
         test configure [OPTION]… 
  
  DESCRIPTION
         The configure command initializes a fresh test application.
  
  CONFIGURE OPTIONS
         --context-file=FILE (absent=test.context)
             The context file to use.
  
         --depext
             Enable call to `opam depext' in the project Makefile.
  
         --dry-run
             Display I/O actions instead of executing them.
  
         --extra-repos=NAME1:URL1,NAME2:URL2,...
         (absent=opam-overlays:https://github.com/dune-universe/opam-overlays.git,mirage-overlays:https://github.com/dune-universe/mirage-opam-overlays.git
         or MIRAGE_EXTRA_REPOS env)
             Additional opam-repositories to use when using `opam monorepo
             lock' to gather local sources. Default:
             https://github.com/dune-universe/opam-overlays.git &
             https://github.com/dune-universe/mirage-opam-overlays.git.
  
         -f FILE, --file=FILE, --config-file=FILE (absent=config.ml)
             The configuration file to use.
  
         --no-depext
             Disable call to `opam depext' in the project Makefile.
  
         --no-extra-repo
             Disable the use of any overlay repository.
  
         -o FILE, --output=FILE
             Name of the output file.
  
  APPLICATION OPTIONS
         --hello=VAL (absent=Hello World!)
             How to say hello. 
  
         --vote=VOTE (absent=cat)
             Vote. 
  
         --warn-error=BOOL (absent=false)
             Enable -warn-error when compiling OCaml sources. 
  
  COMMON OPTIONS
         --color=WHEN (absent=auto)
             Colorize the output. WHEN must be one of auto, always or never.
  
         --help[=FMT] (default=auto)
             Show this help in format FMT. The value FMT must be one of auto,
             pager, groff or plain. With auto, the format is pager or plain
             whenever the TERM env var is dumb or undefined.
  
         -q, --quiet
             Be quiet. Takes over -v and --verbosity.
  
         -v, --verbose
             Increase verbosity. Repeatable, but more than twice does not bring
             more.
  
         --verbosity=LEVEL (absent=warning)
             Be more or less verbose. LEVEL must be one of quiet, error,
             warning, info or debug. Takes over -v.
  
         --version
             Show version information.
  
  EXIT STATUS
         configure exits with the following status:
  
         0   on success.
  
         123 on indiscriminate errors reported on standard error.
  
         124 on command line parsing errors.
  
         125 on unexpected internal errors (bugs).
  
  ENVIRONMENT
         These environment variables affect the execution of configure:
  
         MIRAGE_EXTRA_REPOS
             See option --extra-repos.
  
  SEE ALSO
         test(1)
  

No difference
  $ diff d1 d2
