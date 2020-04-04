
(rule
 (action
  (with-stdout-to name
  (with-stderr-to name.err
   (setenv MIRAGE_DEFAULT_TARGET unix
   (run ./config.exe query name))))))

(rule
 (alias runtest)
 (package mirage)
 (action
  (diff name.expected name)))

(rule
 (alias runtest)
 (package mirage)
 (action
  (diff name.err.expected name.err)))

(rule
 (action
  (with-stdout-to opam
  (with-stderr-to opam.err
   (setenv MIRAGE_DEFAULT_TARGET unix
   (run ./config.exe query opam))))))

(rule
 (alias runtest)
 (package mirage)
 (action
  (diff opam.expected opam)))

(rule
 (alias runtest)
 (package mirage)
 (action
  (diff opam.err.expected opam.err)))

(rule
 (action
  (with-stdout-to packages
  (with-stderr-to packages.err
   (setenv MIRAGE_DEFAULT_TARGET unix
   (run ./config.exe query packages))))))

(rule
 (alias runtest)
 (package mirage)
 (action
  (diff packages.expected packages)))

(rule
 (alias runtest)
 (package mirage)
 (action
  (diff packages.err.expected packages.err)))

(rule
 (action
  (with-stdout-to files
  (with-stderr-to files.err
   (setenv MIRAGE_DEFAULT_TARGET unix
   (run ./config.exe query files))))))

(rule
 (alias runtest)
 (package mirage)
 (action
  (diff files.expected files)))

(rule
 (alias runtest)
 (package mirage)
 (action
  (diff files.err.expected files.err)))

(rule
 (action
  (with-stdout-to Makefile
  (with-stderr-to Makefile.err
   (setenv MIRAGE_DEFAULT_TARGET unix
   (run ./config.exe query Makefile))))))

(rule
 (alias runtest)
 (package mirage)
 (action
  (diff Makefile.expected Makefile)))

(rule
 (alias runtest)
 (package mirage)
 (action
  (diff Makefile.err.expected Makefile.err)))

(rule
 (action
  (with-stdout-to Makefile.no-depext
  (with-stderr-to Makefile.no-depext.err
   (setenv MIRAGE_DEFAULT_TARGET unix
   (run ./config.exe query Makefile --no-depext))))))

(rule
 (alias runtest)
 (package mirage)
 (action
  (diff Makefile.no-depext.expected Makefile.no-depext)))

(rule
 (alias runtest)
 (package mirage)
 (action
  (diff Makefile.no-depext.err.expected Makefile.no-depext.err)))

(rule
 (action
  (with-stdout-to Makefile.depext
  (with-stderr-to Makefile.depext.err
   (setenv MIRAGE_DEFAULT_TARGET unix
   (run ./config.exe query Makefile --depext))))))

(rule
 (alias runtest)
 (package mirage)
 (action
  (diff Makefile.depext.expected Makefile.depext)))

(rule
 (alias runtest)
 (package mirage)
 (action
  (diff Makefile.depext.err.expected Makefile.depext.err)))

(rule
 (action
  (with-stdout-to x-dune
  (with-stderr-to x-dune.err
   (setenv MIRAGE_DEFAULT_TARGET unix
   (run ./config.exe query dune --dry-run))))))

(rule
 (alias runtest)
 (package mirage)
 (action
  (diff x-dune.expected x-dune)))

(rule
 (alias runtest)
 (package mirage)
 (action
  (diff x-dune.err.expected x-dune.err)))

(rule
 (action
  (with-stdout-to x-dune-base
  (with-stderr-to x-dune-base.err
   (setenv MIRAGE_DEFAULT_TARGET unix
   (run ./config.exe query dune-base))))))

(rule
 (alias runtest)
 (package mirage)
 (action
  (diff x-dune-base.expected x-dune-base)))

(rule
 (alias runtest)
 (package mirage)
 (action
  (diff x-dune-base.err.expected x-dune-base.err)))

(rule
 (action
  (with-stdout-to x-dune-project
  (with-stderr-to x-dune-project.err
   (setenv MIRAGE_DEFAULT_TARGET unix
   (run ./config.exe query dune-project))))))

(rule
 (alias runtest)
 (package mirage)
 (action
  (diff x-dune-project.expected x-dune-project)))

(rule
 (alias runtest)
 (package mirage)
 (action
  (diff x-dune-project.err.expected x-dune-project.err)))

(rule
 (action
  (with-stdout-to x-dune-workspace
  (with-stderr-to x-dune-workspace.err
   (setenv MIRAGE_DEFAULT_TARGET unix
   (run ./config.exe query dune-workspace --dry-run))))))

(rule
 (alias runtest)
 (package mirage)
 (action
  (diff x-dune-workspace.expected x-dune-workspace)))

(rule
 (alias runtest)
 (package mirage)
 (action
  (diff x-dune-workspace.err.expected x-dune-workspace.err)))

(rule
 (action
  (with-stdout-to name-hvt
  (with-stderr-to name-hvt.err
   (setenv MIRAGE_DEFAULT_TARGET unix
   (run ./config.exe query name --target=hvt))))))

(rule
 (alias runtest)
 (package mirage)
 (action
  (diff name-hvt.expected name-hvt)))

(rule
 (alias runtest)
 (package mirage)
 (action
  (diff name-hvt.err.expected name-hvt.err)))

