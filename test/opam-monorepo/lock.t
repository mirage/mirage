  $ opam-monorepo lock --require-cross-compile
  ==> Using 1 locally scanned package as the target.
  ==> Found 8 opam dependencies for the target package.
  ==> Querying opam database for their metadata and Dune compatibility.
  ==> Calculating exact pins for each of them.
  ==> Wrote lockfile with 4 entries to $TESTCASE_ROOT/unikernel.opam.locked. You can now run opam monorepo pull to fetch their sources.

  $ cat unikernel.opam.locked
  opam-version: "2.0"
  synopsis: "opam-monorepo generated lockfile"
  maintainer: "opam-monorepo"
  depends: [
    "dune" {= "3.0.0"}
    "fmt" {= "0.9.0+dune" & ?vendor}
    "gmp" {= "6.2.9+dune" & ?vendor}
    "mirage-runtime" {= "4.0.0" & ?vendor}
    "ocaml-base-compiler" {= "4.13.1"}
    "ocaml-solo5" {= "0.8.0"}
    "solo5" {= "0.7.1"}
    "zarith" {= "1.12+dune+mirage" & ?vendor}
  ]
  pin-depends: [
    ["fmt.0.9.0+dune" "https://fmt.src"]
    ["gmp.6.2.9+dune" "https://gmp.src"]
    ["mirage-runtime.4.0.0" "https://mirage.src"]
    ["zarith.1.12+dune+mirage" "https://github.com/ocaml/zarith.git"]
  ]
  x-opam-monorepo-cli-args: ["--require-cross-compile"]
  x-opam-monorepo-duniverse-dirs: [
    ["https://fmt.src" "fmt"]
    ["https://github.com/ocaml/zarith.git" "zarith"]
    ["https://gmp.src" "gmp"]
    ["https://mirage.src" "mirage"]
  ]
  x-opam-monorepo-opam-provided: ["ocaml-solo5"]
  x-opam-monorepo-opam-repositories: [
    "file://$OPAM_MONOREPO_CWD/mini-opam-overlays"
    "file://$OPAM_MONOREPO_CWD/mini-opam-repository"
  ]
  x-opam-monorepo-root-packages: ["unikernel"]
  x-opam-monorepo-version: "0.3"
