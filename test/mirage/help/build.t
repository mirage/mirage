  $ export MIRAGE_DEFAULT_TARGET=unix

Help build --man-format=plain
  $ ./config.exe help build --man-format=plain | tee d1
  NAME
         mirage-build - Build a mirage application.
  
  SYNOPSIS
         mirage build [OPTION]…
  
  DESCRIPTION
         Build a mirage application.
  
  UNIKERNEL PARAMETERS
         -l LEVEL, --logs=LEVEL (absent MIRAGE_LOGS env)
             Be more or less verbose. LEVEL must be of the form
             *:info,foo:debug means that that the log threshold is set to info
             for every log sources but the foo which is set to debug.
  
  MIRAGE PARAMETERS
         -t TARGET, --target=TARGET (absent=unix or MODE env)
             Target platform to compile the unikernel for. Valid values are:
             xen, qubes, unix, macosx, virtio, hvt, spt, muen, genode.
  
  CONFIGURE OPTIONS
         --context-file=FILE (absent=mirage.context)
             The context file to use.
  
         --dry-run
             Display I/O actions instead of executing them.
  
         -f FILE, --file=FILE, --config-file=FILE (absent=config.ml)
             The configuration file to use.
  
         -o FILE, --output=FILE
             Name of the output file.
  
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
         mirage build exits with:
  
         0   on success.
  
         123 on indiscriminate errors reported on standard error.
  
         124 on command line parsing errors.
  
         125 on unexpected internal errors (bugs).
  
  ENVIRONMENT
         These environment variables affect the execution of build:
  
         MIRAGE_LOGS
             See option --logs.
  
         MODE
             See option --target.
  
  SEE ALSO
         mirage(1)
  

Help build --help=plain
  $ ./config.exe build --help=plain | tee d2
  NAME
         mirage-build - Build a mirage application.
  
  SYNOPSIS
         mirage build [OPTION]…
  
  DESCRIPTION
         Build a mirage application.
  
  UNIKERNEL PARAMETERS
         -l LEVEL, --logs=LEVEL (absent MIRAGE_LOGS env)
             Be more or less verbose. LEVEL must be of the form
             *:info,foo:debug means that that the log threshold is set to info
             for every log sources but the foo which is set to debug.
  
  MIRAGE PARAMETERS
         -t TARGET, --target=TARGET (absent=unix or MODE env)
             Target platform to compile the unikernel for. Valid values are:
             xen, qubes, unix, macosx, virtio, hvt, spt, muen, genode.
  
  CONFIGURE OPTIONS
         --context-file=FILE (absent=mirage.context)
             The context file to use.
  
         --dry-run
             Display I/O actions instead of executing them.
  
         -f FILE, --file=FILE, --config-file=FILE (absent=config.ml)
             The configuration file to use.
  
         -o FILE, --output=FILE
             Name of the output file.
  
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
         mirage build exits with:
  
         0   on success.
  
         123 on indiscriminate errors reported on standard error.
  
         124 on command line parsing errors.
  
         125 on unexpected internal errors (bugs).
  
  ENVIRONMENT
         These environment variables affect the execution of build:
  
         MIRAGE_LOGS
             See option --logs.
  
         MODE
             See option --target.
  
  SEE ALSO
         mirage(1)
  

No difference
  $ diff d1 d2
