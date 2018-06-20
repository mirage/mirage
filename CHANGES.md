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
