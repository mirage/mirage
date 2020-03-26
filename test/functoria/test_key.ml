open Functoria

let key_a = Key.create "a" Key.Arg.(flag @@ info [ "a" ])

let key_b = Key.create "b" Key.Arg.(opt int 0 @@ info [ "b" ])

let key_c =
  Key.create "c" Key.Arg.(required ~stage:`Configure string @@ info [ "c" ])

let empty = Key.empty_context

let ( & ) (k, v) c = Key.add_to_context k v c

let ( && ) x y = x & y & empty

let test_eval () =
  let context = (key_a, true) & (key_b, 0) && (key_c, Some "foo") in

  let if_ = Key.if_ Key.(value key_a) "hello" "world" in
  let r = Key.eval context if_ in
  Alcotest.(check string) "if" "hello" r;

  let match_1 =
    Key.match_ Key.(value key_b) (function 0 -> "hello" | _ -> "world")
  in
  let r = Key.eval context match_1 in
  Alcotest.(check string) "match 1" "hello" r;

  let match_2 =
    Key.match_
      Key.(value key_c)
      (function Some "foo" -> "hello" | _ -> "world")
  in
  let r = Key.eval context match_2 in
  Alcotest.(check string) "match 1" "hello" r

let keys = Key.Set.of_list Key.[ v key_a; v key_b; v key_c ]

let eval f keys argv =
  let argv = Array.of_list ("" :: argv) in
  match Cmdliner.Term.eval ~argv (f keys, Cmdliner.Term.info "keys") with
  | `Error _ -> Alcotest.fail "Error"
  | `Ok x -> x
  | `Version -> Alcotest.fail "version"
  | `Help -> Alcotest.fail "help"

exception Error

let test_get () =
  let context =
    eval (Key.context ~with_required:false) keys [ "-a"; "-c"; "foo" ]
  in
  Alcotest.(check bool) "get a" true (Key.get context key_a);
  Alcotest.(check int) "get b" 0 (Key.get context key_b);
  Alcotest.(check (option string)) "get c" (Some "foo") (Key.get context key_c);

  let context = eval (Key.context ~with_required:false) keys [ "-a" ] in
  Alcotest.(check (option string))
    "get c with_required:false" None (Key.get context key_c);

  Alcotest.check_raises "get c with_required:true" Error (fun () ->
      try ignore (eval (Key.context ~with_required:true) keys [ "-a" ])
      with _ -> raise Error)

let test_find () =
  let context = eval (Key.context ~with_required:false) keys [] in
  Alcotest.(check (option bool)) "find a" None (Key.find context key_a);
  Alcotest.(check (option int)) "find b" None (Key.find context key_b);
  Alcotest.(check (option (option string)))
    "find c" None (Key.find context key_c)

let test_merge () =
  let cache = (key_a, true) && (key_c, Some "foo") in
  let cli = (key_a, false) && (key_b, 2) in
  let context = Key.merge_context ~default:cache cli in
  Alcotest.(check bool) "merge a" false (Key.get context key_a);
  Alcotest.(check int) "merge b" 2 (Key.get context key_b);
  Alcotest.(check (option string))
    "merge c" (Some "foo") (Key.get context key_c)

let suite =
  List.map
    (fun (n, f) -> (n, `Quick, f))
    [
      ("eval", test_eval);
      ("get", test_get);
      ("find", test_find);
      ("merge", test_merge);
    ]
