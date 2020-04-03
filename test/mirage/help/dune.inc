
(rule
 (target help-configure)
 (action
  (with-stdout-to
   %{target}
   (setenv MIRAGE_DEFAULT_TARGET unix
   (run ./config.exe help configure --man-format=plain)))))

(rule
 (target configure-help)
 (action
  (with-stdout-to
   %{target}
   (setenv MIRAGE_DEFAULT_TARGET unix
   (run ./config.exe configure --help=plain)))))

(rule
 (alias runtest)
 (package mirage)
 (action
  (diff help-configure.expected help-configure)))

(rule
 (alias runtest)
 (package mirage)
 (action
  (diff configure-help.expected configure-help)))

(rule
 (alias runtest)
 (package mirage)
 (action
  (diff configure-help help-configure)))

(rule
 (target help-configure-o)
 (action
  (with-stdout-to
   %{target}
   (setenv MIRAGE_DEFAULT_TARGET unix
   (run ./config.exe help configure -o foo --man-format=plain)))))

(rule
 (target configure-o-help)
 (action
  (with-stdout-to
   %{target}
   (setenv MIRAGE_DEFAULT_TARGET unix
   (run ./config.exe configure -o foo --help=plain)))))

(rule
 (alias runtest)
 (package mirage)
 (action
  (diff help-configure-o.expected help-configure-o)))

(rule
 (alias runtest)
 (package mirage)
 (action
  (diff configure-o-help.expected configure-o-help)))

(rule
 (alias runtest)
 (package mirage)
 (action
  (diff configure-o-help help-configure-o)))

(rule
 (target help-build)
 (action
  (with-stdout-to
   %{target}
   (setenv MIRAGE_DEFAULT_TARGET unix
   (run ./config.exe help build --man-format=plain)))))

(rule
 (target build-help)
 (action
  (with-stdout-to
   %{target}
   (setenv MIRAGE_DEFAULT_TARGET unix
   (run ./config.exe build --help=plain)))))

(rule
 (alias runtest)
 (package mirage)
 (action
  (diff help-build.expected help-build)))

(rule
 (alias runtest)
 (package mirage)
 (action
  (diff build-help.expected build-help)))

(rule
 (alias runtest)
 (package mirage)
 (action
  (diff build-help help-build)))

(rule
 (target help-clean)
 (action
  (with-stdout-to
   %{target}
   (setenv MIRAGE_DEFAULT_TARGET unix
   (run ./config.exe help clean --man-format=plain)))))

(rule
 (target clean-help)
 (action
  (with-stdout-to
   %{target}
   (setenv MIRAGE_DEFAULT_TARGET unix
   (run ./config.exe clean --help=plain)))))

(rule
 (alias runtest)
 (package mirage)
 (action
  (diff help-clean.expected help-clean)))

(rule
 (alias runtest)
 (package mirage)
 (action
  (diff clean-help.expected clean-help)))

(rule
 (alias runtest)
 (package mirage)
 (action
  (diff clean-help help-clean)))

(rule
 (target help-query)
 (action
  (with-stdout-to
   %{target}
   (setenv MIRAGE_DEFAULT_TARGET unix
   (run ./config.exe help query --man-format=plain)))))

(rule
 (target query-help)
 (action
  (with-stdout-to
   %{target}
   (setenv MIRAGE_DEFAULT_TARGET unix
   (run ./config.exe query --help=plain)))))

(rule
 (alias runtest)
 (package mirage)
 (action
  (diff help-query.expected help-query)))

(rule
 (alias runtest)
 (package mirage)
 (action
  (diff query-help.expected query-help)))

(rule
 (alias runtest)
 (package mirage)
 (action
  (diff query-help help-query)))

(rule
 (target help-describe)
 (action
  (with-stdout-to
   %{target}
   (setenv MIRAGE_DEFAULT_TARGET unix
   (run ./config.exe help describe --man-format=plain)))))

(rule
 (target describe-help)
 (action
  (with-stdout-to
   %{target}
   (setenv MIRAGE_DEFAULT_TARGET unix
   (run ./config.exe describe --help=plain)))))

(rule
 (alias runtest)
 (package mirage)
 (action
  (diff help-describe.expected help-describe)))

(rule
 (alias runtest)
 (package mirage)
 (action
  (diff describe-help.expected describe-help)))

(rule
 (alias runtest)
 (package mirage)
 (action
  (diff describe-help help-describe)))
