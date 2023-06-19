  $ export MIRAGE_DEFAULT_TARGET=unix

Configure
  $ ./config.exe configure
  Fatal error: exception Invalid_argument("Your configuration includes a job without arguments. Please add a dependency in your config.ml: use `let main = Mirage.main \"Unikernel.hello\" (job @-> job) register \"hello\" [ main $ noop ]` instead of `.. job .. [ main ]`.")
  [2]
