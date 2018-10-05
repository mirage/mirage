let with_fmt_str k =
  let buf = Buffer.create 0 in
  let fmt = Format.formatter_of_buffer buf in
  k fmt;
  Format.pp_print_flush fmt ();
  Buffer.contents buf

let redact_line n s =
  (* At the moment it is not possible to inject argv & time so we remove the
   * generated line.
   * See https://github.com/mirage/functoria/pull/159 *)
  let lines = String.split_on_char '\n' s in
  let redacted_lines =
    List.mapi
      (fun i line ->
        if i + 1 = n then
          "# REDACTED"
        else
          line
      )
      lines
  in
  String.concat "\n" redacted_lines

let print_banner s =
  print_endline s;
  print_endline @@ String.make (String.length s) '=';
  print_newline ()

let test_output_main_xl () =
  print_banner "output_main_xl";
  print_endline @@
  redact_line 1 @@
  with_fmt_str
    (Mirage_cli.output_main_xl
       ~name:"NAME"
       ~kernel:"KERNEL"
       ~memory:"MEMORY"
       ~blocks:
         [ (0, "BLOCK_PATH0")
         ; (1, "BLOCK_PATH1")
         ; (60, "BLOCK_PATH60")
         ]
       ~networks:["NETWORK1"; "NETWORK2"]
    )

let test_output_main_xe () =
  print_banner "output_main_xe";
  print_endline @@
  redact_line 2 @@
  with_fmt_str
    (Mirage_cli.output_main_xe
       ~root:"ROOT"
       ~name:"NAME"
       ~blocks:
         [ ("FILE1", 1)
         ; ("FILE2", 2)
         ]
    )

let test_output_main_libvirt_xml () =
  print_banner "output_main_libvirt_xml";
  print_endline @@
  redact_line 1 @@
  with_fmt_str
    (Mirage_cli.output_main_libvirt_xml
       ~root:"ROOT"
       ~name:"NAME"
    )

let test_output_virtio_libvirt_xml () =
  print_banner "output_virtio_libvirt_xml";
  print_endline @@
  redact_line 1 @@
  with_fmt_str
    (Mirage_cli.output_virtio_libvirt_xml
       ~root:"ROOT"
       ~name:"NAME"
    )

let test_output_opam () =
  print_banner "output_opam";
  print_endline @@
  redact_line 1 @@
  with_fmt_str
    (Mirage_cli.output_opam
      ~name:"NAME"
      ~info:(
        Functoria.Info.create
          ~packages:
            [ Functoria.package "pkg1"
            ; Functoria.package "pkg2" ~build:true
            ; Functoria.package "pkg3" ~min:"3"
            ; Functoria.package "pkg4" ~max:"4"
            ; Functoria.package "pkg5" ~min:"5.0" ~max:"5.1"
            ]
          ~keys:[]
          ~context:Functoria_key.empty_context
          ~name:"INFO_NAME"
          ~build_dir:(Fpath.v "BUILD_DIR")
      )
    )

let test_output_fat () =
  print_banner "output_fat";
  print_endline @@
  with_fmt_str
    (Mirage_cli.output_fat
      ~block_file:"BLOCK_FILE"
      ~root:(Fpath.v "ROOT")
      ~dir:(Fpath.v "DIR")
      ~regexp:"REGEXP"
    )

let () =
  test_output_main_xl ();
  test_output_main_xe ();
  test_output_main_libvirt_xml ();
  test_output_virtio_libvirt_xml ();
  test_output_opam ();
  test_output_fat ();
  ()
