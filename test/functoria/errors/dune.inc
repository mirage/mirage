
(rule
  (target configure)
  (action
    (with-stdout-to configure
    (with-stderr-to configure.err
      (with-accepted-exit-codes 1 (run ./test.exe configure --vote=dog))))))

(rule
  (alias runtest)
  (package functoria)
  (action (diff configure.expected configure)))

(rule
  (alias runtest)
  (package functoria)
  (action (diff configure.err.expected configure.err)))

(rule
  (target query)
  (action
    (with-stdout-to query
    (with-stderr-to query.err
      (with-accepted-exit-codes 1 (run ./test.exe query --vote=dog))))))

(rule
  (alias runtest)
  (package functoria)
  (action (diff query.expected query)))

(rule
  (alias runtest)
  (package functoria)
  (action (diff query.err.expected query.err)))

(rule
  (target describe)
  (action
    (with-stdout-to describe
    (with-stderr-to describe.err
      (with-accepted-exit-codes 1 (run ./test.exe describe --vote=dog))))))

(rule
  (alias runtest)
  (package functoria)
  (action (diff describe.expected describe)))

(rule
  (alias runtest)
  (package functoria)
  (action (diff describe.err.expected describe.err)))

(rule
  (target help)
  (action
    (with-stdout-to help
    (with-stderr-to help.err
      (with-accepted-exit-codes 0 (run ./test.exe help --man-format=plain))))))

(rule
  (alias runtest)
  (package functoria)
  (action (diff help.expected help)))

(rule
  (alias runtest)
  (package functoria)
  (action (diff help.err.expected help.err)))

(rule
  (target clean)
  (action
    (with-stdout-to clean
    (with-stderr-to clean.err
      (with-accepted-exit-codes 0 (run ./test.exe clean --vote=dog))))))

(rule
  (alias runtest)
  (package functoria)
  (action (diff clean.expected clean)))

(rule
  (alias runtest)
  (package functoria)
  (action (diff clean.err.expected clean.err)))
