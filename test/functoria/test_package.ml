open Functoria

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
  Alcotest.(check string) "pp(x)" (str x) {|foo { >= "1.0" & < "2.0"}|};
  Alcotest.(check string)
    "pp(xy)" (str xy) {|foo { >= "0.9" & >= "1.0" & < "1.9" & < "2.0"}|};
  Alcotest.(check string) "pp(z)" (str z) {|bar { >= "42"}|};
  Alcotest.(check string) "pp'(x)" (str' x) {|xfoox { >= "1.0" & < "2.0"}|}

let suite =
  [ ("merge", `Quick, test_package_merge); ("pp", `Quick, test_package_pp) ]
