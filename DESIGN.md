# Multi-stage code generation

### Configure, Build, Clean

When files are generated, the commands need to be run in `_build`.
and hence be called by `dune`. To allow `dune` to drive these
commands, they should be called via an alias.

REMARK: alias do not have CLI arguments, so everyhing is set by
the configure command.

```
$ mirage configure --file <path>/<file>.ml <args>
-> generate dune-project
-> generate path/dune
-> generate path/.mirage.config
-> call dune rule (needed to generate files in _build)
  $ dune build @mirage-configure <path>
  -> compile config.exe
  -> dune re-exec in _build/default/<path>
    $ ./config.exe configure --file <file>.ml <args>
    -> extract context from <args> and .mirage.config
    -> generate main.ml, key_gen.ml, etc.
```

```
$ <path>/config.exe configure --file <path>/<file> <args>
-> generate <path>/main.ml, <path>/key_gen.ml, etc.
```

```
$ mirage build --file <path>/<file>
-> call dune rule (needed to generate files in _build)
  $ dune build @mirage-build <path>
  -> dune re-exec in _build/default/<path>
    $ ./config.exe build --file <file> <configure-args>
    -> generate build files and main.exe
```

```
$ mirage clean --file <path>/<file>
-> call dune rule (needed to call clean-up code _build)
  $ dune build @mirage-clean <path>
  -> dune re-exec in _build/default/<path>
    $ ./config.exe clean --file <file> <configure-args>
```

### Description, Query

No files are generated so they can be called directly using `dune exec`;
They also take more command-line arguments than configure, build, clean,
so they need to merge what is provided on the CLI and what is cached
on disk.

```
$ mirage describe --file <path>/<file>.ml <descr-args> <descr-context>
-> re-exec
  $ dune exec -- \
    <path>/config.exe describe \
      --file <path>/<file>.ml <descr-args> \
       <descr-context>
  -> read <path>/.mirage.config and merge it with <descr-context>
```

```
$ mirage help --file <path>/<file>.ml <help-args> <help-context>
-> re-exec
  $ dune exec -- \
    <path>/config.exe help \
      --file <path>/<file>.ml <help-args> \
       <help-context>
  -> read <path>/.mirage.config and merge it with <help-context>
```
