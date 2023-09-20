let failed_to_parse_comments =
  [
    "(* not a name *)";
    "not a comment";
    "(* missing closing thingy";
    "(* name2 >= bad version *)";
    "(* name3 >= 1.2.3 && < 2.3.4 *)";
    "(* name2 \n >= 1.2.3 & < 2.3.4 *)";
  ]

let test_failed_to_parse_comments () =
  List.iter
    (fun data ->
      match Functoria.Tool.check_version ~name:"name" ~version:"1.2.3" data with
      | Ok _ -> ()
      | Error msg ->
          Alcotest.fail
            ("expected comment parse failure (and an ok), but got error "
            ^ msg
            ^ " for "
            ^ data))
    failed_to_parse_comments

let bad_comments =
  [
    "(* name >= 1.2.3";
    "(* name >>= 1.2.3 *)";
    "(* name > 1.2.3 *)";
    "(* name >= 1.2.3 && < 2.3.4 *)";
    "(* name >= 1.2.3 & >= 2.3.4 *)";
    "(* name < 1.2.3 & < 2.3.4 *)";
  ]

let test_bad_comments () =
  List.iter
    (fun data ->
      match Functoria.Tool.check_version ~name:"name" ~version:"1.2.3" data with
      | Ok _ -> Alcotest.fail ("expected bad comment to be bad for " ^ data)
      | Error _ -> ())
    bad_comments

let good_comments =
  [
    "(* name >= 1.2.3 *)";
    "(* name < 2.0.0 *)";
    "(* name >= 1.0.0 & < 2.0.0 *)";
    "(* name >= 1.0.0 *)";
    "(* name >= 1.2 *)";
    "(* name >= 1.0 & < 2.0 *)";
    "(* name >= 1 & < 2 *)";
    "(* name < 2.0 *)";
    "(* name < 2 *)";
  ]

let test_good_comments () =
  List.iter
    (fun data ->
      match Functoria.Tool.check_version ~name:"name" ~version:"1.2.3" data with
      | Ok _ -> ()
      | Error _ ->
          Alcotest.fail
            ("expected good comment to be met for " ^ data ^ " at version 1.2.3"))
    good_comments;
  List.iter
    (fun data ->
      match Functoria.Tool.check_version ~name:"name" ~version:"1.3" data with
      | Ok _ -> ()
      | Error _ ->
          Alcotest.fail
            ("expected good comment to be met for " ^ data ^ " at version 1.3"))
    good_comments;
  List.iter
    (fun data ->
      match
        Functoria.Tool.check_version ~name:"name" ~version:"1.2.3-23-g453412"
          data
      with
      | Ok _ -> ()
      | Error _ ->
          Alcotest.fail
            ("expected good comment to be met for " ^ data ^ " at version 1.3"))
    good_comments

let unmet_comments =
  [
    "(* name >= 1.2.3 *)";
    "(* name < 0.1.2 *)";
    "(* name >= 1.0.0 & < 2.0.0 *)";
    "(* name >= 1.0.0 *)";
  ]

let test_unmet_comments () =
  List.iter
    (fun data ->
      match Functoria.Tool.check_version ~name:"name" ~version:"0.1.2" data with
      | Ok _ ->
          Alcotest.fail ("expected unmet comment to not be met for " ^ data)
      | Error _ -> ())
    unmet_comments

let suite =
  [
    ("failed_to_parse comments", `Quick, test_failed_to_parse_comments);
    ("bad comment", `Quick, test_bad_comments);
    ("good comment", `Quick, test_good_comments);
    ("unmet comment", `Quick, test_unmet_comments);
  ]
