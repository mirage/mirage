
(rule
 (deps x.context y.context)
 (action
  (with-stdout-to query-package-no-x
  (with-stderr-to query-package-no-x.err
   (run ./config.exe query package --context-file=x.context)))))

(rule
 (alias runtest)
 (package functoria)
 (action
  (diff query-package-no-x.expected query-package-no-x)))

(rule
 (alias runtest)
 (package functoria)
 (action
  (diff query-package-no-x.err.expected query-package-no-x.err)))

(rule
 (deps x.context y.context)
 (action
  (with-stdout-to query-package-no-y
  (with-stderr-to query-package-no-y.err
   (run ./config.exe query package --context-file=y.context)))))

(rule
 (alias runtest)
 (package functoria)
 (action
  (diff query-package-no-y.expected query-package-no-y)))

(rule
 (alias runtest)
 (package functoria)
 (action
  (diff query-package-no-y.err.expected query-package-no-y.err)))

(rule
 (deps x.context y.context)
 (action
  (with-stdout-to query-package-x-y
  (with-stderr-to query-package-x-y.err
   (run ./config.exe query package -t x --context-file=y.context)))))

(rule
 (alias runtest)
 (package functoria)
 (action
  (diff query-package-x-y.expected query-package-x-y)))

(rule
 (alias runtest)
 (package functoria)
 (action
  (diff query-package-x-y.err.expected query-package-x-y.err)))

(rule
 (deps x.context y.context)
 (action
  (with-stdout-to query-package-y-x
  (with-stderr-to query-package-y-x.err
   (run ./config.exe query package -t y --context-file=x.context)))))

(rule
 (alias runtest)
 (package functoria)
 (action
  (diff query-package-y-x.expected query-package-y-x)))

(rule
 (alias runtest)
 (package functoria)
 (action
  (diff query-package-y-x.err.expected query-package-y-x.err)))

(rule
 (deps x.context y.context)
 (action
  (with-stdout-to describe-no-x
  (with-stderr-to describe-no-x.err
   (run ./config.exe describe --context-file=x.context)))))

(rule
 (alias runtest)
 (package functoria)
 (action
  (diff describe-no-x.expected describe-no-x)))

(rule
 (alias runtest)
 (package functoria)
 (action
  (diff describe-no-x.err.expected describe-no-x.err)))

(rule
 (deps x.context y.context)
 (action
  (with-stdout-to describe-no-y
  (with-stderr-to describe-no-y.err
   (run ./config.exe describe --context-file=y.context)))))

(rule
 (alias runtest)
 (package functoria)
 (action
  (diff describe-no-y.expected describe-no-y)))

(rule
 (alias runtest)
 (package functoria)
 (action
  (diff describe-no-y.err.expected describe-no-y.err)))

(rule
 (deps x.context y.context)
 (action
  (with-stdout-to describe-y-x
  (with-stderr-to describe-y-x.err
   (run ./config.exe describe -t y --context-file=x.context)))))

(rule
 (alias runtest)
 (package functoria)
 (action
  (diff describe-y-x.expected describe-y-x)))

(rule
 (alias runtest)
 (package functoria)
 (action
  (diff describe-y-x.err.expected describe-y-x.err)))

(rule
 (deps x.context y.context)
 (action
  (with-stdout-to describe-x-y
  (with-stderr-to describe-x-y.err
   (run ./config.exe describe -t x --context-file=y.context)))))

(rule
 (alias runtest)
 (package functoria)
 (action
  (diff describe-x-y.expected describe-x-y)))

(rule
 (alias runtest)
 (package functoria)
 (action
  (diff describe-x-y.err.expected describe-x-y.err)))
