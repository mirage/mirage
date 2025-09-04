  $ export MIRAGE_DEFAULT_TARGET=unix

Help query --man-format=plain
  $ ./config.exe help query --man-format=plain | tee d1
  NAME
         mirage-query - Query information about the mirage application.
  
  SYNOPSIS
         mirage query [OPTION]… [INFO]
  
  DESCRIPTION
         The query command queries information about the mirage application.
  
  QUERY OPTIONS
         --depext
             Enable call to `opam depext' in the project Makefile.
  
         --extra-repos=NAME1:URL1,NAME2:URL2,...
         (absent=opam-overlays:https://github.com/dune-universe/opam-overlays.git,mirage-overlays:https://github.com/dune-universe/mirage-opam-overlays.git
         or MIRAGE_EXTRA_REPOS env)
             Additional opam-repositories to use when using `opam monorepo
             lock' to gather local sources. Default:
             https://github.com/dune-universe/opam-overlays.git &
             https://github.com/dune-universe/mirage-opam-overlays.git.
  
         --no-depext
             Disable call to `opam depext' in the project Makefile.
  
         --no-extra-repo
             Disable the use of any overlay repository.
  
  MIRAGE PARAMETERS
         -t TARGET, --target=TARGET (absent=unix or MODE env)
             Target platform to compile the unikernel for. Valid values are:
             one of unix, macosx, xen, virtio, hvt, muen, qubes, genode, spt,
             unikraft-firecracker or unikraft-qemu
  
  CONFIGURE OPTIONS
         --context-file=FILE (absent=mirage.context)
             The context file to use.
  
         --dry-run
             Display I/O actions instead of executing them.
  
         -f FILE, --file=FILE, --config-file=FILE (absent=config.ml)
             The configuration file to use.
  
         -o FILE, --output=FILE
             Name of the output file.
  
         INFO (absent=packages)
             The information to query. INFO must be one of 'name', 'packages',
             'opam', 'files', 'Makefile', 'dune.config', 'dune.build',
             'dune-project', 'dune-workspace' or 'dune.dist'
  
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
         mirage query exits with:
  
         0   on success.
  
         123 on indiscriminate errors reported on standard error.
  
         124 on command line parsing errors.
  
         125 on unexpected internal errors (bugs).
  
  ENVIRONMENT
         These environment variables affect the execution of mirage query:
  
         MIRAGE_EXTRA_REPOS
             See option --extra-repos.
  
         MODE
             See option --target.
  
  SEE ALSO
         mirage(1)
  

Help query --help=plain
  $ ./config.exe query --help=plain | tee d2
  NAME
         mirage-query - Query information about the mirage application.
  
  SYNOPSIS
         mirage query [OPTION]… [INFO]
  
  DESCRIPTION
         The query command queries information about the mirage application.
  
  QUERY OPTIONS
         --depext
             Enable call to `opam depext' in the project Makefile.
  
         --extra-repos=NAME1:URL1,NAME2:URL2,...
         (absent=opam-overlays:https://github.com/dune-universe/opam-overlays.git,mirage-overlays:https://github.com/dune-universe/mirage-opam-overlays.git
         or MIRAGE_EXTRA_REPOS env)
             Additional opam-repositories to use when using `opam monorepo
             lock' to gather local sources. Default:
             https://github.com/dune-universe/opam-overlays.git &
             https://github.com/dune-universe/mirage-opam-overlays.git.
  
         --no-depext
             Disable call to `opam depext' in the project Makefile.
  
         --no-extra-repo
             Disable the use of any overlay repository.
  
  MIRAGE PARAMETERS
         -t TARGET, --target=TARGET (absent=unix or MODE env)
             Target platform to compile the unikernel for. Valid values are:
             one of unix, macosx, xen, virtio, hvt, muen, qubes, genode, spt,
             unikraft-firecracker or unikraft-qemu
  
  CONFIGURE OPTIONS
         --context-file=FILE (absent=mirage.context)
             The context file to use.
  
         --dry-run
             Display I/O actions instead of executing them.
  
         -f FILE, --file=FILE, --config-file=FILE (absent=config.ml)
             The configuration file to use.
  
         -o FILE, --output=FILE
             Name of the output file.
  
         INFO (absent=packages)
             The information to query. INFO must be one of 'name', 'packages',
             'opam', 'files', 'Makefile', 'dune.config', 'dune.build',
             'dune-project', 'dune-workspace' or 'dune.dist'
  
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
         mirage query exits with:
  
         0   on success.
  
         123 on indiscriminate errors reported on standard error.
  
         124 on command line parsing errors.
  
         125 on unexpected internal errors (bugs).
  
  ENVIRONMENT
         These environment variables affect the execution of mirage query:
  
         MIRAGE_EXTRA_REPOS
             See option --extra-repos.
  
         MODE
             See option --target.
  
  SEE ALSO
         mirage(1)
  

No difference
  $ diff d1 d2
