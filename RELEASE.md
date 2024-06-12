## Tips on making a new release for MirageOS

This document aims to streamline the release process for
MirageOS. It's a living document, evolving with each
release. Contributions to enhance this guide are highly encouraged!

Since opam and CI systems use the latest version number released to
opam-repository, there's some caution needed and there'll be CI runs that are
not successful (since the CI doesn't yet know about your new version number).

## Before the release

- Check that `let min = "xxx" and max = "yyy" in` `lib/mirage.ml`
  is a range that contains the new release number.
- Rename `## Unreleased` to `## vXXX (YYY-MM-DD)` in CHANGES.md. Open a
  Pull Request (PR) with these changes to begin the release process.

and open a PR

### Version bounds

Mirage generates OCaml code, including device initialization code (usually
named "connect"). To avoid breakage of configured unikernels, package
dependencies are generated as well, with lower and upper bounds.

These bounds need to change:
- if there's a new release of a package (and the "connect" function didn't
  change), adjust the upper bound only,
- the code generation in mirage targets a new release of the package, adjust the
  lower bound and the upper bound.

### Release `mirage` and `mirage-runtime` to opam-repository

- Tag with `dune-release tag`
- Release to opam-repository with `dune-release`
- Backport packaging fixes in the repo (usually lower-bounds).
  Ideally this should be done before submitting to opam-repository but
  right now it's not super convenient to do so.

### Update `mirage-skeleton`

- Verify that all changes in the main branch are correctly ported to
  the dev branch and vice versa. This step ensures that both branches
  reflect the latest, stable changes.
- When complete, force-push dev to become the new main, solidifying
  these updates.
- If there are breaking changes, and mirage-skeleton unikernels needed
  adjustments, also adjust the first line in config.ml to reflect that:
  `(* mirage >= planned_release & < planned_release+1 *)`
- If there are no breaking changes, ensure that mirage-skeleton unikernels
  have a good upper bound `(* mirage < planned_release+1 *)`

### Update `mirage-www`

- Confirm that the MirageOS website builds successfully with the newly
  released version. To facilitate this, update the `mirageio.opam.template`
  pins to test against the new version ahead of the official release.
