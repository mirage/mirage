
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
  (with-stdout-to files-configure
  (with-stderr-to files-configure.err
   (setenv MIRAGE_DEFAULT_TARGET unix
   (run ./config.exe query files-configure))))))

(rule
 (alias runtest)
 (package mirage)
 (action
  (diff files-configure.expected files-configure)))

(rule
 (alias runtest)
 (package mirage)
 (action
  (diff files-configure.err.expected files-configure.err)))

(rule
 (action
  (with-stdout-to files-build
  (with-stderr-to files-build.err
   (setenv MIRAGE_DEFAULT_TARGET unix
   (run ./config.exe query files-build))))))

(rule
 (alias runtest)
 (package mirage)
 (action
  (diff files-build.expected files-build)))

(rule
 (alias runtest)
 (package mirage)
 (action
  (diff files-build.err.expected files-build.err)))

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
  (with-stdout-to version
  (with-stderr-to version.err
   (setenv MIRAGE_DEFAULT_TARGET unix
   (run ./config.exe query --version))))))

(rule
 (alias runtest)
 (package mirage)
 (action
  (diff version.expected version)))

(rule
 (alias runtest)
 (package mirage)
 (action
  (diff version.err.expected version.err)))

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
  (with-stdout-to files-configure-hvt
  (with-stderr-to files-configure-hvt.err
   (setenv MIRAGE_DEFAULT_TARGET unix
   (run ./config.exe query files-configure --target=hvt))))))

(rule
 (alias runtest)
 (package mirage)
 (action
  (diff files-configure-hvt.expected files-configure-hvt)))

(rule
 (alias runtest)
 (package mirage)
 (action
  (diff files-configure-hvt.err.expected files-configure-hvt.err)))

(rule
 (action
  (with-stdout-to files-build-hvt
  (with-stderr-to files-build-hvt.err
   (setenv MIRAGE_DEFAULT_TARGET unix
   (run ./config.exe query files-build --target=hvt))))))

(rule
 (alias runtest)
 (package mirage)
 (action
  (diff files-build-hvt.expected files-build-hvt)))

(rule
 (alias runtest)
 (package mirage)
 (action
  (diff files-build-hvt.err.expected files-build-hvt.err)))

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
  (with-stdout-to version-hvt
  (with-stderr-to version-hvt.err
   (setenv MIRAGE_DEFAULT_TARGET unix
   (run ./config.exe query --version --target=hvt))))))

(rule
 (alias runtest)
 (package mirage)
 (action
  (diff version-hvt.expected version-hvt)))

(rule
 (alias runtest)
 (package mirage)
 (action
  (diff version-hvt.err.expected version-hvt.err)))
