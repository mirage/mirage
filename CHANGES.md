## 2.2.0 (01/08/2017)

* API improvements: add `Functoria_app.packages` and `ignore_dirs`
  functions. Also add prettyprinting functions to the CLI module. (@samoht)
* rename the man pages from "Unikernel" references to "Application"
* Add end-to-end tests for the tool (@samoht)

## 2.1.0 (03/07/2017)

* port build to Jbuilder (#115 @djs55)
* add `--output` option to configure so that the name of hte output target can be overridden (#108 @samoht)
* improve README formatting (@olleolleolle)
* fix formatting error in the `help` subcommand (#112 @neatonk)
* do not munge the name of the output opam package twice (#113 @hannesm)

## 2.0.2 (07/03/2017)

* don't complain about command-line options when config.ml is unbuildable (#109, by @yomimono and @talex5)

## 2.0.1 (13/02/2017)

* raise an exception with useful information when Univ.new_key fails (#102, by @yomimono)
* remove `-f <config-file>` command option to unbreak `--help` with subcommands
  and unikernel present (which config.ml is dynamically loaded to present
  possible command-line keys (#101 (superseeding #100), discussion in #91 and
  #97, fixes #72 by @hannesm)

## 2.0.0 (19/01/2017)

* invoke ocamlbuild with quiet (#93 by @hannesm)
* restrict -f command line argument to items in current working directory (#91 by @hannesm)
* ocamlify opam filename (#89 by @yomimono)
* persist configuration arguments (#85, #87 by @hannesm, @Drup)
* remove Functoria_misc.Log (#84 by @hannesm)
* remove Functoria_misc.Cmd (#84 by @hannesm)
* separate configure from build step, both are now done on the graph.  opam file is now generated during configure (#76, #84 by @hannesm)
* check presence of vertex before removing (#83 by #Drup)
* split into functoria and functoria-runtime opam packages (#80 by @hannesm)
* use Astring instead of custom Functoria_misc.String (#77 by @hannesm)
* expose Functoria_key.name, and use it to generate a list of runtime keys (#68 by @yomimono)
* remove Functoria_misc.Set (provided `of_list`), now depend on 4.03+ (#75 by @hannesm)
* signature of `connect` changed: value is now `'a io`, no result (fail hard instead!) (#71 by @hannesm)
* remove base_context (#65 by @yomimono)
* Switch to topkg (#64 by @samoht)

## 1.1.0 (29/04/2016)

* Add init jobs to start before every other ones (@talex5, @Drup, @samoht)

## 1.0.0 (16/02/2016)

* Initial release
