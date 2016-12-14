## 1.2.0 (unreleased)

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