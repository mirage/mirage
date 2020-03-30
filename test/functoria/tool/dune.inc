
(rule
  (target configure)
  (action
    (with-stdout-to configure
    (with-stderr-to configure.err
      (run ./test.exe configure a b c)))))

(rule
  (alias runtest)
  (package functoria)
  (action (diff configure.expected configure)))

(rule
  (alias runtest)
  (package functoria)
  (action (diff configure.err.expected configure.err)))

(rule
  (target build)
  (action
    (with-stdout-to build
    (with-stderr-to build.err
      (run ./test.exe build a b c)))))

(rule
  (alias runtest)
  (package functoria)
  (action (diff build.expected build)))

(rule
  (alias runtest)
  (package functoria)
  (action (diff build.err.expected build.err)))

(rule
  (target clean)
  (action
    (with-stdout-to clean
    (with-stderr-to clean.err
      (run ./test.exe clean a b c)))))

(rule
  (alias runtest)
  (package functoria)
  (action (diff clean.expected clean)))

(rule
  (alias runtest)
  (package functoria)
  (action (diff clean.err.expected clean.err)))

(rule
  (target query)
  (action
    (with-stdout-to query
    (with-stderr-to query.err
      (run ./test.exe query a b c)))))

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
      (run ./test.exe describe a b c)))))

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
      (run ./test.exe help a b c)))))

(rule
  (alias runtest)
  (package functoria)
  (action (diff help.expected help)))

(rule
  (alias runtest)
  (package functoria)
  (action (diff help.err.expected help.err)))

(rule
  (target simple-help)
  (action
    (with-stdout-to simple-help
    (with-stderr-to simple-help.err
      (run ./test.exe help)))))

(rule
  (alias runtest)
  (package functoria)
  (action (diff simple-help.expected simple-help)))

(rule
  (alias runtest)
  (package functoria)
  (action (diff simple-help.err.expected simple-help.err)))

(rule
  (target help-configure)
  (action
    (with-stdout-to help-configure
    (with-stderr-to help-configure.err
      (run ./test.exe help configure)))))

(rule
  (alias runtest)
  (package functoria)
  (action (diff help-configure.expected help-configure)))

(rule
  (alias runtest)
  (package functoria)
  (action (diff help-configure.err.expected help-configure.err)))

(rule
  (target configure-help)
  (action
    (with-stdout-to configure-help
    (with-stderr-to configure-help.err
      (run ./test.exe configure help)))))

(rule
  (alias runtest)
  (package functoria)
  (action (diff configure-help.expected configure-help)))

(rule
  (alias runtest)
  (package functoria)
  (action (diff configure-help.err.expected configure-help.err)))

(rule
  (target help-no-config)
  (action
    (with-stdout-to help-no-config
    (with-stderr-to help-no-config.err
      (run ./test.exe help --file=empty/config.ml --man-format=plain)))))

(rule
  (alias runtest)
  (package functoria)
  (action (diff help-no-config.expected help-no-config)))

(rule
  (alias runtest)
  (package functoria)
  (action (diff help-no-config.err.expected help-no-config.err)))

(rule
  (target help-no-config-err)
  (action
    (with-stdout-to help-no-config-err
    (with-stderr-to help-no-config-err.err
      (run ./test.exe help --file=empty/config.ml a b c)))))

(rule
  (alias runtest)
  (package functoria)
  (action (diff help-no-config-err.expected help-no-config-err)))

(rule
  (alias runtest)
  (package functoria)
  (action (diff help-no-config-err.err.expected help-no-config-err.err)))

(rule
  (target build-help-no-config)
  (action
    (with-stdout-to build-help-no-config
    (with-stderr-to build-help-no-config.err
      (run ./test.exe build --help=plain --file=empty/config.ml a b c)))))

(rule
  (alias runtest)
  (package functoria)
  (action (diff build-help-no-config.expected build-help-no-config)))

(rule
  (alias runtest)
  (package functoria)
  (action (diff build-help-no-config.err.expected build-help-no-config.err)))

(rule
  (target version)
  (action
    (with-stdout-to version
    (with-stderr-to version.err
      (run ./test.exe configure --version a b c)))))

(rule
  (alias runtest)
  (package functoria)
  (action (diff version.expected version)))

(rule
  (alias runtest)
  (package functoria)
  (action (diff version.err.expected version.err)))

(rule
  (target ambiguous)
  (action
    (with-stdout-to ambiguous
    (with-stderr-to ambiguous.err
      (run ./test.exe c a b c)))))

(rule
  (alias runtest)
  (package functoria)
  (action (diff ambiguous.expected ambiguous)))

(rule
  (alias runtest)
  (package functoria)
  (action (diff ambiguous.err.expected ambiguous.err)))

(rule
  (target default)
  (action
    (with-stdout-to default
    (with-stderr-to default.err
      (run ./test.exe )))))

(rule
  (alias runtest)
  (package functoria)
  (action (diff default.expected default)))

(rule
  (alias runtest)
  (package functoria)
  (action (diff default.err.expected default.err)))
