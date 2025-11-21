### v4.10.4 (2025-11-21)

- Refactor `right_tcpip_library` (#1622 @reynir, review by @hannesm)
- Correctly compare package pins when merging (#1623 @reynir, review by @hannesm)

### v4.10.3 (2025-10-27)

- Include output file extension in generated Makefile (#1619 @Firobe,
  fixes #1610)
- Allow solo5 0.10.0 (#1620 @hannesm)

### v4.10.2 (2025-10-03)

- Add a way to provide network and address to generic_stackv4v6 (removed in
  4.10.0, requested by @ansiwen in #1612, #1615)
- Upgrade to cmdliner 2.0.0 (#1614 @hannesm fixes #1602)
- Refactor open into qualified access in devices (#1613 @reynir)

### v4.10.1 (2025-09-09)

- Fix the generated dependencies on mirage-runtime to 4.10.*

### v4.10.0 (2025-09-08)

- Add unikraft targets (#1607 @fabbing @shym)
- Add a `?local_libs` parameter to allow local dune libs
  (#1609 @omegametabroccolo)
- Add a `--name` argument to each unikernel (`Mirage_runtime.name ()`),
  remove `monitor_hostname` (#1611 @hannesm)
- Use Git_net instead of Git_mirage (#1606 @dinosaure)
- Fix Mirage_runtime documentation headers, use correct Stop special comment
  (#1605 @reynir)
- Exclude buggy dune versions from testing (#1609 @reynir)
- Remove unused exports about ip stacks, ipv4_config, ipv6_config,
  socket_tcpv4v6, and socket_udpv4v6 (#1612 @hannesm)

### v4.9.0 (2025-03-04)

- Remove time, pclock, mclock, random from functor arguments
  Instead, use the linking trick in mirage-mtime, mirage-ptime, mirage-sleep
  libraries (#1599 @hannesm, discussion in #1513 and on the mailing list)
  This removes the default_time, default_monotonic_clock, default_posix_clock
  bindings, and allows "Mirage.register" to get ?sleep ?ptime ?mtime ?random
  passed optionally, following how ?argv is handled.

  This is a breaking change, and your unikernel likely needs to be updated. Have
  a look at https://github.com/mirage/mirage-skeleton/pull/407 for how our
  examples changed.

  As example, the hello-key unikernel diff:
```
  --- a/tutorial/hello-key/config.ml
  +++ b/tutorial/hello-key/config.ml
  @@ -2,5 +2,5 @@
   open Mirage
   
   let packages = [ package "duration" ]
  -let main = main ~packages "Unikernel.Hello" (time @-> job)
  -let () = register "hello-key" [ main $ default_time ]
  +let main = main ~packages "Unikernel" job
  +let () = register "hello-key" [ main ]

  --- a/tutorial/hello-key/unikernel.ml
  +++ b/tutorial/hello-key/unikernel.ml
  @@ -5,13 +5,12 @@ let hello =
     let doc = Arg.info ~doc:"How to say hello." [ "hello" ] in
     Mirage_runtime.register_arg Arg.(value & opt string "Hello World!" doc)
   
  -module Hello (Time : Mirage_time.S) = struct
  -  let start _time =
  +let start () =
     let rec loop = function
       | 0 -> Lwt.return_unit
       | n ->
         Logs.info (fun f -> f "%s" (hello ()));
  -          Time.sleep_ns (Duration.of_sec 1) >>= fun () -> loop (n - 1)
  +      Mirage_sleep.ns (Duration.of_sec 1) >>= fun () ->
  +      loop (n - 1)
     in
     loop 4
  -end
```
- Inject a unit argument to the start function if otherwise it would have
  no binding (discussed various times, including #1088 #873)

### v4.8.2 (2024-12-09)

- allow ocaml-solo5 1.x (@hannesm #1595)
- guide the user what to do next (#1592 @hannesm, fixes #921)
- revise syslog devices, add monitoring (#1591 @hannesm)
- add `ipv4_of_dhcp` device (#1593, @palainp)
- separate sections for DNS, happy-eyeballs, SSH, TLS, HTTP arguments in
  unikernel man pages (#1590 @hannesm, fixes #1587)

### v4.8.1 (2024-10-14)

* Mirage_runtime: add a top-level call to Printexc.record_backtrace
  The runtime argument --backtrace=true/false turns backtraces on and off in
  the running unikernel - but for the time where runtime arguments are not yet
  evaluated, we enable backtraces by default. The reason is that e.g.
  `Mirage_runtime.register_arg <my-cmdliner-term> ()` leads to an exception,
  and without backtrace this is not easy to spot where work needs to be done
  (#1584 @reynir)
* Document Mirage_runtime.register_arg, add parens around its return value
  (unit -> 'a) (#1580 #1585 @hannesm)
* Use OCaml runtime arguments from cmdliner-stdlib opam package
  (#1580 by @hannesm)
* Allow solo5 0.9 (#1583 by @hannesm)
* Mirage_runtime.logs: explain the log levels (#1581 by @reynir)
* Mirage.register: document ?src argument (#1578 by @reynir)

### v4.8.0 (2024-10-08)

- BREAKING avoid optional runtime arguments in devices (ip, git, happy-eyeballs,
  dns) (#1552 #1577 by @hannesm)
- update documentation (fixes #1560, #1571 #1576 by @hannesm)
- code cleanups, removed unused code (#1575 by @reynir)
- provide Mirage_runtime,register_arg, deprecate Mirage_runtime.register
  (#1574 by @hannesm)
- improve Mirage_runtime argument error message (#1573 by @hannesm)
- config.ml: make deprecation warnings non-errors (#1568 by @reynir)
- Use copy# for config.ml (#1570 by @reynir)
- generated opam file: avoid double slash (reported in #1563 by @reynir, fixed
  in #1564 by @reynir)
- BUGFIX: version check: log a warning if version is not parseable
  (reported in #1565 by @reynir, fixed in #1566 by @hannesm)

### v4.7.0 (2024-09-05)

- Adapt bounds for mirage-crypto-rng-mirage {>= "1.0.0"}, tls {>= "1.0.0"},
  conduit {>= "7.0.0"}, dns {>= "9.0.0"}, happy-eyeballs {>= "1.2.0"},
  tcpip {>= "8.2.0"}, mirage-qubes {>= "1.0.0"}, git {>= "3.17"}.
  The changes are in mirage-crypto to use string instead of cstruct.t
  (#1559 @hannesm)

### v4.6.1 (2024-08-08)

- BREAKING re-introduce `?deps` argument into `Mirage.main` function to be
  able to track how to compile some artifacts for an unikernel without emitting
  modules/functors used by these artifacts (#1555, @dinosaure) - this was
  removed in mirage 4.5.0, and is back now
- Allow tar 3.0.0 (#1557, @hannesm)

### v4.6.0 (2024-06-26)

- BREAKING adapt to happy-eyeballs and dns-client devices where dependencies
  got reversed (#1543 @dinosaure @hannesm)

  Adapting unikernels requires to notice that the generic_dns_client now
  takes a happy_eyeballs, and happy_eyeballs does no longer take a dns_client:

  -let dns_client = generic_dns_client ~nameservers stackv4v6
  -let happy_eyeballs = generic_happy_eyeballs stackv4v6 dns_client
  +let happy_eyeballs = generic_happy_eyeballs stackv4v6
  +let dns_client = generic_dns_client ~nameservers stackv4v6 happy_eyeballs

- allow mirage-qubes 0.10 series (#1548 @dinosaure)
- revise "job without arguments" to take runtime arguments into consideration
  (#1544 @hannesm)
- provide Mirage.ethif (alias to Mirage.etif - which is now deprecated)
  (#1546 @reynir @hannesm)
- update tests for cmdliner 1.3.0 (#1545 @hannesm)
- allow paf 0.6.0 (#1542 @hannesm)

### v4.5.1 (2024-05-17)

- BREAKING: remove `~name` parameter from Mirage.Runtime_args.create
  (#1541 @samoht, fixes #1532)
- BREAKING: remove `~name` parameter from Mirage.runtime_arg, and use a
  string (instead of a format string) as third parameter (#1541 @samoht)
- constrain the `start` function to `unit Lwt.t`. Previously, there was no
  restrictions, and lots of time was spent in debugging when a unikernel
  resulted in `unit Lwt.t Lwt.t` (@Julow #1524)
- revise man page sections and ordering: ARGUMENTS, OPTIONAL, NETWORK OPTIONS,
  DISK OPTIONS, LOG AND MONITORING OPTIONS, OCAML RUNTIME OPTIONS. Previously,
  the ARGUMENTS and OPTIONS were put later, and were hard to find. These are
  the sections where unikernel-specific arguments are put by default
  (#1531 @hannesm @reynir)
- add --net=host and --net=ocaml to reduce confusion. --net=host uses the
  TCP/IP socket stack, --net=ocaml the OCaml network stack (#1525 @hannesm)
- quote Runtime_arg.call (#1522 @Julow)
- documentation fixes (inline examples @Julow #1523, @hannesm #1537 (fixes
  #1512 reported by @reynir), Runtime_args.create #1541 @samoht)
- fix the build instructions of the generated opam file: since 4.5.0
  `mirage build` is no longer available, use `make "build"` (#1527 @hannesm)
- add RELEASE.md, a guide on how to cut a mirage release (#1519 @samoht)
- allow git 3.16 (#1536 @hannesm)
- use mirage-bootvar (using dune variant) instead of parse-argv and
  mirage-bootvar-xen, mirage-bootvar-solo5, mirage-bootvar-unix
  (#1533 @hannesm)
- BUGFIX: reset the lexer location before applying functors in generated code
  (#1539 @samoht, fixes #1520 @hannesm)
- BUGFIX: fix off-by-one locations for mirage/main.ml (#1540 @samoht, fixes
  #1528 @hannesm)

### v4.5.0 (2024-04-09)

- This release introduces a significant change in the Mirage tool by
  splitting the definition of command-line arguments used at
  configure-time and runtime. Command-line arguments used in the
  configure script (also called 'configuration keys' and defined in
  the `Key` module) are essential during the setup of module
  dependencies for the unikernel, allowing for a specialized
  production of a unikernel for a given target runtime environment. On
  the other hand, command-line arguments that the unikernel can use at
  runtime (defined in the `Runtime_arg` module) are useful for
  customizing deployments without altering the dependencies of the
  unikernels. (#1449, #1450, #1451, #1455 @samoht, review by @hannesm)

  * API changes:
    - There is no more `~stage` parameter for `Key.Arg.info`.
    - `Key` now define command-line arguments for the configuration tool.
    - There is a new module `Runtime_arg` to define command-line arguments
      for the unikernel.
    - As there are no more keys type `'Both`, users are now expected to create
      two separated keys in that case (one for configure-time, one for runtime)
      or decide if the key is useful at runtime of configure-time.

  * Intended use of configuration keys (values of type `'a key`):
    - Used to set up module dependencies of the unikernel, such as the
      target (hvt, xen, etc.) and whether to use DHCP or a fixed IP address.
    - Enable the production of specialized unikernels suitable for
      specific target runtime environments and dedicated network and
      storage stacks.
    - Similar keys will produce reproducible binaries to be uploaded to artifact
      repositories like Docker Hub or https://builds.robur.coop/.

  * Intended use of command-line runtime arguments (values of type
    `a runtime_arg`):
    - Allow users to customize deployments by changing device
      configuration, like IP addresses, secrets, block device names,
      etc., post downloading of binaries.
    - These keys don’t alter the dependencies of the unikernels.
    - A runtime keys is just a reference to a normal Cmdliner term.

  * `key_gen.ml` is not generated anymore, so users cannot refer to
    `Key_gen.<key_name>` directy.
    - Any runtime argument has to be declared (using `runtime_arg` and
      registered on the device (using `~runtime_args`). The value of that
      argument will then be passed  as an extra parameter of the `connect`
      function of that device.
    - Configuration keys are not available at runtime anymore. For
      instance, `Key_gen.target` has been removed.

* Code migration:
    ```ocaml
    (* in config.ml *)
    let key =
      let doc = Key.Arg.info ~doc:"A Key." ~stage:`Run [ "key" ] in
      Key.(create "key" Arg.(opt_all ~stage:`Run string doc))
    ```
    becomes:
    ```ocaml
    (* in unikernel.ml *)
    open Cmdliner

    let key =
      let doc = Arg.info ~doc:"A Key." [ "key" ] in
      Arg.(value & opt_all string [] doc)
    ```

    ```ocaml
    (* in unikernel.ml *)
    let start _ =
      let key = Key_gen.hello () in
      ...
    ```
    becomes:
    ```ocaml
    (* in config.ml *)
    let hello = runtime_arg ~pos:__POS__ "Unikernel.hello"
    let main = main ~runtime_args:[hello] ...
    ```

    ```
    (* in unikernel.ml *)
    let hello =
      let open Cmdliner in
      let doc = Arg.info ~doc:"How to say hello." [ "hello" ] in
      Arg.(value & opt string "Hello World!" doc)

    let start _ hello =
      ...
    ```

- bump minimal ocaml-solo5 version bound to 0.8.2 to avoid fast memory usage
  error (#1507, @palainp)
- BREAKING: the packages `functoria` and `functoria-runtime` are removed. The
  respectives libraries became `mirage.functoria` and `mirage-runtime.functoria`
  (#1509, @samoht)
- BREAKING: `Mirage.keys` is renamed to `Mirage.runtime_args` (#1506, @samoht)
- BREAKING: remove `Mirage.foreign`. Use `Mirage.main` instead (#1505, @samoht)
- BREAKING: `Mirage.main` does not take a `?extra_deps` parameter anymore
  (#1505, @samoht)
- BREAKING: the `Mirage.connect` functions passed to create devices
  (with `Mirage.impl`)  now take values of type `'a Mirage.code` instead
  of `string`. Value of type `code` are created using a new `Mirage.code`
  function, that takes `~pos:__POS__` as parameter. This is used to generate
  better locations in the generated code, leading to better error messages
  (#1504, @samoht)
- BUGFIX: fix `mirage describe` output (#1446 @samoht), add test (#1458 @samoht)
- Remove ipaddr from runtime (#1437 @samoht, #1465 @hannesm)
- BREAKING: `Mirage.register` no longer have `?packages` and `?keys` arguments
  (#1433, #1434 @hannesm)
- BREAKING: Remove deprecated bindings and types (#1461 @hannesm)
- BREAKING: Remove `mirage build` subcommand, use `dune build` in Makefile
  (#1404 @hannesm), put `--profile release` in Makefile instead of
  dune-workspace (#1470 @hannesm)
- Increase dune version to 2.9 in generated dune-project (#1443 @samoht)

### v4.4.2 (2024-02-13)

- Fix GC documentation (space overhead is 120 since best-fit is default)
  (#1491 @hannesm)
- use Option in printing of GC keys (#1491 @hannesm)
- allow to use git 3.15 (#1491 @hannesm)
- allow empty noop job (addresses an issue with #1428)
  solves an issue reported by @MisterDA in mirage/mirage-www#815
  (#1491 @hannesm)

### v4.4.1 (2023-11-20)

- Document exit codes in `--help` (#1485 @hannesm)
- Avoid dependency on environment variable (removing MIRAGE_LOGS #1484 @hannesm)
- BUGFIX: dune.config mark "dist" as data-only-dir to allow config.ml being
  compiled (#1475 @memst)
- Allow git 3.14 (#1474 @hannesm)
- Default to best-fit allocation (#1473 @hannesm)
- FEATURE: Add a key "--delay" to all unikernels (#1472 @hannesm, fixes #1468)
- Fix Unix target dune rule (add a deps) (#1469 @hannesm)
- Optionally pass tcp in direct_stackv4v6, static_ipv4v6, generic_stackv4v6
  (#1467 @hannesm)
- FEATURE: Support mirage version indication in first line of config.ml:
  (* mirage >= 2.3.4 & < 5.0.0 *) (#1466 @hannesm, fixes #1381)
- Use \033 instead of \e in generated Makefile (fixes the output on non-Linux
  systems #1464 @hannesm)
- Adapt to mirage-logs 2.0.0 (#1460 @hannesm)
- Allow version 0.8.0 of solo5 (#1432 #1490 @hannesm @palainp)

### v4.4.0 (2023-06-19)

- Fail configure if jobs without arguments are present
  (fixes #873 #1426, #1428 @hannesm)
- mirage-runtime & functoria-runtime: remove fmt dependency (#1417 @hannesm)
- Fix tests on macOS (#1425 @samoht)
- Adapt to happy-eyeballs 0.6.0 release (#1427 @hannesm)
- Adapt to logs-syslog 0.4.0 release (#1424 @hannesm)
- Adapt to docteur 0.0.6 release (#1419 @dinosaure)
- Upgrade tests to cmdliner 1.2.0 (#1418 @hannesm)
- Fail if jobs without arguments are registered (reported #873 @kit-ty-kate
  #1426 @reynir @PizieDust, fixed #1428 @hannesm and #1431 @reynir)
- Console is marked as deprecated (#1429 @hannesm)
- Tracing has been removed, since it was not used anymore and not supported with
  solo5-xen-pvh (#1430 @hannesm)

### v4.3.6 (2023-03-28)

- Allow paf 0.4 and 0.5 (#1414 @hannesm)
- Remove bytes dependency from functoria-runtime (#1411 @hannesm)
- Allow git-mirage 3.13 (#1412 @dinosaure @hannesm)

### v4.3.5 (2023-03-20)

#### Changed
- Remove OCaml dependency to allow OCaml 5 being chosen (#1409 @palainp)
- Disallow empty key names (#1407 @reynir)
- Allow tls-mirage 0.17 (#1405 @hannesm)
- Allow tcpip 8.0 (#1410 @hannesm)
- Fix typo in generated Makefile (#1406 @hannesm)

### v4.3.4 (2023-02-23)

#### Fixed

- Add -f <config> to Makefile output (#1394 @hannesm)

#### Added

- Add tar_kv_ro and tar_kv_rw (#1389 @reynir)

#### Changed

- Improved documentation of mirage.mli (#1390 #1391 @reynir)
- Deprecate Mirage.archive (use tar_kv_ro, #1389 @reynir)
- Removed deprecated device git_happy_eyeballs (#1388 @TaeminHa)
- Adapt bounds: mirage-crypto 0.11.0 (#1392 @hannesm) git-mirage 2.13.0
  (#1396 @hannesm) dns 7.0.0 tls 0.16.0 (#1399 @hannesm)
  mirage-block-ccm (#1400 @hannesm)
- mirage-runtime: conflict with ppxlib 0.29 (#1397 @hannesm)
- add upper bound to dune 3.7 until a release of chamelon with fixes lands (see
  https://github.com/mirage/mirage/pull/1401#issuecomment-1440762994)

### v4.3.3 (2023-01-30)

#### Fixed

- add (merlin) to the dune-workspace file -- this allows merlin to properly work
  with unikernels (#1385, fixes #1384 @TheLortex @hannesm)
- add "build" stanzas to packages that are supposed to be vendored (#1383,
  @Leonidas-from-XIV) for "opam-monorepo 0.3.5" compatibility

#### Changed

- raise upper bound for git to 3.12 (#1387 @dinosaure)

### v4.3.2 (2022-12-12)

#### Fixed

- use "printf" instead of "echo -e" in Makefiles for macOS support (#1370,
  @gridbugs)

#### Changed

- raise lower bound of solo5 to 0.7.5 (#1380 @dinosaure)
- remove "-warn-error -A" from generated dune file (for config) (#1379 @hannesm)

#### Added

- CCM device for block device encryption (#1364 @dinosaure)
- ALPN client and mimic device (#1376 @dinosaure)

### v4.3.1 (2022-10-25)

#### Fixed

- adapt to conduit 6.0.1 API (delay the parsing of the nameserver list)
  (#1362 #1369, @reynir @hannesm, fixes #1360)
- improve the generic_dns_client documentation (#1365, @dinosaure)
- upgrade to git 3.10.0 (#1366, @dinosaure)

#### Changed

- mirage-runtime: use Logs.level_of_string / level_to_string, avoid manual
  construction of Cmdliner.Arg.conv types (use the Cmdliner.Arg.conv function
  instead) (#1358, @hannesm)

#### Added

- functoria-runtime: provide argument_error exit code (#1361, @hannesm)
- add a http_server device using paf (#1367, @dinosaure)

### v4.3.0 (2022-09-26)

#### Fixed

- The chamelon format example invocation had the arguments in the wrong order
  (#1351, @hannesm)
- tar-mirage: allow the 2.x release series (#1352, @hannesm)
- Fix the separator for list and pair combinator (command-line arguments, #1354,
  @dinosaure, reported in #1349 #1348 by @rand00)
- Update references (hyperlinks) to erratique.ch documentation (#1343, @reynir)

#### Changed

- Allow more log levels (None / quiet) (#1275, @reynir, closes #1273 & #1274)
- Improve Functoria CLI: don't fail if context cache is invalid, handle
  situation when global arguments have a parse error (#1350, @TheLortex)
- Remove v4 & v6 stack, and other deprecated bindings (#1341, @hannesm)
- Remove FS remnants, and kv_ro of archive, and brittle shell scripts
  that used to generate FAT block storage devices (#1353, @hannesm)
- Update to OCamlFormat 0.23.0 (#1351, @dinosaure)

### v4.2.1 (2022-08-25)

#### Fixed

- In the generated opam file, also run "depext-lockfile" (#1342, @hannesm)

### v4.2.0 (2022-07-26)

#### Fixed

- Remove non-existing mirage-repo-add and mirage-repo-rm from PHONY in generated
  Makefile (#1332, @hannesm)
- Update deprecated references (#1337, @reynir)

#### Changed

- Prepare for reproducing unikernels with generated opam file (#1335, @hannesm)
  - split x-mirage-configure (mirage configure), x-mirage-pre-build
    (make lock pull), and build instructions in opam file
  - embed x-mirage-extra-repo (a list of opam repositories to use)
  - take relative paths up to git repository into account
  - include x-mirage-opam-lock-location (relative to git repository root)
- Adapt constraints for mirage-solo5 0.9.0 and mirage-xen 8.0.0 (ocaml-solo5
  0.8.1 with trim and improved memory metrics) (#1338, @hannesm, based on
  @palainp work)
- Require opam-monorepo 0.3.2 (#1332 #1334, @hannesm @dinosaure)
- Use OPAMVAR_monorepo instead of OPAMVAR_switch in generated opam file (#1332,
  @hannesm)
- Remove name from opam file (#1332, @hannesm)

### v4.1.1 (2022-04-05)

#### Fixed

- Update constraints on generated OPAM files (d21de15, @dinosaure)

### v4.1.0 (2022-05-02)

#### Changed

- Be able to make a docteur image with a relative path (@dinosaure, #1324)
- Update the project with `ocamlformat.0.21.0` (@gpetiot, @dinosaure, #1286)
- Upgrade the `mirage` tool with `opam-monorepo.0.3.0` and generate
  a single OPAM file (@TheLortex, @hannesm, @dinosaure, #1327)

  You should check the `opam-monorepo.0.3.0` release to get more details about
  updates and fixes.

#### Added

- Add `chamelon` device, a filesystem with `littlefs` (@dinosaure, @yomimono, #1300)
- Add `pair` combinator for MirageOS key (@dinosaure, #1328)

### v4.0.0 (2022-03-28)

#### Fixed

- use `--solo5-abi=xen` for qubes target (#1312, @hannesm)
- Support using a different filename than `config.ml` with `-f`
  (#1309, @dinosaure)
- Fix build with dune 3.0 (#1296, @dinosaure)
- Check that the package name respects opam conventions
  (#1287, #1304, @TheLortex)
- Allow to specify version of pinned packages (#1295, @Julow)

#### Changed

- Use the same compilation as dune (#1313, #1316, #1317, @samoht, @hannesm)
- Remove unused `--warn-errors` and `--debug` flags (#1320, @samoht)
- Remove the deprecated `--target=ukvm` (#1321, @hannesm)
- Require cmdliner 1.1 (#1289, @samoht, @dinosaure, @dbuenzli)
- Require opam 2.1 to use MirageOS (#1239, 1311, @hannesm)
- Require conduit 5.1 (#1297, @hannesm)
- Rename `ocaml-freestanding` to `ocaml-solo5`
  (#1314, @dinosaure, @samoht, @hannesm)

#### Added

- Add Key.opt_all to allows usage of an argument multiple times
  (#1292, #1301, @dinosaure, @Drup)
- Add Git devices (#1291, @dinosaure, @samoht, @hannesm, @yomimono)
- Add happy-eyeballs devices (#1307, @dinosaure, @hannesm)
- Add docteur device to manage read-only persistent key-value stores
  (#1298, @dinosaure, @samoht)
- Add tcpv4v6_of_stackv4v6 device (#1293, @dinosaure)
- Add int64 converter (#1305, @dinosaure)
- Add dns_client device (#1302, #1306, @dinosaure, @hannesm)

### v4.0.0~beta3 (2022-02-02)

- Lint constraints on few packages to split the world between MirageOS 3.0 and
  MirageOS 4.0 (#1280, @dinosaure)

### v4.0.0~beta2 (2022-01-31)

- Update the generated minimal constraint required for `mirage-runtime` as
  Opam considers `4.0.0~beta* < 4.0.0` (#1276, @dinosaure)

### v4.0.0~beta1 (2022-01-29)

Refactor build process to use [Dune](https://dune.build/) build system. The
motivation is to drop `ocamlbuild`-induced technical debt and to obtain
first-class support for _cross-compilation_. To learn more about how Dune is
able to perform cross-compilation, please refer to the
[documentation](https://dune.readthedocs.io/en/stable/cross-compilation.html).

Main changes:

* Two opam files are generated when running `mirage configure`:
  - `<unikernel>-switch.opam`: for dependencies that are meant to be installed
    in the user's opam switch. It comprises of build tools such as
    `ocaml-freestanding` for Solo5 targets.
  - `<unikernel>-monorepo.opam`: for unikernel dependencies, they are locally
    fetched to compose a _dune workspace_.

* Unikernel dependencies are fetched in the source project using the
  `opam-monorepo` tool. This tool reads the `<unikernel>-monorepo.opam` file and
  make use of the opam solver to compute the transitive dependency set, saves
  that as a _lockfile_, and fetch sources in the `duniverse/` subfolder.
  More info on the
  [Github repository](https://github.com/ocamllabs/opam-monorepo).

* The compilation scheme use `dune`'s concept of a _workspace_: it's a set of
  libraries that are built together using the same _context_. For each
  compilation target, the Mirage tool is able to generate a _context_ definition
  able to compile for that target. A _context_ is defined by an OCaml compiler
  (or cross-compiler) toolchain, as defined by `findlib`, it can be tuned with
  environment variables and custom flags for the OCaml or underlying C compiler.

* The usual workflow `mirage configure && make depends && mirage build` does
  not change. However, files are now generated in the `./mirage` directory
  (OPAM files, `main.ml`, `key_gen.ml` or `manifest.json`), and
  the final artefact is created in the `./dist` directory.

Breaking changes:

* Unikernel dependencies need to use `dune` as a build system. Other build
  systems can be sandboxed, but the recommended way is to switch to `dune`.
  Many packages not compiling with dune yet have been ported  and are available
  as an additional
  [opam repository](https://github.com/dune-universe/opam-overlays) overlay.
  In addition, a few packages not supporting cross-compilation have been fixed
  and are available in another
  [opam repository](https://github.com/dune-universe/mirage-opam-overlays)
  overlay. The mirage tool uses these two opam overlays by default. To only
  use the default packages provided by Opam,
  use `mirage configure --no-extra-repo`.
* `Functoria_runtime.info` and `Mirage_runtime.info` now list all the libraries
  that are statically linked against the unikernel. The `packages` field have
  been removed and the `libraries` field is now accurate and contains the
  versions computed by `dune-build-info`.

* Update the DSL to describe devices into the `config.ml`.  We don't use
  objects anymore, and we replace it with the usage of `Mirage.impl` that
  expects the same _fields_ as before.

### v3.10.8 (2021-12-17)

- Allow tcpip 7.0.0, arp 3.0.0, ethernet 3.0.0 (#1259 @hannesm)

### v3.10.7 (2021-12-09)

- Allow mirage-clock 4.0.0 (@hannesm #1256)
- Use "opam var prefix" instead of "opam config var prefix" (@hannesm)

### v3.10.6 (2021-10-20)

- Adapt to conduit 5.0.0 API (and dns 6.0.0) @hannesm #1246
- Avoid deprecated Fmt functions @hannesm #1246

### v3.10.5 (2021-10-09)

- Allow tls-mirage 0.14 and 0.15 series (@hannesm)

### v3.10.4 (2021-04-20)

- Allow mirage-crypto-rng-mirage 0.10 (@hannesm)

### v3.10.3 (2021-04-19)

- Adapt to conduit 4.0.0 and cohttp 4.0.0 (@dinosaure #1221)

### v3.10.2 (2021-03-30)

* Adapt to conduit 2.3 and cohttp 4.0 (@samoht @dinosaure #1209)
* Allow mirage-crypto-rng-mirage 0.9 (@hannesm #1218)
* Adapt to tcpip 6.1.0 release (the unix sublibrary is no longer needed)

### v3.10.1 (2020-12-04)

* Fix serialising of Mirage_key.Arg.ip_address: remove superfluous '.'
  character (#1205 @hannesm)

### v3.10.0 (2020-12-02)

IPv6 and dual (IPv4 and IPv6) stack support #1187

Since a long time, IPv6 code was around in our TCP/IP stack (thanks to @nojb
who developed it in 2014). Some months ago, @hannesm and @MagnusS got excited
to use it. After we managed to fix some bugs and add some test cases, and
writing more code to setup IPv6-only and dual stacks, we are eager to share
this support for MirageOS in a released version. We expect there to be bugs
lingering around, but duplicate address detection (neighbour solicitation and
advertisements) has been implemented, and (unless
"--accept-router-advertisement=false") router advertisements are decoded and
used to configure the IPv6 part of the stack. Configuring a static IPv6 address
is also possible (with "--ipv6=2001::42/64").

While at it, we unified the boot arguments between the different targets:
namely, on Unix (when using the socket stack), you can now pass
"--ipv4=127.0.0.1/24" to the same effect as the direct stack: only listen
on 127.0.0.1 (the subnet mask is ignored for the Unix socket stack).

A dual stack unikernel has "--ipv4-only=BOOL" and "--ipv6-only=BOOL" parameters,
so a unikernel binary could support both Internet Protocol versions, while the
operator can decide which protocol version to use.

Please also note that the default IPv4 network configuration no longer uses
10.0.0.1 as default gateway (since there was no way to unset the default
gateway #1147).

For unikernel developers, there are some API changes in the Mirage module
- New "v4v6" types for IP protocols and stacks
- The ipv6_config record was adjusted in the same fashion as the ipv4_config
  type: it is now a record of a network (V6.Prefix.t) and gateway (V6.t option)

Some parts of the Mirage_key module were unified as well:
- Arp.ip_address is available (for a dual Ipaddr.t)
- Arg.ipv6_address replaces Arg.ipv6 (for an Ipaddr.V6.t)
- Arg.ipv6 replaces Arg.ipv6_prefix (for a Ipaddr.V6.Prefix.t)
- V6.network and V6.gateway are available, mirroring the V4 submodule

If you're ready to experiment with the dual stack, here's a diff for our basic
network example (from mirage-skeleton/device-usage/network) replacing IPv4
with a dual stack:

```
diff --git a/device-usage/network/config.ml b/device-usage/network/config.ml
index c425edb..eabc9d6 100644
--- a/device-usage/network/config.ml
+++ b/device-usage/network/config.ml
@@ -4,9 +4,9 @@ let port =
   let doc = Key.Arg.info ~doc:"The TCP port on which to listen for incoming connections." ["port"] in
   Key.(create "port" Arg.(opt int 8080 doc))

-let main = foreign ~keys:[Key.abstract port] "Unikernel.Main" (stackv4 @-> job)
+let main = foreign ~keys:[Key.abstract port] "Unikernel.Main" (stackv4v6 @-> job)

-let stack = generic_stackv4 default_network
+let stack = generic_stackv4v6 default_network

 let () =
   register "network" [
diff --git a/device-usage/network/unikernel.ml b/device-usage/network/unikernel.ml
index 5d29111..1bf1228 100644
--- a/device-usage/network/unikernel.ml
+++ b/device-usage/network/unikernel.ml
@@ -1,19 +1,19 @@
 open Lwt.Infix

-module Main (S: Mirage_stack.V4) = struct
+module Main (S: Mirage_stack.V4V6) = struct

   let start s =
     let port = Key_gen.port () in
-    S.listen_tcpv4 s ~port (fun flow ->
-        let dst, dst_port = S.TCPV4.dst flow in
+    S.listen_tcp s ~port (fun flow ->
+        let dst, dst_port = S.TCP.dst flow in
         Logs.info (fun f -> f "new tcp connection from IP %s on port %d"
-                  (Ipaddr.V4.to_string dst) dst_port);
-        S.TCPV4.read flow >>= function
+                  (Ipaddr.to_string dst) dst_port);
+        S.TCP.read flow >>= function
         | Ok `Eof -> Logs.info (fun f -> f "Closing connection!"); Lwt.return_unit
-        | Error e -> Logs.warn (fun f -> f "Error reading data from established connection: %a" S.TCPV4.pp_error e); Lwt.return_unit
+        | Error e -> Logs.warn (fun f -> f "Error reading data from established connection: %a" S.TCP.pp_error e); Lwt.return_unit
         | Ok (`Data b) ->
           Logs.debug (fun f -> f "read: %d bytes:\n%s" (Cstruct.len b) (Cstruct.to_string b));
-          S.TCPV4.close flow
+          S.TCP.close flow
       );

     S.listen s
```

Other bug fixes include #1188 (in #1201) and adapt to charrua 1.3.0 and
arp 2.3.0 changes (#1199).

### v3.9.0 (2020-10-24)

The Xen backend is a minimal legacy-free re-write: Solo5 (since 0.6.6) provides
the low-level glue code, and ocaml-freestanding provides the OCaml runtime. The
PV-only Mini-OS implementation has been retired.

The only supported virtualization mode is now Xen PVH (version 2 or above),
supported since Xen version 4.10 or later (and Qubes OS 4.0).

The support for the ARM32 architecture on Xen has been removed.

Security posture improvements:

With the move to a Solo5 and ocaml-freestanding base MirageOS gains several
notable improvements to security posture for unikernels on Xen:

* Stack smashing protection is enabled unconditionally for all C code.
* W^X is enforced throughout, i.e. `.text` is read-execute, `.rodata` is
  read-only, non-executable and `.data`, heap and stack are read-write and
  non-executable.
* The memory allocator used by the OCaml runtime is now dlmalloc (provided by
  ocaml-freestanding), which is a big improvement over the Mini-OS malloc, and
  incorporates features such as heap canaries.

Interface changes:

* With the rewrite of the Xen core platform stack, several Xen-specific APIs
  have changed in incompatible ways; unikernels may need to be updated. Please
  refer to the mirage-xen v6.0.0 [change
  log](https://github.com/mirage/mirage-xen/releases/tag/v6.0.0) for a list of
  interfaces that have changed along with their replacements.

Other changes:

* OCaml 4.08 is the minimum supported version.
* A dummy `dev-repo` field is emitted for the generated opam file.
* .xe files are no longer generated.
* Previous versions of MirageOS would strip boot parameters on Xen, since Qubes
  OS 3.x added arguments that could not be interpreted by our command line
  parser. Since Qubes OS 4.0 this is no longer an issue, and MirageOS no longer
  strips any boot parameters. You may need to execute
  `qvm-prefs qube-name kernelopts ''`.

Acknowledgements:

* Thanks to Roger Pau Monné, Andrew Cooper and other core Xen developers for
  help with understanding the specifics of how PVHv2 works, and how to write an
  implementation from scratch.
* Thanks to Marek Marczykowski-Górecki for help with the Qubes OS specifics, and
  for forward-porting some missing parts of PVHv2 to Qubes OS version of Xen.
* Thanks to @palainp on Github for help with testing on Qubes OS.

### v3.8.1 (2020-09-22)

* OCaml runtime parameters (OCAMLPARAM) are exposed as boot and configure
  arguments. This allows e.g. to switch to the best-fit garbage collection
  strategy (#1180 @hannesm)

### v3.8.0 (2020-06-22)

* Emit type=pv in xl (instead of builder=linux), as required by xen 4.10+ (#1166 by @djs55)
* adapt to ipaddr 5.0.0, tcpip 5.0.0, mirage-crypto 0.8 (#1172 @hannesm)

### v3.7.7 (2020-05-18)

* handle errors from Bos.OS.Cmd.run_out
* use PREFIX if defined (no need to call "opam config var prefix")
* adapt to conduit 2.2.0, tls 0.12, mirage-crypto 0.7.0 changes

### v3.7.6 (2020-03-18)

* fix conduit with 3.7.5 changes (#1086 / #1087, @hannesm)

### v3.7.5 (2020-03-15)

* use mirage-crypto (and mirage-crypto-entropy) instead of nocrypto, also
  tls-mirage and up-to-date conduit (#1068 / #1079, @hannesm @samoht)

### v3.7.4 (2019-12-20)

* use `git rev-parse --abbrev-ref HEAD` instead of `git branch --show-current`
  for emitting branch information into the opam file. The latter is only
  available in git 2.22 or later, while the former seems to be supported by
  old git releases. (#1024, @hannesm)

### v3.7.3 (2019-12-17)

* `mirage configure` now emits build and install steps into generated opam file
  this allows to use `opam install .` to actually install a unikernel.
  (#1022 @hannesm)
* refactor configure, build and link step into separate modules (#1017 @dinosaure)

### v3.7.2 (2019-11-18)

* adjust fat-filesystem constraints to >= 0.14 && < 0.15 (#1015, @hannesm)

### v3.7.1 (2019-11-03)

* clean opam files when `mirage configure` is executed (#1013 @dinosaure)
* deprecate mirage-types and mirage-types-lwt (#1006 @hannesm)
* remove abstraction over 'type 'a io' and 'buffer', remove mirage-*-lwt packages (#1006 @hannesm)
* unify targets in respect to hooks (Mirage_runtime provides the hooks and registration)
* unify targets in respect to error handling (no toplevel try .. with installed anymore, mirage-unix does no longer ignore all errors)

### v3.7.0 (2019-11-01)

* mirage-runtime: provide at_enter_iter/at_exit_iter/at_exit hooks for the event loop (#1010, @samoht @dinosaure @hannesm)
* call `exit 0` after the Lwt event loop returned (to run at_exit handlers in freestanding environments) (#1011, @hannesm)
* NOTE: this release only contains the mirage-runtime opam package to unblock other releases, there'll be a 3.7.1 soon

### v3.6.0 (2019-10-02)

* solo5 0.6 support for multiple devices (#993, by @mato)
  please read https://github.com/Solo5/solo5/blob/v0.6.2/CHANGES.md for detailed changes
  observable mirage changes:
  - new target `-t spt` for sandboxed processed tender (seccomp on Linux)
  - new functions Mirage_key.is_solo5 and Mirage_key.is_xen, analogue to Mirage_key.is_unix
* respect verbosity when calling `ocamlbuild` -- verbose if log level is info or debug (#999, by @mato)

### v3.5.2 (2019-08-22)

* Adapt to conduit 2.0.0 release, including dns 4.0.0 (#996, by @hannesm)
* Adjust mirage-xen constraints to < 5.0.0 (#995, by @reynir)

### v3.5.1 (2019-07-11)

* Adapt to new tracing API (#985, by @talex5)
* Remove stubs for qrexec and qubes gui (qubes 3 is end of life, qubes 4 makes it configurable) (#984, by @linse & @yomimono)
* Update mirage-logs and charrua-client-mirage version constraints (#982, by @hannesm)
* Remove unused dockerfile, travis updates (#982 #990, by @hannesm)

### v3.5.0 (2019-03-03)

* Rename Mirage_impl_kv_ro to Mirage_impl_kv, and introduce `rw` (#975, by @hannesm)
* Adapt to mirage-kv 2.0.0 changes (#975, by @hannesm)
* Adapt to mirage-protocols and mirag-net 2.0.0 changes (#972, by @hannesm)
* mirage-types-lwt: remove unneeded io-page dependency (#971, by @hannesm)
* Fix regression introduced in 3.4.0 that "-l *:debug" did no longer work (#970, by @hannesm)
* Adjust various upper bounds (mirage-unix, cohttp-mirage, mirage-bootvar-xen) (#967, by @hannesm)

### v3.4.1 (2019-02-05)

* Provide a httpaf_server device, and a cohttp_server device (#955, by @anmonteiro)
* There can only be a single prng device in a unikernel, due to entropy
  harvesting setup (#959, by @hannesm)
* Cleanup zarith-freestanding / gmp-freestanding dependencies (#964, by @hannesm)
* ethernet is now a separate package (#965, by @hannesm)
* arp now uses the mirage/arp repository by default, the tcpip.arpv4
  implementation was removed in tcpip 3.7.0 (#965, by @hannesm)

### v3.4.0 (2019-01-11)

* use ipaddr 3.0 without s-expression dependency (#956, by @hannesm)
* use mirage-clock 2.x and tcpip 3.6.x libraries (#960, #962, by @hannesm)
* default to socket stack on unix and macos (#958, by @hannesm)
* use String.split_on_char in mirage-runtime to avoid astring dependency (#957, by @hannesm)
* add build-dependency on mirage to each unikernel (#953, by @hannesm)

### 3.3.1 (2018-11-21)

* fix regression: --yes was not passed to opam in 3.3.0 (#950, by @hannesm)

### 3.3.0 (2018-11-18)

New target: (via solo5) Genode:
"Genode is a free and open-source operating system framework consisting
of a microkernel abstraction layer and a collection of userspace components. The
framework is notable as one of the few open-source operating systems not derived
from a proprietary OS, such as Unix. The characteristic design philosophy is
that a small trusted computing base is of primary concern in a security oriented
OS." (from wikipedia, more at https://genode.org/ #942, by @ehmry)

User-visible changes
* use mirage-bootvar-unix instead of OS.Env.argv
  (deprecated since mirage-{xen,unix,os-shim}.3.1.0, mirage-solo5.0.5.0) on unix
  (#931, by @hannesm)

  WARNING: this leads to a different semantics for argument passing on Unix:
  all arguments are concatenated (using a whitespace " " as separator), and
  split on the whitespace character again (by parse-argv). This is coherent
  with all other backends, but the whitespace in "--hello=foo bar" needs to
  be escaped now.

* mirage now generates upper bounds for hard-coded packages that are used in
  generated code. When we now break the API, unikernels which are configured with
  an earlier version won't accept the new release of the dependency. This means
  API breakage is much smoother for us, apart from that we now track version
  numbers in the mirage utility. The following rules were applied for upper bounds:
  - if version < 1.0.0 then ~min:"a.b.c" ~max:"a.(b+1).0"
  - if version > 1.0.0 then ~min:"a.b.c" ~max:"(a+1).0.0"`
  - exceptions: tcpip (~min:"3.5.0" ~max:"3.6.0"), mirage-block-ramdisk (unconstrained)

  WARNING: Please be careful when release any of the referenced libraries by
  taking care of appropriate version numbering.
  (initial version in #855 by @avsm, final #946 by @hannesm)

* since functoria.2.2.2, the "package" function (used in unikernel configuration)
  is extended with the labeled argument ~pin that receives a string (e.g.
  ~pin:"git+https://github.com/mirage-random/mirage-random.git"), and is embedded
  into the generated opam file as [pin-depends](https://opam.ocaml.org/doc/Manual.html#opamfield-pin-depends)

* mirage-random-stdlib is now used for default_random instead of mirage-random
  (which since 1.2.0 no longer bundles the stdlib Random
  module). mirage-random-stdlib is not cryptographically secure, but "a
  lagged-Fibonacci F(55, 24, +) with a modified addition function to enhance the
  mixing of bits.", which is now seeded using mirage-entropy. If you configure
  your unikernel with "mirage configure --prng fortuna" (since mirage 3.0.0), a
  cryptographically secure PRNG will be used (read more at
  https://mirage.io/blog/mirage-entropy)

* mirage now revived its command-line "--no-depext", which removes the call to
  "opam depext" in the depend and depends target of the generated Makefile
  (#948, by @hannesm)

* make depend no longer uses opam pin for opam install --deps-only (#948, by @hannesm)

* remove unused io_page configuration (initial discussion in #855, #940, by @hannesm)

* charrua-client requires a Mirage_random interface since 0.11.0 (#938, by @hannesm)

* split implementations into separate modules (#933, by @emillon)

* improved opam2 support (declare ocaml as dependency #926)

* switch build system to dune (#927, by @emillon)

* block device writes has been fixed in mirage-solo5.0.5.0

### 3.2.0 (2018-09-23)

* adapt to solo5 0.4.0 changes (#924, by @mato)
Upgrading from Mirage 3.1.x or earlier

Due to conflicting packages, opam will not upgrade mirage to version 3.2.0 or newer if a version of mirage-solo5 older than 0.4.0 is installed in the switch. To perform the upgrade you must run `opam upgrade mirage` explicitly.

Changes required to rebuild and run ukvm unikernels

As of Solo5 0.4.0, the ukvm target has been renamed to hvt. If you are working out of an existing, dirty, source tree, you should initially run:

```
mirage configure -t hvt
mirage clean
mirage configure -t hvt
```

and then proceed as normal. If you are working with a clean source tree, then simply configuring with the new hvt target is sufficient:

`mirage configure -t hvt`

Note that the build products have changed:

The unikernel binary is now named `<unikernel>.hvt`,
the `ukvm-bin` binary is now named `solo5-hvt`.

* adapt to mirage-protocols, mirage-stack, tcpip changes (#920, by @hannesm)

This is a breaking change: mirage 3.2.0 requires mirage-protocols 1.4.0, mirage-stack 1.3.0, and tcpip 3.5.0 to work (charru-client-mirage 0.10 and mirage-qubes-ipv4 0.6 are adapted to the changes).  An older mirage won't be able to use these new libraries correctly.  Conflicts were introduced in the opam-repository.

In more detail,  direct and socket stack initialisation changed, which is automatically generated by the mirage tool for each unikernel (as part of `main.ml`).  A record was built up, which is no longer needed.

Several unneeded type aliases were removed:
  `netif` from Mirage_protocols.ETHIF
  `ethif` and `prefix` from Mirage_protocols.IP
  `ip` from Mirage_protocols.{UDP,TCP}
  `netif` and `'netif config` from Mirage_stack.V4
  `'netif stackv4_config` and `socket_stack_config` in Mirage_stack

* squash unnecessary warning from `mirage build` (#916, by @mato)

### 3.1.1 (2018-08-01)

* for the unix target, add `-tags thread`, as done for the mac osx target (#861,
  suggested by @cfcs)
* bump minimum mirage-solo5* and solo5-kernel* to 0.3.0 (#914, by @hannesm, as
  suggested by @mato)
* use the exposed signature in functoria for Key modules (#912, by @Drup)
* add ?group param to all generic devices (#913, by @samoht)

### 3.1.0 (2018-06-20)

* solo5 v0.3.0 support (#906, by @mato @kensan @hannesm):
  The major new user-visible features for the Solo5 backends are:
    ukvm: Now runs natively on FreeBSD vmm and OpenBSD vmm.
    ukvm: ARM64 support.
    muen: New target, for the Muen Separation Kernel.
    ukvm: Improved and documented support for debugging Solo5-based unikernels.
* generate libvirt.xml for virtio target (#903, by @bramford)
* don't make xen config documents for target qubes (#895, by @yomimono)
* use a path pin when making depends (#891, by @yomimono)
* move block registration to `configure` section (#892, by @yomimono)
* allow to directly specifying xenstore ids (#879, by @yomimono)

### 3.0.8 (2017-12-19)

* when passing block devices to `xen`, pass the raw filename rather than trying to infer the xenstore ID (#874, by @yomimono)
* make homepage in opam files consistent (#872, by @djs55)

### 3.0.7 (2017-11-24)

* the released version of `cohttp-mirage` is `1.0.0` (not `3.0.0`)
  (#870 by @hannesm)

### 3.0.6 (2017-11-16)

* remove macOS < yosemite support (#860 by @hannesm)
* rename `mirage-http` to `cohttp-mirage` (#863 by @djs55)
  See [mirage/ocaml-cohttp#572]
* opam: require OCaml 4.04.2+ (#867 by @hannesm)

### 3.0.5 (2017-08-08)

* Allow runtime configuration of syslog via config keys `--syslog`,
  `--syslog-port` and `--syslog-hostname` (#853 via @hannesm).
* Switch build of tool and libraries to Jbuilder (by @samoht)
* Fix a warning when connecting to a ramdisk device (#837 by @g2p)
* Fix reference to tar library when using `--kv-ro archive` (#848 by @mor1)
* Adapt to latest functoria API (#849 by @samoht)

* Add a `--gdb` argument for ukvm targets so that debuggers can be attached easily.
  This allows `mirage configure --gdb -t ukvm` to work (@ricarkol in #847).

* Adapt to latest functoria (#849 by @samoht)
* Adapt to latest charrua, tcpip (#854 by @yomimono)
* Switch to jbuilder (#850 by @samoht)

Packaging updates for latest opam repository:
* ARP is compatible with MirageOS3 since 0.2.0 (#851 by @hannesm)


### 3.0.4 (2017-06-15)
* add a --block configure flag for picking ramdisk or file-backed disk
* add lower bounds on packages
* fallback to system `$PKG_CONFIG_PATH`
* update for mirage-qubes-ipv4

### 3.0.2 (2017-03-15)

* restore ocamlbuild colors when `TERM <> dumb && Unix.isatty stdout` (#814, by @hannesm)

### 3.0.1 (2017-03-14)

* remove "-color always" from ocamlbuild invocation (bugfix for some scripts interpreting build output) (#811, by @hannesm)
* provide a "random" module argument when invoking IPv6.Make (compat with tcpip 3.1.0) (#801, by @hannesm)
* add a "depends" target to the generated Makefile (controversial and may be removed) (#805, by @yomimono)
* allow qubesdb to be requested in config.ml when the target is xen (#807, by @talex5)

### 3.0.0 (2017-02-23)

* rename module types modules: V1 -> Mirage_types, V1_LWT -> Mirage_types_lwt (#766, by @yomimono, @samoht, and @hannesm)
* split type signatures and error printers into separate libraries (#755, #753, #752, #751, #764, and several others, by @samoht and @yomimono)
* use mirage-fs instead of ocaml-fat to transform FS into KV_RO (#756, by @samoht)
* changes to simplify choosing an alternate ARP implementation (#750, by @hannesm)
* add configurators for syslog reporter (#749, by @hannesm)
* filter incoming boot-time arguments for all Xen backends, not just QubesOS (#746, by @yomimono)
* give mirage-types-lwt its own library, instead of a mirage-types sublibrary called lwt (#735, by @hannesm)
* remove `format` function and `Format_unknown` error from FS module type (#733, by @djs55)
* ocamlify FAT name (#723 by @yomimono)
* remove type `error` from DEVICE module type (#728, by @hannesm)
* UDP requires random for source port randomization (#726 by @hannesm)
* drop "mir-" prefix from generated binaries (#725 by @hannesm)
* BLOCK and FS uses result types (#705 by @yomimono)
* depext fixes (#718 by @mato)
* workflow changes: separate configure, depend, build phases, generate opam file during configure (#703, #711 by @hannesm)
* tap0 is now default_network (#715, #719 by @yomimono, @mato)
* ARP uses result types (#711 by @yomimono)
* ipv4 key (instead of separate ip and netmask) (#707, #709 by @yomimono)
* CHANNEL uses result types (#702 by @avsm)
* no custom myocamlbuild.ml, was needed for OCaml 4.00 (#693 by @hannesm)
* revert custom ld via pkg-config (#692 by @hannesm)
* result types for FLOW and other network components (#690 by @yomimono)
* removed `is_xen` key (#682, by @hannesm)
* mirage-clock-xen is now mirage-clock-freestanding (#684, by @mato)
* mirage-runtime is a separate opam package providing common functionality (#681, #615 by @hannesm)
* add `qubes` target for making Xen unikernels which boot & configure themselves correctly on QubesOS. (#553, by @yomimono)
* revised V1.CONSOLE interface: removed log, renamed log_s to log (#667, by @hannesm)
* remove Str module from OCaml runtime (#663, in ocaml-freestanding and mirage-xen-ocaml, by @hannesm)
* new configuration time keyword: prng to select the default prng (#611, by @hannesm)
* fail early if tracing is attempted with Solo5 (#657, by @yomimono)
* refactor ipv4, stackv4, and dhcp handling (#643, by @yomimono)
* create xen-related helper files only when the target is xen (#639, by @hannesm)
* improvements to nocrypto handling (#636, by @pqwy)
* disable warning #42 in generated code for unikernels (#633, by @hannesm)
* V1.NETWORK functions return a Result.t rather than polyvars indicating success or errors (#615, by @hannesm)
* remove GNUisms and unnecessary artifacts from build (#623, #627, by @mato and @hannesm)
* remove type `id` from `DEVICE` module type. (#612, by @yomimono and @talex5)
* revise the RANDOM signature to provide n random bytes; provide nocrypto_random and stdlib_random (#551 and #610, by @hannesm)
* expose `direct` as an option for `kv_ro`.  (#607, by @mor1)
* require a `mem` function in KV_RO, and add `Failure` error variant (#606, by @yomimono)
* `connect` functions are no longer expected to return polyvars, but rather to raise exceptions if `connect` fails and return the value directly. (#602, by @hannesm)
* new documentation using `odig` (#591, #593, #594, #597, #598, #599, #600, and more, by @avsm)
* change build system to `topkg` from `oasis`. (#558, #590, #654, #673, by @avsm, @samoht, @hannesm, @dbuenzli)
* express io-page dependency of crunch. (#585, by @yomimono and @mato)
* deprecate the CLOCK module type in favor of PCLOCK (POSIX clock) and
  MCLOCK (a monotonically increasing counter of elapsed nanoseconds).
  (#548 and #579, by @mattgray and @yomimono)
* emit an ocamlfind predicate that matches the target, reducing the
  amount of duplication by target required of library authors
  (#568, by @pqwy)
* implement an `is_unix` key (#575, by @mato)
* use an int64 representing nanoseconds as the argument for `TIME.sleep`,
  instead of a float representing seconds. (#547, by @hannesm)
* expose new targets `virtio` and `ukvm` via the `solo5` project. (#565,
  by @djwillia, @mato, and @hannesm).
* remove users of `base_context`, which includes command-line arguments `--unix`
  and `--xen`, and `config.ml` functions `add_to_ocamlfind_libraries` and
  `add_to_opam_packages`.  As a side effect, fix a long-standing error message
  bug when invoking `mirage` against a `config.ml` that does not build.
  (#560, by @yomimono)
* link `libgcc.a` only on ARM & other build improvements (#544, by @hannesm)
* allow users to use `crunch` on unix with `kv_ro`; clean up crunch .mlis on
  clean (#556, by @yomimono)
* remove console arguments to network functors (#554, by @talex5 and @yomimono)
* standardize ip source and destination argument names as `src` and `dst`, and
  source and destination ports as `src_port` and `dst_port` (#546, by @yomimono)
* a large number of documentation improvements (#549, by @djs55)
* require `pseudoheader` function for IP module types. (#541, by @yomimono)
* always build with `ocamlbuild -r`, to avoid repetitive failure message
  (#537, by @talex5)

### 2.9.1 (2016-07-20)

* Warn users of command-line arguments `--unix` and `--xen` that support for
  these will soon be dropped.  Instead, use `-t unix` and `-t xen` respectively.
  (see https://github.com/mirage/mirage-www/pull/475#issuecomment-233802501)
  (#561, by @yomimono)
* Warn users of functions `add_to_opam_packages p` and
  `add_to_ocamlfind_libraries l` that support for these will soon be dropped.
  Instead, use `register ~libraries:l` and `register:~packages:p`
  respectively. (#561, by @yomimono).

### 2.9.0 (2016-04-29)

* Add logging support. A new `reporter` parameter to `register` is now
  available. This parameter defines how to configure the log reporter,
  using `Logs` and `Mirage_logs`. Log reporters can also be configured
  at configuration AND runtime using on the new `-l` or `--logs`
  command-line argument.  (#534, by @samoht, @talex5 and @Drup)
* Allow to disable command-line parsing at runtime. There is a new
  `argv` parameter to the `register` function to allow to pass custom
  command-line argument parsing devices.  Use `register ~argv:no_argv`
  to disable command-line argument parsing. (#493, by @samoht and @Drup)

### 2.8.0 (2016-04-04)

* Define an ICMP and ICMPV4 module type. ICMPV4 is included in, and
  surfaced by, the STACKV4 module type. The previous default behavior
  of the IPv4 module with respect to ICMP is preserved by STACKV4 and
  the tcpip_stack_direct function provided by mirage. (#523, by
  @yomimono)
* Explicitly require OCaml compiler version 4.02.3 in opam files for
  mirage-types and mirage.

### 2.7.3 (2016-03-20)

* Fix another regression introduced in 2.7.1 which enable
  `-warn-error` by default. This is now controlled by a
  `--warn-error` flag on `mirage configure`. Currently it's
  default value is [false] but this might change in future
  versions (#520)

### 2.7.2 (2016-03-20)

* Fix regression introduced in 2.7.1 which truncates the ouput of
  `opam install` and breaks `opam depext` (#519, by @samoht)

### 2.7.1 (2016-03-17)

* Improve the Dockerfile (#507, by @avsm)
* Use Astring (by @samoht)
* Clean-up dependencies automatically added by the tool
  - do not require `lwt.syntax`, `cstruct.syntax` and `sexplib`, which
    should make the default unikernels camlp4-free (#510, #515 by @samoht)
  - always require `mirage-platform` (#512, by @talex5)
  - ensure that `mirage-types` and `mirage-types-lwt` are installed
* Turn on more warnings and enable "warning as errors".
* Check that the OCaml compiler is at least 4.02.3 (by @samoht)

### 2.7.0 (2016-02-17)

The mirage tool is now based on functoria. (#441 #450, by @drup @samoht)
See https://mirage.io/blog/introducing-functoria for full details.

* Command line interface: The config file must be passed with the -f option
  (instead of being just an argument).
* Two new generic combinators are available, generic_stack and generic_kv_ro.
* `get_mode` is deprecated. You should use keys instead. And in particular
  `Key.target` and `Key.is_xen`.
* `add_to_ocamlfind_libraries` and `add_to_opam_packages` are deprecated. Both
  the `foreign` and the `register` functions now accept the `~libraries` and
  `~packages` arguments to specify library dependencies.

* If you were using `tls` without the conduit combinator, you will be
  greeted during configuration by a message like this:
  ```
The "nocrypto" library is loaded but entropy is not enabled!
Please enable the entropy by adding a dependency to the nocrypto device.
You can do so by adding ~deps:[abstract nocrypto] to the arguments of Mirage.foreign.
  ```
  Data dependencies (such as entropy initialization) are now explicit.
  In order to fix this, you need to declare the dependency like so:
  ```ocaml
open Mirage

let my_functor =
  let deps = [abstract nocrypto] in
  foreign ~deps "My_Functor" (foo @-> bar)
  ```
  `My_functor.start` will now take an extra argument for each
  dependencies. In the case of nocrypto, this is `()`.

* Remove `nat-script.sh` from the scripts directory, to be available
  as an external script.

### 2.6.1 (2015-09-08)

* Xen: improve the .xl file generation. We now have
  - `name.xl`: this has sensible defaults for everything including the
    network bridges and should "just work" if used on the build box
  - `name.xl.in`: this has all the settings needed to boot (e.g. presence of
    block and network devices) but all the environmental dependencies are
    represented by easily-substitutable variables. This file is intended for
    production use: simply replace the variables for the paths, bridges, memory
    sizes etc. and run `xl create` as before.

### 2.6.0 (2015-07-28)

* Better ARP support. This needs `mirage-tcpip.2.6.0` (#419, by @yomimono)
  - [mirage-types] Remove `V1.IPV4.input_arp`
  - [mirage-types] Expose `V1.ARP` and `V1_LWT.ARP`
  - Expose a `Mirage.arp` combinator
* Provide noop configuration for default_time (#435, by @yomimono)
* Add `Mirage.archive` and `Mirage.archive_of_files` to support attaching files
  via a read-only tar-formatted BLOCK (#432, by @djs55)
* Add a .merlin file (#428, by @Drup)

### 2.5.1 (2015-07-17)

* [mirage-types] Expose `V1_LWT.FS.page_aligned_buffer = Cstruct.t`

### 2.5.0 (2015-06-10)

* Change the type of the `Mirage.http_server` combinator. The first argument
  (the conduit server configuration) is removed and should now be provided
  at compile-time in `unikernel.ml` instead of configuration-time in
  `config.ml`:

    ```ocaml
(* [config.ml] *)
(* in 2.4 *) let http = http_server (`TCP (`Port 80)) conduit
(* in 2.5 *) let http = http_server conduit

(* [unikernel.ml] *)
let start http =
(* in 2.4 *) http (S.make ~conn_closed ~callback ())
(* in 2.5 *) http (`TCP 80) (S.make ~conn_closed ~callback ())
    ```

* Change the type of the `Mirage.conduit_direct` combinator.
  Previously, it took an optional `vchan` implementation, an optional
  `tls` immplementation and an optional `stackv4` implemenation. Now,
  it simply takes a `stackv4` implementation and a boolean to enable
  or disable the `tls` stack. Users who want to continue to use
  `vchan` with `conduit` should now use the `Vchan` functors inside
  `unikernel.ml` instead of the combinators in `config.ml`. To
  enable the TLS stack:

    ```ocaml
(* [config.ml] *)
let conduit = conduit_direct ~tls:true (stack default_console)

(* [unikernel.ml] *)
module Main (C: Conduit_mirage.S): struct
  let start conduit =
    C.listen conduit (`TLS (tls_config, `TCP 443)) callback
end
    ```

* [types] Remove `V1.ENTROPY` and `V1_LWT.ENTROPY`. The entropy is now
  handled directly by `nocrypto.0.4.0` and the mirage-tool is only responsible to
  call the `Nocrypto_entropy_{mode}.initialize` function.

* Remove `Mirage.vchan`, `Mirage.vchan_localhost`, `Mirage.vchan_xen` and
  `Mirage.vchan_default`. Vchan users need to adapt their code to directly
  use the `Vchan` functors instead of relying on the combinators.
* Remove `Mirage.conduit_client` and `Mirage.conduit_server` types.
* Fix misleading "Compiling for target" messages in `mirage build`
  (#408 by @lnmx)
* Add `--no-depext` to disable the automatic installation of opam depexts (#402)
* Support `@name/file` findlib's extended name syntax in `xen_linkopts` fields.
  `@name` is expanded to `%{lib}%/name`
* Modernize the Travis CI scripts

### 2.4.0 (2015-05-05)

* Support `mirage-http.2.2.0`
* Support `conduit.0.8.0`
* Support `tcpip.2.4.0`
* Add time and clock parameters to IPv4 (#362, patch from @yomimono)
* Support for `ocaml-tls` 0.4.0.
* Conduit now takes an optional TLS argument, allowing servers to support
  encryption. (#347)
* Add the ability to specify `Makefile.user` to extend the generated
  `Makefile`. Also `all`, `build` and `clean` are now extensible make
  targets.
* Remove the `mirage run` command (#379)
* Call `opam depext` when configuring (#373)
* Add opam files for `mirage` and `mirage-types` packages
* Fix `mirage --version` (#374)
* Add a `update-doc` target to the Makefile to easily update the online
  documentation at http://mirage.github.io/mirage/

### 2.3.0 (2015-03-10)

* Remove the `IO_PAGE` module type from `V1`. This has now moved into the
  `io-page` pacakge (#356)
* Remove `DEVICE.connect` from the `V1` module types.  When a module is
  functorised over a `DEVICE` it should only have the ability to
  *use* devices it is given, not to connect to new ones. (#150)
* Add `FLOW.error_message` to the `V1` module types to allow for
  generic handling of errors. (#346)
* Add `IP.uipaddr` as a universal IP address type. (#361)
* Support the `entropy` version 0.2+ interfaces. (#359)
* Check that the `opam` command is at least version 1.2.0 (#355)
* Don't put '-classic-display' in the generated Makefiles. (#364)

### 2.2.1 (2015-01-29)

* Fix logging errors when `mirage` output is not redirected. (#355)
* Do not reverse the order of C libraries when linking.  This fixes Zarith
  linking in Xen mode. (#341).
* Fix typos in command line help. (#352).

### 2.2.0 (2014-12-18)

* Add IPv6 support. This alters some of the interfaces that were previously
  hardcoded to IPv4 by generalising them.  For example:

    ```ocaml
type v4
type v6

type 'a ip
type ipv4 = v4 ip
type ipv6 = v6 ip
    ```

Full support for configuring IPv6 does not exist yet, as this release is
intended for getting the type definitions in place before adding configuration
support.

### 2.1.1 (2014-12-10)

* Do not reuse the Unix linker options when building Xen unikernels.  Instead,
  get the linker options from the ocamlfind `xen_linkopts` variables (#332).
  See `tcpip.2.1.0` for a library that does this for a C binding.
* Only activate MacOS X compilation by default on 10.10 (Yosemite) or higher.
  Older revisions of MacOS X will use the generic Unix mode by default, since
  the `vmnet` framework requires Yosemite or higher.
* Do not run crunched filesystem modules through `camlp4`, which significantly
  speeds up compilation on ARM platforms (from minutes to seconds!) (#299).

### 2.1.0 (2014-12-07)

* Add specific support for `MacOSX` as a platform, which enables network bridging
  on Yosemite (#329).  The `--unix` flag will automatically activate the new target
  if run on a MacOS X host.  If this breaks for you due to being on an older version of
  MacOS X, then use the new `--target` flag to set either Unix, MacOSX or Xen to the
  `mirage configure` command.
* Add `mirage.runtime` findlib library and corresponding Mirage_runtime module (#327).
* If net driver in STACKV4_direct can't initialize, print a helpful error (#164).
* [xen]: fixed link order in generated Makefile (#322).
* Make `Lwt.tracing` instructions work for Fish shell too by improving quoting (#328).

### 2.0.1 (2014-11-21)

* Add `register ~tracing` to enable tracing with mirage-profile at start-up (#321).
* Update Dockerfile for latest libraries (#320).
* Only build mirage-types if Io_page is also installed (#324).

### 2.0.0 (2014-11-05)

* [types]: backwards incompatible change: CONSOLE is now a FLOW;
  'write' has a different signature and 'write_all' has been removed.
* Set on_crash = 'preserve' in default Xen config.
* Automatically install dependencies again, but display the live output to the
  user.
* Include C stub libraries in linker command when generating Makefiles for Xen.
* Add `Vchan`, `Conduit` and `Resolver` code generators.
* Generate a `*.xe` script which can upload a kernel to a XenServer.
* Generate a libvirt `*.xml` configuration file (#292).
* Fix determination of `mirage-xen` location for paths with spaces (#279).
* Correctly show config file locations when using a custom one.
* Fix generation of foreign (non-functor) modules (#293)

### 1.2.0 (2014-07-05)

The Mirage frontend tool now generates a Makefile with a `make depend`
target, instead of directly invoking OPAM as part of `mirage configure`.
This greatly improves usability on slow platforms such as ARM, since the
output of OPAM as it builds can be inspected more easily.  Users will now
need to run `make depend` to ensure they have the latest package set,
before building their unikernel with `make` as normal.

* Improve format of generated Makefile, and also colours in terminal output.
* Add `make depend` target to generated Makefile.
* Set `OPAMVERBOSE` and `OPAMYES` in the Makefile, which can be overridden.
* Add an `ENTROPY` device type for strong random sources (#256).

### 1.1.3 (2014-06-15)

* Build OPAM packages in verbose mode by default.
* [types] Add `FLOW` based on `TCPV4`.
* travis: build mirage-types from here, rather than 1.1.0.

### 1.1.2 (2014-04-01)

* Improvement to the Amazon EC2 deployment script.
* [types] Augment STACKV4 with an IPV4 module in addition to TCPV4 and UDPV4.
* Regenerate with OASIS 0.4.4 (which adds natdynlink support)

### 1.1.1 (2014-02-21)

* Man page fixes for typos and terminology (#220).
* Activate backtrace recording by default (#225).
* Fixes in the `V1.STACKV4` to expose UDPv4/TCPv4 types properly (#226).

### 1.1.0 (2014-02-05)

* Add a combinator interface to device binding that makes the functor generation
  significantly more succinct and expressive.  This breaks backwards compatibility
  with `config.ml` files from the 1.0.x branches.
* Integrate the `mirage-types` code into `types`.  This is built as a separate
  library from the command-line tool, via the `install-types` Makefile target.

### 1.0.4 (2014-01-14)

* Add default build tags for annot, bin_annot, principal and strict_sequence.
* Renane `KV_RO` to `Crunch`

### 1.0.3 (2013-12-18)

* Do not remove OPAM packages when doing `mirage clean` (#143)
* [xen] generate a simple main.xl, without block devices or network interfaces.
* The HTTP dependency now also installs `mirage-tcp-*` and `mirage-http-*`.
* Fix generated Makefile dependency on source OCaml files to rebuild reliably.
* Support `Fat_KV_RO` (a read-only k/v version of the FAT filesystem).
* The Unix `KV_RO` now passes through to the underlying filesystem instead of calling `crunch`, via `mirage-fs-unix`.

### 1.0.2 (2013-12-10)

* Add `HTTP` support.
* Fix `KV_RO` configuration for OPAM autoinstall.

### 1.0.1 (2013-12-09)

* Add more examples to the FAT filesystem test case.
* Fix `mirage-tcpip-*` support
* Fix `mirage-net-*` support

### 1.0.0 (2013-12-09)

* Adapt the latest library releases for Mirage 1.0 interfaces.

### 0.10.0 (2013-12.08)

* Complete API rewrite
* [xen] XL configuration phase is now created during configure phase, was during run phase.

### 0.9.7 (2013-08-09)

* Generate code that uses the `Ipaddr.V4` interface instead of `Nettypes`.

### 0.9.6 (2013-07-26)

* fix unix-direct by linking the unix package correctly (previously it was always dropped).

### 0.9.5 (2013-07-18)

* completely remove the dependency on obuild: use ocamlbuild everywhere now.
* adapt for mirage-0.9.3 OS.Netif interfaces (abstract type `id`).
* do not output network config when there are no `ip-*` lines in the `.conf` file.
* do not try to install `mirage-fs` if there is no filesystem to create.
* added `nat-script.sh` to setup xenbr0 with DNS, DHCP and masqerading under Linux.

### 0.9.4 (2013-07-09)

* build using ocamlbuild rather than depending on obuild.
* [xen] generate a symbol that can be used to produce stack traces with xenctx.
* mirari run --socket just runs the unikernel without any tuntap work.
* mirari run --xen creates a xl config file and runs `xl create -c unikernel.xl`.

### 0.9.3 (2013-06-12)

* Add a `--socket` flag to activate socket-based networking (UNIX only).
* Do not use OPAM compiler switches any more, as that's done in the packaging now.
* Use fd-passing in the UNIX backend to spawn a process.

### 0.9.2 (2013-03-28)

* Install `obuild` automatically in all compiler switches (such as Xen).
* Only create symlinks to `mir-foo` for a non-Xen target.
* Add a `mirari clean` command.
* Add the autoswitch feature via `mirari --switch=<compiler>` or the config file.

### 0.9.1 (2013-02-13)

* Fix Xen symlink upon build.
* Add a `--no-install` option to `mirari configure` to prevent invoking OPAM automatically.

### 0.9.0 (2013-02-12)

* Automatically install `mirage-fs` package if a filesystem crunch is requested.
* Remove the need for `mir-run` by including the final Xen link directly in Mirari.
* Add support for building Xen variants.
* Initial import of a unix-direct version.
