Configure
  $ ./config.exe configure a b c 2> configure.err
  [1]

  $ cat configure.err
  test: too many arguments, don't know what to do with 'a', 'b', 'c'
  Usage: test configure [OPTION]… 
  Try 'test configure --help' or 'test --help' for more information.

Build
  $ ./config.exe build a b c 2> build.err
  [1]

  $ cat build.err
  test: too many arguments, don't know what to do with 'a', 'b', 'c'
  Usage: test build [OPTION]… 
  Try 'test build --help' or 'test --help' for more information.

Clean
  $ ./config.exe clean a b c 2> clean.err
  [1]

  $ cat clean.err
  test: too many arguments, don't know what to do with 'a', 'b', 'c'
  Usage: test clean [OPTION]… 
  Try 'test clean --help' or 'test --help' for more information.

Query
  $ ./config.exe query a b c 2> query.err
  [1]

  $ cat query.err
  test: too many arguments, don't know what to do with 'b', 'c'
  Usage: test query [OPTION]… [INFO]
  Try 'test query --help' or 'test --help' for more information.

Describe
  $ ./config.exe describe a b c 2> describe.err
  [1]

  $ cat describe.err
  test: too many arguments, don't know what to do with 'a', 'b', 'c'
  Usage: test describe [OPTION]… 
  Try 'test describe --help' or 'test --help' for more information.

Help
  $ ./config.exe help a b c 2> help.err
  [1]

  $ cat help.err
  test: too many arguments, don't know what to do with 'b', 'c'
  Usage: test help [--man-format=FMT] [OPTION]… [TOPIC]
  Try 'test help --help' or 'test --help' for more information.

Simple help
  $ ./config.exe help --man-format=plain 2> simple-help.err
  NAME
         test-test - The test application builder
  
  SYNOPSIS
         test test [COMMAND] …
  
  DESCRIPTION
         The test application builder. It glues together a set of libraries and
         configuration (e.g. network and storage) into a standalone unikernel
         or UNIX binary.
  
         Use test help <command> for more information on a specific command.
  
  COMMANDS
         build [OPTION]… 
             Build a test application.
  
         clean [OPTION]… 
             Clean the files produced by test for a given application.
  
         configure [OPTION]… 
             Configure a test application.
  
         describe [OPTION]… 
             Describe a test application.
  
         help [--man-format=FMT] [OPTION]… [TOPIC]
             Display help about test commands.
  
         query [OPTION]… [INFO]
             Query information about the test application.
  
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
         test exits with the following status:
  
         0   on success.
  
         123 on indiscriminate errors reported on standard error.
  
         124 on command line parsing errors.
  
         125 on unexpected internal errors (bugs).
  
  SEE ALSO
         test(1)
  

  $ cat simple-help.err

Help configure
  $ ./config.exe help configure --man-format=plain 2> configure.err
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
  

  $ cat configure.err

Configure help
  $ ./config.exe configure help 2> configure-help.err
  [1]

  $ cat configure-help.err
  test: too many arguments, don't know what to do with 'help'
  Usage: test configure [OPTION]… 
  Try 'test configure --help' or 'test --help' for more information.

Help no config
  $ ./config.exe help --file=empty/config.ml --man-format=plain 2> help-no-config.err
  NAME
         test-test - The test application builder
  
  SYNOPSIS
         test test [COMMAND] …
  
  DESCRIPTION
         The test application builder. It glues together a set of libraries and
         configuration (e.g. network and storage) into a standalone unikernel
         or UNIX binary.
  
         Use test help <command> for more information on a specific command.
  
  COMMANDS
         build [OPTION]… 
             Build a test application.
  
         clean [OPTION]… 
             Clean the files produced by test for a given application.
  
         configure [OPTION]… 
             Configure a test application.
  
         describe [OPTION]… 
             Describe a test application.
  
         help [--man-format=FMT] [OPTION]… [TOPIC]
             Display help about test commands.
  
         query [OPTION]… [INFO]
             Query information about the test application.
  
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
         test exits with the following status:
  
         0   on success.
  
         123 on indiscriminate errors reported on standard error.
  
         124 on command line parsing errors.
  
         125 on unexpected internal errors (bugs).
  
  SEE ALSO
         test(1)
  
  $ cat help-no-config.err

Help no config with bad arguments
  $ ./config.exe help --file=empty/config.ml a b c 2> help-no-config-args.err
  [1]

  $ cat help-no-config-args.err
  test: too many arguments, don't know what to do with 'b', 'c'
  Usage: test help [--man-format=FMT] [OPTION]… [TOPIC]
  Try 'test help --help' or 'test --help' for more information.

Build help no config with bad arguments
  $ ./config.exe build --help=plain --file=empty/config.ml a b c 2> build-help-no-config-args.err
  NAME
         test-build - Build a test application.
  
  SYNOPSIS
         test build [OPTION]… 
  
  DESCRIPTION
         Build a test application.
  
  CONFIGURE OPTIONS
         --context-file=FILE (absent=test.context)
             The context file to use.
  
         --dry-run
             Display I/O actions instead of executing them.
  
         -f FILE, --file=FILE, --config-file=FILE (absent=config.ml)
             The configuration file to use.
  
         -o FILE, --output=FILE
             Name of the output file.
  
  APPLICATION OPTIONS
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
         build exits with the following status:
  
         0   on success.
  
         123 on indiscriminate errors reported on standard error.
  
         124 on command line parsing errors.
  
         125 on unexpected internal errors (bugs).
  
  SEE ALSO
         test(1)
  
  $ cat build-help-no-config-args.err

Version configure
  $ ./config.exe configure --version a b c
  1.0~test

Ambiguous
  $ ./config.exe c a b c 2> ambiguous.err
  [1]

  $ cat ambiguous.err
  test: command 'c' ambiguous and could be either 'clean' or 'configure'
  Usage: test [COMMAND] …
  Try 'test --help' for more information.

Default
  $ ./config.exe 2> default.err
  NAME
         test - The test application builder
  
  SYNOPSIS
         test [COMMAND] …
  
  DESCRIPTION
         The test application builder. It glues together a set of libraries and
         configuration (e.g. network and storage) into a standalone unikernel
         or UNIX binary.
  
         Use test help <command> for more information on a specific command.
  
  COMMANDS
         build [OPTION]… 
             Build a test application.
  
         clean [OPTION]… 
             Clean the files produced by test for a given application.
  
         configure [OPTION]… 
             Configure a test application.
  
         describe [OPTION]… 
             Describe a test application.
  
         help [--man-format=FMT] [OPTION]… [TOPIC]
             Display help about test commands.
  
         query [OPTION]… [INFO]
             Query information about the test application.
  
  COMMON OPTIONS
         --color=WHEN (absent=auto)
             Colorize the output. WHEN must be one of auto, always or never.
  
         --help[=FMT] (default=auto)
             Show this help in format FMT. The value FMT must be one of auto,
             pager, groff or plain. With auto, the format is pager or plain
             whenever the TERM env var is dumb or undefined.
  
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
  
         --version
             Show version information.
  
  EXIT STATUS
         test exits with the following status:
  
         0   on success.
  
         123 on indiscriminate errors reported on standard error.
  
         124 on command line parsing errors.
  
         125 on unexpected internal errors (bugs).
  

  $ cat default.err
