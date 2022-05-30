open Functoria

let w = Package.v ~min:"1.0" ~max:"2.0" "foo" ~scope:`Switch
let x = Package.v ~min:"1.0" ~max:"2.0" "foo"
let y = Package.v ~min:"0.9" ~max:"1.9" ~sublibs:[ "bar" ] "foo"
let z = Package.v "bar" ~sublibs:[ "foo" ] ~min:"42"

let xy =
  match Package.merge x y with
  | Some x -> x
  | None -> Alcotest.fail "xy should not be None"

let test_package_merge () =
  let () =
    match Package.merge x z with
    | Some _ -> Alcotest.fail "xz should be None"
    | None -> ()
  in
  Alcotest.(check (list string))
    "min" (Package.min_versions xy) [ "0.9"; "1.0" ];
  Alcotest.(check (list string))
    "max" (Package.max_versions xy) [ "1.9"; "2.0" ]

let test_package_pp () =
  let str = Fmt.to_to_string Package.pp in
  let str' = Fmt.to_to_string (Package.pp ~surround:"x") in
  Alcotest.(check string)
    "pp(x)" (str x) {|foo { ?monorepo & >= "1.0" & < "2.0" }|};
  Alcotest.(check string)
    "pp(xy)" (str xy)
    {|foo { ?monorepo & >= "0.9" & >= "1.0" & < "1.9" & < "2.0" }|};
  Alcotest.(check string) "pp(z)" (str z) {|bar { ?monorepo & >= "42" }|};
  Alcotest.(check string)
    "pp'(x)" (str' x) {|xfoox { ?monorepo & >= "1.0" & < "2.0" }|};
  Alcotest.(check string) "pp(w)" (str w) {|foo { >= "1.0" & < "2.0" }|};
  Alcotest.(check string) "key(x)" (Package.key x) "monorepo-foo";
  Alcotest.(check string) "key(w)" (Package.key w) "switch-foo"

let test_invalid_package_names () =
  let check_name_is_invalid name =
    Alcotest.check_raises name
      (Invalid_argument (Fmt.str "package name %S is invalid" name))
      (fun () -> Package.v name |> ignore)
  in
  check_name_is_invalid "bar.subfoo";
  check_name_is_invalid "000";
  check_name_is_invalid "é"

let suite =
  [
    ("merge", `Quick, test_package_merge);
    ("pp", `Quick, test_package_pp);
    ("invalid names", `Quick, test_invalid_package_names);
  ]
