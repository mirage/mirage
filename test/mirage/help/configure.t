  $ export MIRAGE_DEFAULT_TARGET=unix

Help configure --man-format=plain
  $ ./config.exe help configure --man-format=plain | tee d1
  NAME
         mirage-configure - Configure a mirage application.
  
  SYNOPSIS
         mirage configure [OPTION]... 
  
  DESCRIPTION
         The configure command initializes a fresh mirage application.
  
  UNIKERNEL PARAMETERS
         -l LEVEL, --logs=LEVEL (absent MIRAGE_LOGS env)
             Be more or less verbose. LEVEL must be of the form
             *:info,foo:debug means that that the log threshold is set to info
             for every log sources but the foo which is set to debug. 
  
  OCAML RUNTIME PARAMETERS
         --allocation-policy=ALLOCATION (absent=next-fit)
             The policy used for allocating in the OCaml heap. Possible values
             are: next-fit, first-fit, best-fit. Best-fit is only supported
             since OCaml 4.10. 
  
         --backtrace=BOOL (absent=true)
             Trigger the printing of a stack backtrace when an uncaught
             exception aborts the unikernel. 
  
         --custom-major-ratio=CUSTOM MAJOR RATIO
             Target ratio of floating garbage to major heap size for
             out-of-heap memory held by custom values. Default: 44. 
  
         --custom-minor-max-size=CUSTOM MINOR MAX SIZE
             Maximum amount of out-of-heap memory for each custom value
             allocated in the minor heap. Default: 8192 bytes. 
  
         --custom-minor-ratio=CUSTOM MINOR RATIO
             Bound on floating garbage for out-of-heap memory held by custom
             values in the minor heap. Default: 100. 
  
         --gc-verbosity=VERBOSITY
             GC messages on standard error output. Sum of flags. Check GC
             module documentation for details. 
  
         --gc-window-size=WINDOW SIZE
             The size of the window used by the major GC for smoothing out
             variations in its workload. Between 1 adn 50, default: 1. 
  
         --major-heap-increment=MAJOR INCREMENT
             The size increment for the major heap (in words). If less than or
             equal 1000, it is a percentage of the current heap size. If more
             than 1000, it is a fixed number of words. Default: 15. 
  
         --max-space-overhead=MAX SPACE OVERHEAD
             Heap compaction is triggered when the estimated amount of wasted
             memory exceeds this (percentage of live data). If above 1000000,
             compaction is never triggered. Default: 500. 
  
         --minor-heap-size=MINOR SIZE
             The size of the minor heap (in words). Default: 256k. 
  
         --randomize-hashtables=BOOL (absent=true)
             Turn on randomization of all hash tables by default. 
  
         --space-overhead=SPACE OVERHEAD
             The percentage of live data of wasted memory, due to GC does not
             immediately collect unreachable blocks. The major GC speed is
             computed from this parameter, it will work more if smaller.
             Default: 80. 
  
  MIRAGE PARAMETERS
         -g  Enables target-specific support for debugging. Supported targets:
             hvt (compiles solo5-hvt with GDB server support). 
  
         -t TARGET, --target=TARGET (absent=unix or MODE env)
             Target platform to compile the unikernel for. Valid values are:
             xen, qubes, unix, macosx, virtio, hvt, spt, muen, genode. 
  
         --warn-error
             Enable -warn-error when compiling OCaml sources. 
  
  CONFIGURE OPTIONS
         --context-file=FILE (absent=mirage.context)
             The context file to use.
  
         --depext
             Enable call to `opam depext' in the project Makefile.
  
         --dry-run
             Display I/O actions instead of executing them.
  
         --extra-repo=URL (absent=https://github.com/mirage/opam-overlays.git
         or MIRAGE_EXTRA_REPO env)
             Additional opam-repository to use when using `opam monorepo lock'
             to gather local sources. Default:
             https://github.com/mirage/opam-overlays.git.
  
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
         These environment variables affect the execution of configure:
  
         MIRAGE_EXTRA_REPO
             See option --extra-repo.
  
         MIRAGE_LOGS
             See option --logs.
  
         MODE
             See option --target.
  

