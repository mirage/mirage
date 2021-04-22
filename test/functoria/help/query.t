Help query --man-format=plain
  $ ./config.exe help query --man-format=plain | tee d1
  NAME
         test-query - Query information about the test application.
  
  SYNOPSIS
         test query [OPTION]... [INFO]
  
  DESCRIPTION
         The query command queries information about the test application.
  
  QUERY OPTIONS
         --depext
             Enable call to `opam depext' in the project Makefile.
  
         --extra-repo=URL (absent=https://github.com/mirage/opam-overlays.git
         or MIRAGE_EXTRA_REPO env)
             Additional opam-repository to use when using `opam monorepo lock'
             to gather local sources. Default:
             https://github.com/mirage/opam-overlays.git.
  
         --no-depext
             Disable call to `opam depext' in the project Makefile.
  
         --no-extra-repo
             Disable the use of any overlay repository.
  
  CONFIGURE OPTIONS
         --context-file=FILE (absent=test.context)
             The context file to use.
  
         --dry-run
             Display I/O actions instead of executing them.
  
         -f FILE, --file=FILE, --config-file=FILE (absent=config.ml)
             The configuration file to use.
  
         -o FILE, --output=FILE
             Name of the output file.
  
         INFO (absent=packages)
             The information to query. INFO must be one of `name', `packages',
             `monorepo.opam', `switch.opam', `files', `Makefile',
             `dune.config', `dune.build', `dune-project', `dune-workspace' or
             `dune.dist'
  
  APPLICATION OPTIONS
         --hello=VAL (absent=Hello World!)
             How to say hello. 
  
         --vote=VOTE (absent=cat)
             Vote. 
  
         --warn-error=BOOL (absent=false)
             Enable -warn-error when compiling OCaml sources. 
  
  OPTIONS
         --help[=FMT] (default=auto)
             Show this help in format FMT. The value FMT must be one of `auto',
             `pager', `groff' or `plain'. With `auto', the format is `pager` or
             `plain' whenever the TERM env var is `dumb' or undefined.
  
         --version
             Show version information.
  
  COMMON OPTIONS
         --color=WHEN (absent=auto)
             Colorize the output. WHEN must be one of `auto', `always' or
             `never'.
  
         -q, --quiet
             Be quiet. Takes over -v and --verbosity.
  
         -v, --verbose
             Increase verbosity. Repeatable, but more than twice does not bring
             more.
  
         --verbosity=LEVEL (absent=warning)
             Be more or less verbose. LEVEL must be one of `quiet', `error',
             `warning', `info' or `debug'. Takes over -v.
  
  ENVIRONMENT
         These environment variables affect the execution of query:
  
         MIRAGE_EXTRA_REPO
             See option --extra-repo.
  

Help query --help=plain
  $ ./config.exe query --help=plain | tee d2
  NAME
         test-query - Query information about the test application.
  
  SYNOPSIS
         test query [OPTION]... [INFO]
  
  DESCRIPTION
         The query command queries information about the test application.
  
  QUERY OPTIONS
         --depext
             Enable call to `opam depext' in the project Makefile.
  
         --extra-repo=URL (absent=https://github.com/mirage/opam-overlays.git
         or MIRAGE_EXTRA_REPO env)
             Additional opam-repository to use when using `opam monorepo lock'
             to gather local sources. Default:
             https://github.com/mirage/opam-overlays.git.
  
         --no-depext
             Disable call to `opam depext' in the project Makefile.
  
         --no-extra-repo
             Disable the use of any overlay repository.
  
  CONFIGURE OPTIONS
         --context-file=FILE (absent=test.context)
             The context file to use.
  
         --dry-run
             Display I/O actions instead of executing them.
  
         -f FILE, --file=FILE, --config-file=FILE (absent=config.ml)
             The configuration file to use.
  
         -o FILE, --output=FILE
             Name of the output file.
  
         INFO (absent=packages)
             The information to query. INFO must be one of `name', `packages',
             `monorepo.opam', `switch.opam', `files', `Makefile',
             `dune.config', `dune.build', `dune-project', `dune-workspace' or
             `dune.dist'
  
  APPLICATION OPTIONS
         --hello=VAL (absent=Hello World!)
             How to say hello. 
  
         --vote=VOTE (absent=cat)
             Vote. 
  
         --warn-error=BOOL (absent=false)
             Enable -warn-error when compiling OCaml sources. 
  
  OPTIONS
         --help[=FMT] (default=auto)
             Show this help in format FMT. The value FMT must be one of `auto',
             `pager', `groff' or `plain'. With `auto', the format is `pager` or
             `plain' whenever the TERM env var is `dumb' or undefined.
  
         --version
             Show version information.
  
  COMMON OPTIONS
         --color=WHEN (absent=auto)
             Colorize the output. WHEN must be one of `auto', `always' or
             `never'.
  
         -q, --quiet
             Be quiet. Takes over -v and --verbosity.
  
         -v, --verbose
             Increase verbosity. Repeatable, but more than twice does not bring
             more.
  
         --verbosity=LEVEL (absent=warning)
             Be more or less verbose. LEVEL must be one of `quiet', `error',
             `warning', `info' or `debug'. Takes over -v.
  
  ENVIRONMENT
         These environment variables affect the execution of query:
  
         MIRAGE_EXTRA_REPO
             See option --extra-repo.
  

No difference
  $ diff d1 d2
