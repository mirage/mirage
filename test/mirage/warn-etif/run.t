Configure the project for Unix:

  $ mirage configure -t unix
  mirage: [WARNING] Skipping version check, since our_version is not watermarked
  File "config.ml", line 16, characters 52-54:
  16 |     match conf with { hostname } -> ramdisk "secrets\f42"
                                                           ^^
  Warning 14 [illegal-backslash]: illegal backslash escape in string.
  File "config.ml", line 7, characters 2-13:
  7 |   type t = ()
        ^^^^^^^^^^^
  Warning 65 [redefining-unit]: This type declaration is defining a new '()' constructor
  which shadows the existing one.
  Hint: Did you mean 'type t = unit'?
  File "config.ml", line 8, characters 2-14:
  8 |   type t' = ()
        ^^^^^^^^^^^^
  Warning 65 [redefining-unit]: This type declaration is defining a new '()' constructor
  which shadows the existing one.
  Hint: Did you mean 'type t' = unit'?
  File "config.ml", line 11, characters 14-18:
  11 | let rec eth = etif default_network
                     ^^^^
  Alert deprecated: Mirage.etif
  Deprecated. Use [ethif] instead.
  File "config.ml", line 11, characters 8-11:
  11 | let rec eth = etif default_network
               ^^^
  Warning 39 [unused-rec-flag]: unused rec flag.
  File "config.ml", line 16, characters 20-32:
  16 |     match conf with { hostname } -> ramdisk "secrets\f42"
                           ^^^^^^^^^^^^
  Warning 9 [missing-record-field-pattern]: the following labels are not bound in this record pattern:
  server, port, truncate
  Either bind these labels explicitly or add '; _' to the pattern.
  File "config.ml", line 7, characters 2-13:
  7 |   type t = ()
        ^^^^^^^^^^^
  Warning 34 [unused-type-declaration]: unused type t.
  File "config.ml", line 7, characters 11-13:
  7 |   type t = ()
                 ^^
  Warning 37 [unused-constructor]: unused constructor ().
  File "config.ml", line 8, characters 2-14:
  8 |   type t' = ()
        ^^^^^^^^^^^^
  Warning 34 [unused-type-declaration]: unused type t'.
  File "config.ml", line 8, characters 12-14:
  8 |   type t' = ()
                  ^^
  Warning 37 [unused-constructor]: unused constructor ().
  File "config.ml", line 15, characters 6-13:
  15 |   let ramdisk (conf : syslog_config) =
             ^^^^^^^
  Warning 26 [unused-var]: unused variable ramdisk.
  File "config.ml", line 16, characters 22-30:
  16 |     match conf with { hostname } -> ramdisk "secrets\f42"
                             ^^^^^^^^
  Warning 27 [unused-var-strict]: unused variable hostname.
  File "config.ml", line 16, characters 52-54:
  16 |     match conf with { hostname } -> ramdisk "secrets\f42"
                                                           ^^
  Warning 14 [illegal-backslash]: illegal backslash escape in string.
  File "config.ml", line 7, characters 2-13:
  7 |   type t = ()
        ^^^^^^^^^^^
  Warning 65 [redefining-unit]: This type declaration is defining a new '()' constructor
  which shadows the existing one.
  Hint: Did you mean 'type t = unit'?
  File "config.ml", line 8, characters 2-14:
  8 |   type t' = ()
        ^^^^^^^^^^^^
  Warning 65 [redefining-unit]: This type declaration is defining a new '()' constructor
  which shadows the existing one.
  Hint: Did you mean 'type t' = unit'?
  File "config.ml", line 11, characters 14-18:
  11 | let rec eth = etif default_network
                     ^^^^
  Alert deprecated: Mirage.etif
  Deprecated. Use [ethif] instead.
  File "config.ml", line 11, characters 8-11:
  11 | let rec eth = etif default_network
               ^^^
  Warning 39 [unused-rec-flag]: unused rec flag.
  File "config.ml", line 16, characters 20-32:
  16 |     match conf with { hostname } -> ramdisk "secrets\f42"
                           ^^^^^^^^^^^^
  Warning 9 [missing-record-field-pattern]: the following labels are not bound in this record pattern:
  server, port, truncate
  Either bind these labels explicitly or add '; _' to the pattern.
  File "config.ml", line 7, characters 2-13:
  7 |   type t = ()
        ^^^^^^^^^^^
  Warning 34 [unused-type-declaration]: unused type t.
  File "config.ml", line 7, characters 11-13:
  7 |   type t = ()
                 ^^
  Warning 37 [unused-constructor]: unused constructor ().
  File "config.ml", line 8, characters 2-14:
  8 |   type t' = ()
        ^^^^^^^^^^^^
  Warning 34 [unused-type-declaration]: unused type t'.
  File "config.ml", line 8, characters 12-14:
  8 |   type t' = ()
                  ^^
  Warning 37 [unused-constructor]: unused constructor ().
  File "config.ml", line 15, characters 6-13:
  15 |   let ramdisk (conf : syslog_config) =
             ^^^^^^^
  Warning 26 [unused-var]: unused variable ramdisk.
  File "config.ml", line 16, characters 22-30:
  16 |     match conf with { hostname } -> ramdisk "secrets\f42"
                             ^^^^^^^^
  Warning 27 [unused-var-strict]: unused variable hostname.
  $ ls -a
  .
  ..
  Makefile
  _build
  config.ml
  dist
  dune
  dune-project
  dune-workspace
  dune.build
  dune.config
  mirage
