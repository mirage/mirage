
(rule
 (target name)
 (action
  (with-stdout-to
   %{target}
   (run ./config.exe query name))))

(rule
 (alias runtest)
 (package functoria)
 (action
  (diff name.expected name)))

(rule
 (target opam)
 (action
  (with-stdout-to
   %{target}
   (run ./config.exe query opam))))

(rule
 (alias runtest)
 (package functoria)
 (action
  (diff opam.expected opam)))

(rule
 (target packages)
 (action
  (with-stdout-to
   %{target}
   (run ./config.exe query packages))))

(rule
 (alias runtest)
 (package functoria)
 (action
  (diff packages.expected packages)))

(rule
 (target install)
 (action
  (with-stdout-to
   %{target}
   (run ./config.exe query install))))

(rule
 (alias runtest)
 (package functoria)
 (action
  (diff install.expected install)))

(rule
 (target files-configure)
 (action
  (with-stdout-to
   %{target}
   (run ./config.exe query files-configure))))

(rule
 (alias runtest)
 (package functoria)
 (action
  (diff files-configure.expected files-configure)))

(rule
 (target files-build)
 (action
  (with-stdout-to
   %{target}
   (run ./config.exe query files-build))))

(rule
 (alias runtest)
 (package functoria)
 (action
  (diff files-build.expected files-build)))

(rule
 (target Makefile)
 (action
  (with-stdout-to
   %{target}
   (run ./config.exe query Makefile))))

(rule
 (alias runtest)
 (package functoria)
 (action
  (diff Makefile.expected Makefile)))

(rule
 (target Makefile.depext)
 (action
  (with-stdout-to
   %{target}
   (run ./config.exe query Makefile --depext))))

(rule
 (alias runtest)
 (package functoria)
 (action
  (diff Makefile.depext.expected Makefile.depext)))
