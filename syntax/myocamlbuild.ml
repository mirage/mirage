open Ocamlbuild_plugin

let _ = dispatch begin function
  |Before_rules ->
    (* HACK: ocaml doesnt install a str.cmxs by default, it would seem *)
    rule "make str.cmxs from stdlib str.cmxa" ~prod:"str.cmxs"
     (let src = Lazy.force Ocamlbuild_pack.Ocaml_utils.stdlib_dir / "str.cmxa" in
      Ocamlbuild_pack.Ocaml_compiler.native_shared_library_link ~tags:["linkall"] src "str.cmxs"
     )
  |After_rules ->
     (* Required to repack sub-packs (like Pa_css) into Pa_mirage *)
     pflag ["ocaml"; "pack"] "for-repack" (fun param -> S [A "-for-pack"; A param]);
     (* Remove the need for ocamlfind *)
     let r = "camlp4 -I +camlp4 -parser o -parser op -printer p -parser Camlp4GrammarParser -parser Camlp4QuotationCommon -parser Camlp4OCamlRevisedQuotationExpander" in
     let o = "camlp4 -I +camlp4 -parser o -parser op -printer p -parser Camlp4GrammarParser -parser Camlp4QuotationCommon -parser Camlp4OCamlOriginalQuotationExpander" in
     let camlp4_cmd c = S [A"-pp"; A c; A"-I"; A"+camlp4"] in
     List.iter (fun mode -> flag ["ocaml"; mode; "use_camlp4_o"] & (camlp4_cmd o)) ["ocamldep"; "compile"];
     List.iter (fun mode -> flag ["ocaml"; mode; "use_camlp4_r"] & (camlp4_cmd r)) ["ocamldep"; "compile"];
  |_ -> ()
end
