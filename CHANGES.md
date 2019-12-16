## v3.0.3 (2019-12-17)

* Fix equality for `'a impl` values, which caused issue in `mirage configure`
  when multiple keys share the same name (issue #187, fix #188 by @samoht)
* App_info: avoid `opam list --rec` which uses the CUDF solver, instead do
  fixpoint manually. Fixes reproducibility with `orb` (#189 @hannesm)

## v3.0.2 (2019-11-03)

* Remove custom opam version comparison code, instead collect min and max as
  sets and output them all (#183, @hannesm fixes #143)
  for `package ~min:"1.0" ~max:"2.0" "a" ; package ~min:"1.5" ~max:"2.0" "a"`,
  the output is now `"a" {>= "1.0" & >= "1.5" & < "2.0"}`, it used to be
  `"a" {>= "1.5" & < "2.0"}`.

  The advantage of avoiding to parse version numbers is that it can't be
  incompatible with how opam works (functoria's approach used to not support
  "1.0~beta", "1.0-5", "v1.0"; and it used to handle "1.0" and "1.0.0"
  differently than opam).

## v3.0.1 (2019-10-21)

* Use `dune` to compile `config.ml` into an executable and run it.
  This replaces the use of `ocamlbuild` and dynlinking of `config.ml`
  (#176, @samoht)
  The new compilation scheme:
  - generates `dune`, `dune.config` and `dune.build` with sensible
    configuration values. Each file can be overwritten by the user,
    in that case functoria will detect it and will not remove during
    the clean step;
  - by default, `dune` just includes `dune.config` and `dune.build`;
  - by default, `dune.config` contains the rules to build `config.ml`
    into `config.exe`;
  - by default, `dune.build` is empty -- functoria users such as
    `mirage` can just overwrite that file with the rigth build rules.
* Invoke `opam list` with `--color=never` (#177, @ehmry)
* Use different exit codes in `Functoria_runtime.with_argv` (#180, @hannesm)

## v2.2.5 (2019-10-14)

* Functoria_runtime.with_argv now uses (#179, by @hannesm)
  - exit 63 when `Help or `Version is requested (used to exit with 0)
  - exit 64 when Term.eval returns with an error (used to raise an exception)

## v3.0.0 (2019-07-25)

* use `dune` to build `config.ml` (@TheLortex, #167)
* add the ability to use external libraries un `config.ml` via an optional
  `dune.config` file (@TheLortex, #167)
* Replace dynlink method by a 2-stage build (@TheLortex, #167)

## v2.2.4 (2019-05-27)

* fix app_info - executing "opam list --installed" (#170, by @hannesm)

## 2.2.3 (21/11/2018)

* fix support for pin-depends (#165, by @hannesm)

## 2.2.2 (16/11/2018)

* compute all transitive opam dependencies for info (#151, by @hannesm)
* support pin-depends in generated opam file (#163, by @hannesm)
* use dune as build system (#158, by @emillon)
* use Ptime for time printing (#160, by @emillon)
* inject global arguments into generated header (#159, by @emillon)
* add Functoria_key.add_to_context (#161, by @emillon)
* output opam2 files (#157, by @hannesm)

## 2.2.1 (01/08/2018)

* expand signatures manually for 4.07.0 support (#153, by @Drup)
* fix serialization of negative ints (#152, by @samoht)
* fix example in README (#144, by @samoht)

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
