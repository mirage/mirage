type t = { file : string; cmd : string }

let v x = { file = x; cmd = x }

let gen t =
  Format.printf
    {|
(rule
 (target help-%s)
 (action
  (with-stdout-to
   %%{target}
   (setenv MIRAGE_DEFAULT_TARGET unix
   (run ./config.exe help %s --man-format=plain)))))

(rule
 (target %s-help)
 (action
  (with-stdout-to
   %%{target}
   (setenv MIRAGE_DEFAULT_TARGET unix
   (run ./config.exe %s --help=plain)))))

(rule
 (alias runtest)
 (package mirage)
 (action
  (diff help-%s.expected help-%s)))

(rule
 (alias runtest)
 (package mirage)
 (action
  (diff %s-help.expected %s-help)))

(rule
 (alias runtest)
 (package mirage)
 (action
  (diff %s-help help-%s)))
|}
    t.file t.cmd t.file t.cmd t.file t.file t.file t.file t.file t.file

let () =
  List.iter gen
    [
      v "configure";
      { file = "configure-o"; cmd = "configure -o foo" };
      v "build";
      v "clean";
      v "query";
      v "describe";
    ]
