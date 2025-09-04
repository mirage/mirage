  $ export MIRAGE_DEFAULT_TARGET=unix

Help describe --man-format=plain
  $ ./config.exe help describe --man-format=plain | tee d1
  NAME
         mirage-describe - Describe a mirage application.
  
  SYNOPSIS
         mirage describe [OPTION]…
  
  DESCRIPTION
         The describe command describes the configuration of a mirage
         application.
  
         The dot output contains the following elements:
         If vertices
             Represented as circles. Branches are dotted, and the default
             branch is in bold.
         Configurables
             Represented as rectangles. The order of the output arrows is the
             order of the functor arguments.
         Data dependencies
             Represented as dashed arrows.
         App vertices
             Represented as diamonds. The bold arrow is the functor part.
  
  MIRAGE PARAMETERS
         -t TARGET, --target=TARGET (absent=unix or MODE env)
             Target platform to compile the unikernel for. Valid values are:
             one of unix, macosx, xen, virtio, hvt, muen, qubes, genode, spt,
             unikraft-firecracker or unikraft-qemu
  
  DESCRIBE OPTIONS
         --dot
             Output a dot description. If no output file is given, it will
             display the dot file using the command given to --dot-command. Use
             in combination with --output=- (short version: -o-) to display the
             dot file on stdout.
  
         --dot-command=COMMAND (absent=xdot)
             Command used to show a dot file. This command should accept a dot
             file on its standard input.
  
         --eval
             Fully evaluate the graph before showing it. The default when the
             unikernel has already been configured.
  
         --no-eval
             Do not evaluate the graph before showing it. See --eval. The
             default when the unikernel has not been configured.
  
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
         mirage describe exits with:
  
         0   on success.
  
         123 on indiscriminate errors reported on standard error.
  
         124 on command line parsing errors.
  
         125 on unexpected internal errors (bugs).
  
  ENVIRONMENT
         These environment variables affect the execution of mirage describe:
  
         MODE
             See option --target.
  
  SEE ALSO
         mirage(1)
  

Help describe --help=plain
  $ ./config.exe describe --help=plain | tee d2
  NAME
         mirage-describe - Describe a mirage application.
  
  SYNOPSIS
         mirage describe [OPTION]…
  
  DESCRIPTION
         The describe command describes the configuration of a mirage
         application.
  
         The dot output contains the following elements:
         If vertices
             Represented as circles. Branches are dotted, and the default
             branch is in bold.
         Configurables
             Represented as rectangles. The order of the output arrows is the
             order of the functor arguments.
         Data dependencies
             Represented as dashed arrows.
         App vertices
             Represented as diamonds. The bold arrow is the functor part.
  
  MIRAGE PARAMETERS
         -t TARGET, --target=TARGET (absent=unix or MODE env)
             Target platform to compile the unikernel for. Valid values are:
             one of unix, macosx, xen, virtio, hvt, muen, qubes, genode, spt,
             unikraft-firecracker or unikraft-qemu
  
  DESCRIBE OPTIONS
         --dot
             Output a dot description. If no output file is given, it will
             display the dot file using the command given to --dot-command. Use
             in combination with --output=- (short version: -o-) to display the
             dot file on stdout.
  
         --dot-command=COMMAND (absent=xdot)
             Command used to show a dot file. This command should accept a dot
             file on its standard input.
  
         --eval
             Fully evaluate the graph before showing it. The default when the
             unikernel has already been configured.
  
         --no-eval
             Do not evaluate the graph before showing it. See --eval. The
             default when the unikernel has not been configured.
  
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
         mirage describe exits with:
  
         0   on success.
  
         123 on indiscriminate errors reported on standard error.
  
         124 on command line parsing errors.
  
         125 on unexpected internal errors (bugs).
  
  ENVIRONMENT
         These environment variables affect the execution of mirage describe:
  
         MODE
             See option --target.
  
  SEE ALSO
         mirage(1)
  

No difference
  $ diff d1 d2
