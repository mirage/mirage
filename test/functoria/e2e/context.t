Query package - no target - x.context
  $ ./test.exe query package --context-file=context/x.context -f context/config.ml
  "fmt" { ?monorepo }
  "mirage-runtime" { ?monorepo }
  "x" { ?monorepo }

Query package - no target - y.context
  $ ./test.exe query package --context-file=context/y.context -f context/config.ml
  "fmt" { ?monorepo }
  "mirage-runtime" { ?monorepo }
  "y" { ?monorepo }

Query package - x target  - y.context
  $ ./test.exe query package -t x --context-file=context/y.context -f context/config.ml
  "fmt" { ?monorepo }
  "mirage-runtime" { ?monorepo }
  "x" { ?monorepo }

Query package - y target  - x.context
  $ ./test.exe query package -t y --context-file=context/x.context -f context/config.ml
  "fmt" { ?monorepo }
  "mirage-runtime" { ?monorepo }
  "y" { ?monorepo }

Describe - no target - x.context
  $ ./test.exe describe --context-file=context/x.context -f context/config.ml
  Name       noop
  Keys       target=x,
             vote=cat (default),
             warn_error=false (default)

Describe - no target - y.context
  $ ./test.exe describe --context-file=context/y.context -f context/config.ml
  Name       noop
  Keys       target=y,
             vote=cat (default),
             warn_error=false (default)

Describe - x target  - y.context
  $ ./test.exe describe -t x --context-file=context/y.context -f context/config.ml
  Name       noop
  Keys       target=x,
             vote=cat (default),
             warn_error=false (default)

Describe - y target  - x.context
  $ ./test.exe describe -t y --context-file=context/x.context -f context/config.ml
  Name       noop
  Keys       target=y,
             vote=cat (default),
             warn_error=false (default)

Bad context cache
  $ ./test.exe configure -t nonexistent --context-file=context/z.context -f context/config.ml
  test.exe: [WARNING] Skipping version check, since our_version ("1.0~test") fails to parse: only digits and . allowed in version
  test: option '-t': invalid value 'nonexistent', expected either 'y' or 'x'
  Usage: test configure [-t VAL] [OPTION]…
  Try 'test configure --help' or 'test --help' for more information.
  [1]
