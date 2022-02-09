Configure failure
  $ ./test.exe configure --vote=dog
  configuration file config.ml missing
  [1]

Build failure
  $ ./test.exe build --vote=dog
  configuration file config.ml missing
  [1]


Query failure
  $ ./test.exe query --vote=dog
  configuration file config.ml missing
  [1]


Describe failure
  $ ./test.exe describe --vote=dog
  configuration file config.ml missing
  [1]

Clean does not fail
  $ ./test.exe clean --vote=dog

Help does not fail
  $ ./test.exe help --man-format=plain
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
  
