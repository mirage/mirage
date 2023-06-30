Query package - no target - x.context
  $ ./config.exe query package --context-file=x.context
  "fmt" { ?monorepo }
  "functoria-runtime" { ?monorepo }
  "x" { ?monorepo }

Query package - no target - y.context
  $ ./config.exe query package --context-file=y.context
  "fmt" { ?monorepo }
  "functoria-runtime" { ?monorepo }
  "y" { ?monorepo }

Query package - x target  - y.context
  $ ./config.exe query package -t x --context-file=y.context
  test: `--target' has different values in the context file (passed with `--context-file') and on the CLI.
  [1]

Query package - y target  - x.context
  $ ./config.exe query package -t y --context-file=x.context
  test: `--target' has different values in the context file (passed with `--context-file') and on the CLI.
  [1]

Describe - no target - x.context
  $ ./config.exe describe --context-file=x.context
  Name       noop
  Keys       target=x,
             vote=cat (default),
             warn_error=false (default)

Describe - no target - y.context
  $ ./config.exe describe --context-file=y.context
  Name       noop
  Keys       target=y,
             vote=cat (default),
             warn_error=false (default)

Describe - x target  - y.context
  $ ./config.exe describe -t x --context-file=y.context
  test: `--target' has different values in the context file (passed with `--context-file') and on the CLI.
  [1]

Describe - y target  - x.context
  $ ./config.exe describe -t y --context-file=x.context
  test: `--target' has different values in the context file (passed with `--context-file') and on the CLI.
  [1]

Bad context cache
  $ ./config.exe configure -t nonexistent --context-file=z.context
  test: option '-t': invalid value 'nonexistent', expected either 'y' or 'x'
  Usage: test configure [OPTION]…
  Try 'test configure --help' or 'test --help' for more information.
  [1]
