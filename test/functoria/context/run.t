Query package - no target - x.context
  $ ./config.exe query package --context-file=x.context
  "fmt" { switch != "" }
  "functoria-runtime" { switch != "" }
  "x" { switch != "" }

Query package - no target - y.context
  $ ./config.exe query package --context-file=y.context
  "fmt" { switch != "" }
  "functoria-runtime" { switch != "" }
  "y" { switch != "" }

Query package - x target  - y.context
  $ ./config.exe query package -t x --context-file=y.context
  "fmt" { switch != "" }
  "functoria-runtime" { switch != "" }
  "x" { switch != "" }

Query package - y target  - x.context
  $ ./config.exe query package -t y --context-file=x.context
  "fmt" { switch != "" }
  "functoria-runtime" { switch != "" }
  "y" { switch != "" }

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
  Name       noop
  Keys       target=x,
             vote=cat (default),
             warn_error=false (default)

Describe - y target  - x.context
  $ ./config.exe describe -t y --context-file=x.context
  Name       noop
  Keys       target=y,
             vote=cat (default),
             warn_error=false (default)
