
(rule
 (action
  (with-stdout-to name
  (with-stderr-to name.err
   (run ./config.exe query name)))))

(rule
 (alias runtest)
 (package functoria)
 (action
  (diff name.expected name)))

(rule
 (alias runtest)
 (package functoria)
 (action
  (diff name.err.expected name.err)))

(rule
 (action
  (with-stdout-to opam
  (with-stderr-to opam.err
   (run ./config.exe query opam)))))

(rule
 (alias runtest)
 (package functoria)
 (action
  (diff opam.expected opam)))

(rule
 (alias runtest)
 (package functoria)
 (action
  (diff opam.err.expected opam.err)))

(rule
 (action
  (with-stdout-to packages
  (with-stderr-to packages.err
   (run ./config.exe query packages)))))

(rule
 (alias runtest)
 (package functoria)
 (action
  (diff packages.expected packages)))

(rule
 (alias runtest)
 (package functoria)
 (action
  (diff packages.err.expected packages.err)))

(rule
 (action
  (with-stdout-to files
  (with-stderr-to files.err
   (run ./config.exe query files)))))

(rule
 (alias runtest)
 (package functoria)
 (action
  (diff files.expected files)))

(rule
 (alias runtest)
 (package functoria)
 (action
  (diff files.err.expected files.err)))

(rule
 (action
  (with-stdout-to Makefile
  (with-stderr-to Makefile.err
   (run ./config.exe query Makefile)))))

(rule
 (alias runtest)
 (package functoria)
 (action
  (diff Makefile.expected Makefile)))

(rule
 (alias runtest)
 (package functoria)
 (action
  (diff Makefile.err.expected Makefile.err)))

(rule
 (action
  (with-stdout-to Makefile.no-depext
  (with-stderr-to Makefile.no-depext.err
   (run ./config.exe query Makefile --no-depext)))))

(rule
 (alias runtest)
 (package functoria)
 (action
  (diff Makefile.no-depext.expected Makefile.no-depext)))

(rule
 (alias runtest)
 (package functoria)
 (action
  (diff Makefile.no-depext.err.expected Makefile.no-depext.err)))

(rule
 (action
  (with-stdout-to Makefile.depext
  (with-stderr-to Makefile.depext.err
   (run ./config.exe query Makefile --depext)))))

(rule
 (alias runtest)
 (package functoria)
 (action
  (diff Makefile.depext.expected Makefile.depext)))

(rule
 (alias runtest)
 (package functoria)
 (action
  (diff Makefile.depext.err.expected Makefile.depext.err)))

(rule
 (action
  (with-stdout-to version
  (with-stderr-to version.err
   (run ./config.exe query --version)))))

(rule
 (alias runtest)
 (package functoria)
 (action
  (diff version.expected version)))

(rule
 (alias runtest)
 (package functoria)
 (action
  (diff version.err.expected version.err)))

(rule
 (action
  (with-stdout-to x-dune
  (with-stderr-to x-dune.err
   (run ./config.exe query dune)))))

(rule
 (alias runtest)
 (package functoria)
 (action
  (diff x-dune.expected x-dune)))

(rule
 (alias runtest)
 (package functoria)
 (action
  (diff x-dune.err.expected x-dune.err)))

(rule
 (action
  (with-stdout-to x-dune-base
  (with-stderr-to x-dune-base.err
   (run ./config.exe query dune-base)))))

(rule
 (alias runtest)
 (package functoria)
 (action
  (diff x-dune-base.expected x-dune-base)))

(rule
 (alias runtest)
 (package functoria)
 (action
  (diff x-dune-base.err.expected x-dune-base.err)))

(rule
 (action
  (with-stdout-to x-dune-project
  (with-stderr-to x-dune-project.err
   (run ./config.exe query dune-project)))))

(rule
 (alias runtest)
 (package functoria)
 (action
  (diff x-dune-project.expected x-dune-project)))

(rule
 (alias runtest)
 (package functoria)
 (action
  (diff x-dune-project.err.expected x-dune-project.err)))

(rule
 (action
  (with-stdout-to x-dune-workspace
  (with-stderr-to x-dune-workspace.err
   (run ./config.exe query dune-workspace)))))

(rule
 (alias runtest)
 (package functoria)
 (action
  (diff x-dune-workspace.expected x-dune-workspace)))

(rule
 (alias runtest)
 (package functoria)
 (action
  (diff x-dune-workspace.err.expected x-dune-workspace.err)))
