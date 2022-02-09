Test that the help command works without config file:

  $ ./test.exe help -v --help=plain
  test.exe: [INFO] run: help:
                        { "context" = ;
                          "config_file" = config.ml;
                          "output" = None;
                          "dry_run" = false }
  NAME
         test-help - Display help about test commands.
  
  SYNOPSIS
         test help [--man-format=FMT] [OPTION]… [TOPIC]
  
  DESCRIPTION
         Prints help.
  
         Use `test help topics' to get the full list of help topics.
  
  DESCRIBE OPTIONS
         --eval
             Fully evaluate the graph before showing it. The default when the
             unikernel has already been configured.
  
         --no-eval
             Do not evaluate the graph before showing it. See --eval. The
             default when the unikernel has not been configured.
  
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
  
  ARGUMENTS
         TOPIC
             The topic to get help on.
  
  OPTIONS
         --man-format=FMT (absent=pager)
             Show output in format FMT. The value FMT must be one of auto,
             pager, groff or plain. With auto, the format is pager or plain
             whenever the TERM env var is dumb or undefined.
  
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
         help exits with the following status:
  
         0   on success.
  
         123 on indiscriminate errors reported on standard error.
  
         124 on command line parsing errors.
  
         125 on unexpected internal errors (bugs).
  
  ENVIRONMENT
         These environment variables affect the execution of help:
  
         MIRAGE_EXTRA_REPOS
             See option --extra-repos.
  
  SEE ALSO
         test(1)
  


As well as the default command:

  $ ./test.exe -v
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
  