Configure help --help=plain
  $ ./config.exe configure --help=plain | tee d2
  NAME
         mirage-configure - Configure a mirage application.
  
  SYNOPSIS
         mirage configure [OPTION]... 
  
  DESCRIPTION
         The configure command initializes a fresh mirage application.
  
  UNIKERNEL PARAMETERS
         -l LEVEL, --logs=LEVEL (absent MIRAGE_LOGS env)
             Be more or less verbose. LEVEL must be of the form
             *:info,foo:debug means that that the log threshold is set to info
             for every log sources but the foo which is set to debug. 
  
  OCAML RUNTIME PARAMETERS
         --allocation-policy=ALLOCATION (absent=next-fit)
             The policy used for allocating in the OCaml heap. Possible values
             are: next-fit, first-fit, best-fit. Best-fit is only supported
             since OCaml 4.10. 
  
         --backtrace=BOOL (absent=true)
             Trigger the printing of a stack backtrace when an uncaught
             exception aborts the unikernel. 
  
         --custom-major-ratio=CUSTOM MAJOR RATIO
             Target ratio of floating garbage to major heap size for
             out-of-heap memory held by custom values. Default: 44. 
  
         --custom-minor-max-size=CUSTOM MINOR MAX SIZE
             Maximum amount of out-of-heap memory for each custom value
             allocated in the minor heap. Default: 8192 bytes. 
  
         --custom-minor-ratio=CUSTOM MINOR RATIO
             Bound on floating garbage for out-of-heap memory held by custom
             values in the minor heap. Default: 100. 
  
         --gc-verbosity=VERBOSITY
             GC messages on standard error output. Sum of flags. Check GC
             module documentation for details. 
  
         --gc-window-size=WINDOW SIZE
             The size of the window used by the major GC for smoothing out
             variations in its workload. Between 1 adn 50, default: 1. 
  
         --major-heap-increment=MAJOR INCREMENT
             The size increment for the major heap (in words). If less than or
             equal 1000, it is a percentage of the current heap size. If more
             than 1000, it is a fixed number of words. Default: 15. 
  
         --max-space-overhead=MAX SPACE OVERHEAD
             Heap compaction is triggered when the estimated amount of wasted
             memory exceeds this (percentage of live data). If above 1000000,
             compaction is never triggered. Default: 500. 
  
         --minor-heap-size=MINOR SIZE
             The size of the minor heap (in words). Default: 256k. 
  
         --randomize-hashtables=BOOL (absent=true)
             Turn on randomization of all hash tables by default. 
  
         --space-overhead=SPACE OVERHEAD
             The percentage of live data of wasted memory, due to GC does not
             immediately collect unreachable blocks. The major GC speed is
             computed from this parameter, it will work more if smaller.
             Default: 80. 
  
  MIRAGE PARAMETERS
         -g  Enables target-specific support for debugging. Supported targets:
             hvt (compiles solo5-hvt with GDB server support). 
  
         -t TARGET, --target=TARGET (absent=unix or MODE env)
             Target platform to compile the unikernel for. Valid values are:
             xen, qubes, unix, macosx, virtio, hvt, spt, muen, genode. 
  
         --warn-error
             Enable -warn-error when compiling OCaml sources. 
  
  CONFIGURE OPTIONS
         --context-file=FILE (absent=mirage.context)
             The context file to use.
  
         --depext
             Enable call to `opam depext' in the project Makefile.
  
         --dry-run
             Display I/O actions instead of executing them.
  
         --extra-repo=URL (absent=https://github.com/mirage/opam-overlays.git
         or MIRAGE_EXTRA_REPO env)
             Additional opam-repository to use when using `opam monorepo lock'
             to gather local sources. Default:
             https://github.com/mirage/opam-overlays.git.
  
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
         These environment variables affect the execution of configure:
  
         MIRAGE_EXTRA_REPO
             See option --extra-repo.
  
         MIRAGE_LOGS
             See option --logs.
  
         MODE
             See option --target.
  

No difference
  $ diff d1 d2
