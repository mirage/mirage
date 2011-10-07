open Regexp

let t f sre s =
  f (Re.from_string sre) s

let matches =
  t (fun r s -> Re.match_string r s 0 <> None)
let matches_totally =
  t (fun r s -> Re.match_string r s 0 = Some (String.length s))
let doesnt_match =
  t (fun r s -> Re.match_string r s 0 = None)
let doesnt_match_totally =
  t (fun r s -> Re.match_string r s 0 <> Some (String.length s))

let main () =
  assert (matches_totally      "a*" "aaaa");
  assert (matches_totally      "a*" "");
  assert (doesnt_match         "a+" "bbb");
  assert (matches              "a*" "baabb");
  assert (doesnt_match_totally "a*" "baabb");
  assert (matches_totally      "a+b*a+b*" "aa");
  assert (matches_totally      "a+b*a+b*" "aabbbbbb");
  assert (matches_totally      "a+b*a+b*" "ababbbbbb");
  assert (matches_totally      "(fred|joe)" "fred");
  assert (matches_totally      "(fred|joe)" "joe");
  assert (doesnt_match         "(fred|joe)" "jack");
  assert (matches_totally      "(fred|joe)*" "joefredfredfredjoefred");
  assert (matches              "(fred|joe)" "joefredjackfredjoefred");
  assert (doesnt_match_totally "(fred|joe)" "joefredjackfredjoefred");
  assert (matches_totally      "\\\\" "\\");
  Lwt.return ()