(rule
 (action
  (with-stdout-to opam-hvt
  (with-stderr-to opam-hvt.err
   (setenv MIRAGE_DEFAULT_TARGET unix
   (run ./config.exe query opam --target=hvt))))))

(rule
 (alias runtest)
 (package mirage)
 (action
  (diff opam-hvt.expected opam-hvt)))

(rule
 (alias runtest)
 (package mirage)
 (action
  (diff opam-hvt.err.expected opam-hvt.err)))

(rule
 (action
  (with-stdout-to packages-hvt
  (with-stderr-to packages-hvt.err
   (setenv MIRAGE_DEFAULT_TARGET unix
   (run ./config.exe query packages --target=hvt))))))

(rule
 (alias runtest)
 (package mirage)
 (action
  (diff packages-hvt.expected packages-hvt)))

(rule
 (alias runtest)
 (package mirage)
 (action
  (diff packages-hvt.err.expected packages-hvt.err)))

(rule
 (action
  (with-stdout-to files-hvt
  (with-stderr-to files-hvt.err
   (setenv MIRAGE_DEFAULT_TARGET unix
   (run ./config.exe query files --target=hvt))))))

(rule
 (alias runtest)
 (package mirage)
 (action
  (diff files-hvt.expected files-hvt)))

(rule
 (alias runtest)
 (package mirage)
 (action
  (diff files-hvt.err.expected files-hvt.err)))

(rule
 (action
  (with-stdout-to Makefile-hvt
  (with-stderr-to Makefile-hvt.err
   (setenv MIRAGE_DEFAULT_TARGET unix
   (run ./config.exe query Makefile --target=hvt))))))

(rule
 (alias runtest)
 (package mirage)
 (action
  (diff Makefile-hvt.expected Makefile-hvt)))

(rule
 (alias runtest)
 (package mirage)
 (action
  (diff Makefile-hvt.err.expected Makefile-hvt.err)))

(rule
 (action
  (with-stdout-to Makefile.no-depext-hvt
  (with-stderr-to Makefile.no-depext-hvt.err
   (setenv MIRAGE_DEFAULT_TARGET unix
   (run ./config.exe query Makefile --no-depext --target=hvt))))))

(rule
 (alias runtest)
 (package mirage)
 (action
  (diff Makefile.no-depext-hvt.expected Makefile.no-depext-hvt)))

(rule
 (alias runtest)
 (package mirage)
 (action
  (diff Makefile.no-depext-hvt.err.expected Makefile.no-depext-hvt.err)))

(rule
 (action
  (with-stdout-to Makefile.depext-hvt
  (with-stderr-to Makefile.depext-hvt.err
   (setenv MIRAGE_DEFAULT_TARGET unix
   (run ./config.exe query Makefile --depext --target=hvt))))))

(rule
 (alias runtest)
 (package mirage)
 (action
  (diff Makefile.depext-hvt.expected Makefile.depext-hvt)))

(rule
 (alias runtest)
 (package mirage)
 (action
  (diff Makefile.depext-hvt.err.expected Makefile.depext-hvt.err)))

(rule
 (action
  (with-stdout-to x-dune-hvt
  (with-stderr-to x-dune-hvt.err
   (setenv MIRAGE_DEFAULT_TARGET unix
   (run ./config.exe query dune --dry-run --target=hvt))))))

(rule
 (alias runtest)
 (package mirage)
 (action
  (diff x-dune-hvt.expected x-dune-hvt)))

(rule
 (alias runtest)
 (package mirage)
 (action
  (diff x-dune-hvt.err.expected x-dune-hvt.err)))

(rule
 (action
  (with-stdout-to x-dune-base-hvt
  (with-stderr-to x-dune-base-hvt.err
   (setenv MIRAGE_DEFAULT_TARGET unix
   (run ./config.exe query dune-base --target=hvt))))))

(rule
 (alias runtest)
 (package mirage)
 (action
  (diff x-dune-base-hvt.expected x-dune-base-hvt)))

(rule
 (alias runtest)
 (package mirage)
 (action
  (diff x-dune-base-hvt.err.expected x-dune-base-hvt.err)))

(rule
 (action
  (with-stdout-to x-dune-project-hvt
  (with-stderr-to x-dune-project-hvt.err
   (setenv MIRAGE_DEFAULT_TARGET unix
   (run ./config.exe query dune-project --target=hvt))))))

(rule
 (alias runtest)
 (package mirage)
 (action
  (diff x-dune-project-hvt.expected x-dune-project-hvt)))

(rule
 (alias runtest)
 (package mirage)
 (action
  (diff x-dune-project-hvt.err.expected x-dune-project-hvt.err)))

(rule
 (action
  (with-stdout-to x-dune-workspace-hvt
  (with-stderr-to x-dune-workspace-hvt.err
   (setenv MIRAGE_DEFAULT_TARGET unix
   (run ./config.exe query dune-workspace --dry-run --target=hvt))))))

(rule
 (alias runtest)
 (package mirage)
 (action
  (diff x-dune-workspace-hvt.expected x-dune-workspace-hvt)))

(rule
 (alias runtest)
 (package mirage)
 (action
  (diff x-dune-workspace-hvt.err.expected x-dune-workspace-hvt.err)))
