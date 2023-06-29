open Functoria

let x = Impl.v "Foo.Bar" Functoria.job
let y = Impl.v "X.Y" Functoria.(job @-> job) ~extra_deps:[ Impl.abstract x ]
let z = Impl.v "Bar" job ~extra_deps:[ Impl.abstract y ]

let z, y, x =
  let g = Impl.abstract z in
  let g = Impl.eval ~context:Context.empty g in
  match Device.Graph.fold List.cons g [] with
  | [ x; y; z ] -> (x, y, z)
  | _ -> assert false

let var_name x = Device.Graph.var_name x
let impl_name x = Device.Graph.impl_name x
let ident s i = Fmt.str "%s__%d" s i

let test_var_name () =
  Alcotest.(check string) "x" (ident "foo_bar" 1) (var_name x);
  Alcotest.(check string) "y" (ident "x_y" 2) (var_name y);
  Alcotest.(check string) "z" (ident "bar" 3) (var_name z)

let test_impl_name () =
  Alcotest.(check string) "x" "Foo.Bar" (impl_name x);
  Alcotest.(check string) "y" (ident "X_y" 2) (impl_name y);
  Alcotest.(check string) "z" "Bar" (impl_name z)

let d1 = Device.v ~packages:[ package "a" ] "Foo.Bar" job
let d2 = Device.v ~packages:[ package "b" ] "Foo.Bar" job
let i1 = of_device d1
let i2 = of_device d2
let if1 = if_impl (Key.pure true) i1 i2
let if2 = if_impl (Key.pure true) i2 i1

let normalise_lines str =
  let open Astring in
  let lines = String.cuts ~empty:true ~sep:"\n" str in
  let lines =
    List.map
      (fun line -> if String.for_all Char.Ascii.is_blank line then "" else line)
      lines
  in
  String.concat ~sep:"\n" lines

let graph_str g = normalise_lines (Fmt.to_to_string Impl.pp_dot g)

let digraph i =
  let j = i + 1 and k = i + 2 in
  Fmt.str
    {|digraph G {
  ordering=out;
  %d [label="foo_bar__%d\nFoo.Bar\n", shape="box"];
  %d [label="foo_bar__%d\nFoo.Bar\n", shape="box"];
  %d [label="If\n"];

  %d -> %d [style="dotted", headport="n"];
  %d -> %d [style="dotted", headport="n"];
  %d -> %d [style="bold", style="dotted", headport="n"];
  }|}
    i i j j k k i k j k i

let test_graph () =
  let t1 = Impl.abstract if1 in
  Alcotest.(check string) "t1.dot" (digraph 1) (graph_str t1);
  let t2 = Impl.abstract if2 in
  Alcotest.(check string) "t2.dot" (digraph 1) (graph_str t2);
  let module M = struct
    type t = (string * string list) list

    let empty = []
    let union = List.append
  end in
  let packages t =
    let ctx = Context.empty in
    Impl.collect
      (module M)
      (function
        | If _ | App -> []
        | Dev d ->
            let pkgs = Key.(eval ctx (Device.packages d)) in
            List.map (fun pkg -> (Package.name pkg, Package.libraries pkg)) pkgs)
      (Impl.simplify ~full:true ~context:ctx t)
  in
  let label = Alcotest.(list (pair string (list string))) in
  Alcotest.(check label) "t1" [ ("a", [ "a" ]) ] (packages t1);
  Alcotest.(check label) "t2" [ ("b", [ "b" ]) ] (packages t2)

let suite =
  [
    ("var_name", `Quick, test_var_name);
    ("impl_name", `Quick, test_impl_name);
    ("test_graph", `Quick, test_graph);
  ]
