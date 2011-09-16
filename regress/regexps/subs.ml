open Regexp

let t sre replacer replacee result =
  Re.substitute (Re.from_string sre) replacee replacer = result

let main () =
  assert (t "a+" (fun _ -> "") "abcaabcabcaabc" "bcbcbcbc");
  assert (t "a+" (fun s -> string_of_int (String.length s))
    "abcaabcabcaabc" "1bc2bc1bc2bc"
  );
  assert (t "fred|joe"
    (function "fred" -> "Frederic" | "joe" -> "Joseph" |_ -> assert false)
    "fred     joefred blahhhjoefreedfredfrederic"
    "Frederic     JosephFrederic blahhhJosephfreedFredericFredericeric"
  );
  Lwt.return ()
