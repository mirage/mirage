open Pervasives
(***********************************************************************)
(*                                                                     *)
(*                           Objective Caml                            *)
(*                                                                     *)
(*         Jerome Vouillon, projet Cristal, INRIA Rocquencourt         *)
(*                                                                     *)
(*  Copyright 2002 Institut National de Recherche en Informatique et   *)
(*  en Automatique.  All rights reserved.  This file is distributed    *)
(*  under the terms of the GNU Library General Public License, with    *)
(*  the special exception on linking described in file ../LICENSE.     *)
(*                                                                     *)
(***********************************************************************)

(* $Id: camlinternalOO.ml 8768 2008-01-11 16:13:18Z doligez $ *)

open Obj
open Ocamljs.Inline

(**** Object representation ****)

let last_id = ref 0
let new_id () =
  let id = !last_id in incr last_id; id

let set_id o id =
  let id0 = !id in
  Array.unsafe_set (Obj.magic o : int array) 1 id0;
  id := id0 + 1

(**** Object copy ****)

let copy o =
  let c = << new $o$.constructor() >> in
  <:stmt<
    var s = $o$._s;
    var i;
    for (i=0; i < s; i++)
      $c$[i] = $o$[i];
  >>;
  set_id c last_id;
  c

(**** Compression options ****)
(* Parameters *)
type params = {
    mutable compact_table : bool;
    mutable copy_parent : bool;
    mutable clean_when_copying : bool;
    mutable retry_count : int;
    mutable bucket_small_size : int
  }

let params = {
  compact_table = true;
  copy_parent = true;
  clean_when_copying = true;
  retry_count = 3;
  bucket_small_size = 16
}

(**** Parameters ****)

let step = Sys.word_size / 16
let initial_object_size = 2

(**** Items ****)

type item = DummyA | DummyB | DummyC of int

let dummy_item = (magic () : item)

(**** Types ****)

type tag
type label = int
type closure = item
type t = DummyA | DummyB | DummyC of int
type obj = t array
external ret : (obj -> 'a) -> closure = "$dummyargfun"

(**** Labels ****)

let public_method_label s : tag = failwith "unused"

(**** Sparse array ****)

module Vars = Map.Make(struct type t = string let compare = compare end)
type vars = int Vars.t

module Meths = Map.Make(struct type t = string let compare = compare end)
type meths = label Meths.t
module Labs = Map.Make(struct type t = label let compare = compare end)
type labs = bool Labs.t

(* The compiler assumes that the first field of this structure is [size]. *)
type table =
 { mutable size: int;
   mutable methods: closure array;
   mutable methods_by_name: meths;
   mutable methods_by_label: labs;
   mutable previous_states:
     (meths * labs * (label * item) list * vars *
      label list * string list) list;
   mutable hidden_meths: (label * item) list;
   mutable vars: vars;
   mutable initializers: (obj -> unit) list;
   mutable constructor: Obj.t }

let dummy_table =
  { methods = [| dummy_item |];
    methods_by_name = Meths.empty;
    methods_by_label = Labs.empty;
    previous_states = [];
    hidden_meths = [];
    vars = Vars.empty;
    initializers = [];
    size = 0;
    constructor = Obj.magic 0; }

let table_count = ref 0

(* dummy_met should be a pointer, so use an atom *)
let dummy_met : item = obj (Obj.new_block 0 0)
(* if debugging is needed, this could be a good idea: *)
(* let dummy_met () = failwith "Undefined method" *)

let rec fit_size n =
  if n <= 2 then n else
  fit_size ((n+1)/2) * 2

let new_table len =
  incr table_count;
  { methods = Array.create len dummy_met;
    methods_by_name = Meths.empty;
    methods_by_label = Labs.empty;
    previous_states = [];
    hidden_meths = [];
    vars = Vars.empty;
    initializers = [];
    size = initial_object_size;
    constructor = Obj.magic 0; }

let resize array new_size =
  let old_size = Array.length array.methods in
  if new_size > old_size then begin
    let new_buck = Array.create new_size dummy_met in
    Array.blit array.methods 0 new_buck 0 old_size;
    array.methods <- new_buck
 end

let put array label element =
  resize array (label + 1);
  array.methods.(label) <- element

(**** Classes ****)

let method_count = ref 0
let inst_var_count = ref 0

(* type t *)
type meth = item

let new_method table =
  let index = Array.length table.methods in
  resize table (index + 1);
  index

let get_method_label table name =
  try
    Meths.find name table.methods_by_name
  with Not_found ->
    let label = new_method table in
    table.methods_by_name <- Meths.add name label table.methods_by_name;
    table.methods_by_label <- Labs.add label true table.methods_by_label;
    label

let get_method_labels table names =
  Array.map (get_method_label table) names

let set_method table label element =
  incr method_count;
  if Labs.find label table.methods_by_label then
    put table label element
  else
    table.hidden_meths <- (label, element) :: table.hidden_meths

let get_method table label =
  try List.assoc label table.hidden_meths
  with Not_found -> table.methods.(label)

let to_list arr =
  if arr == magic 0 then [] else Array.to_list arr

let narrow table vars virt_meths concr_meths =
  let vars = to_list vars
  and virt_meths = to_list virt_meths
  and concr_meths = to_list concr_meths in
  let virt_meth_labs = List.map (get_method_label table) virt_meths in
  let concr_meth_labs = List.map (get_method_label table) concr_meths in
  table.previous_states <-
     (table.methods_by_name, table.methods_by_label, table.hidden_meths,
      table.vars, virt_meth_labs, vars)
     :: table.previous_states;
  table.vars <-
    Vars.fold
      (fun lab info tvars ->
        if List.mem lab vars then Vars.add lab info tvars else tvars)
      table.vars Vars.empty;
  let by_name = ref Meths.empty in
  let by_label = ref Labs.empty in
  List.iter2
    (fun met label ->
       by_name := Meths.add met label !by_name;
       by_label :=
          Labs.add label
            (try Labs.find label table.methods_by_label with Not_found -> true)
            !by_label)
    concr_meths concr_meth_labs;
  List.iter2
    (fun met label ->
       by_name := Meths.add met label !by_name;
       by_label := Labs.add label false !by_label)
    virt_meths virt_meth_labs;
  table.methods_by_name <- !by_name;
  table.methods_by_label <- !by_label;
  table.hidden_meths <-
     List.fold_right
       (fun ((lab, _) as met) hm ->
          if List.mem lab virt_meth_labs then hm else met::hm)
       table.hidden_meths
       []

let widen table =
  let (by_name, by_label, saved_hidden_meths, saved_vars, virt_meths, vars) =
    List.hd table.previous_states
  in
  table.previous_states <- List.tl table.previous_states;
  table.vars <-
     List.fold_left
       (fun s v -> Vars.add v (Vars.find v table.vars) s)
       saved_vars vars;
  table.methods_by_name <- by_name;
  table.methods_by_label <- by_label;
  table.hidden_meths <-
     List.fold_right
       (fun ((lab, _) as met) hm ->
          if List.mem lab virt_meths then hm else met::hm)
       table.hidden_meths
       saved_hidden_meths

let new_slot table =
  let index = table.size in
  table.size <- index + 1;
  index

let new_variable table name =
  try Vars.find name table.vars
  with Not_found ->
    let index = new_slot table in
    if name <> "" then table.vars <- Vars.add name index table.vars;
    index

let to_array arr =
  if arr = Obj.magic 0 then [||] else arr

let new_methods_variables table meths vals =
  let meths = to_array meths in
  let nmeths = Array.length meths and nvals = Array.length vals in
  let res = Array.create (nmeths + nvals) 0 in
  for i = 0 to nmeths - 1 do
    res.(i) <- get_method_label table meths.(i)
  done;
  for i = 0 to nvals - 1 do
    res.(i+nmeths) <- new_variable table vals.(i)
  done;
  res

let get_variable table name =
  try Vars.find name table.vars with Not_found -> assert false

let get_variables table names =
  Array.map (get_variable table) names

let add_initializer table f =
  table.initializers <- f::table.initializers

(*
module Keys = Map.Make(struct type t = tag array let compare = compare end)
let key_map = ref Keys.empty
let get_key tags : item =
  try magic (Keys.find tags !key_map : tag array)
  with Not_found ->
    key_map := Keys.add tags tags !key_map;
    magic tags
*)

let create_table public_methods =
  if public_methods == magic 0 then new_table 0 else
  (* [public_methods] must be in ascending order for bytecode *)
  let table = new_table (Array.length public_methods) in
  Array.iteri
    (fun i met ->
      let lab = i in
      table.methods_by_name  <- Meths.add met lab table.methods_by_name;
      table.methods_by_label <- Labs.add lab true table.methods_by_label)
    public_methods;
  table

let init_class table =
  inst_var_count := !inst_var_count + table.size - 1;
  table.initializers <- List.rev table.initializers;
  table.constructor <- << function () { } >>;
  Meths.iter
    (fun met lab ->
      <:stmt< $table.constructor$.prototype[$met$] = $table.methods$[$lab$]; >>)
    table.methods_by_name;
  <:stmt<
    $table.constructor$.prototype._m = $table.methods$;
    $table.constructor$.prototype._s = $table.size$;
  >>

let inherits cla vals virt_meths concr_meths (_, super, _, env) top =
  narrow cla vals virt_meths concr_meths;
  let init =
    if top then super cla env else Obj.repr (super cla) in
  widen cla;
  Array.concat
    [[| repr init |];
     magic (Array.map (get_variable cla) (to_array vals) : int array);
     Array.map
       (fun nm -> repr (get_method cla (get_method_label cla nm) : closure))
       (to_array concr_meths) ]

let make_class pub_meths class_init =
  let table = create_table pub_meths in
  let env_init = class_init table in
  init_class table;
  (env_init (Obj.repr 0), class_init, env_init, Obj.repr 0)

type init_table = { mutable env_init: t; mutable class_init: table -> t }

let make_class_store pub_meths class_init init_table =
  let table = create_table pub_meths in
  let env_init = class_init table in
  init_class table;
  init_table.class_init <- class_init;
  init_table.env_init <- env_init

let dummy_class loc =
  let undef = fun _ -> raise (Undefined_recursive_module loc) in
  (Obj.magic undef, undef, undef, Obj.repr 0)

(**** Objects ****)

let create_object table =
  (* XXX Appel de [obj_block] *)
  let obj = << new $table.constructor$() >> in
  set_id obj last_id;
  (Obj.obj obj)

let create_object_opt obj_0 table =
  if (Obj.magic obj_0 : bool) then obj_0 else begin
    (* XXX Appel de [obj_block] *)
    let obj = << new $table.constructor$() >> in
    set_id obj last_id;
    (Obj.obj obj)
  end

let rec iter_f obj =
  function
    []   -> ()
  | f::l -> <:stmt< _m($f$, $obj$, []); >>; iter_f obj l

let run_initializers obj table =
  let inits = table.initializers in
  if inits <> [] then
    iter_f obj inits

let run_initializers_opt obj_0 obj table =
  if (Obj.magic obj_0 : bool) then obj else begin
    let inits = table.initializers in
    if inits <> [] then iter_f obj inits;
    obj
  end

let create_object_and_run_initializers obj_0 table =
  if (Obj.magic obj_0 : bool) then obj_0 else begin
    let obj = create_object table in
    run_initializers obj table;
    obj
  end

(* Equivalent primitive below
let sendself obj lab =
  (magic obj : (obj -> t) array array).(0).(lab) obj
*)
external send : obj -> tag -> 'a = "%send"
external sendcache : obj -> tag -> t -> int -> 'a = "%sendcache"
external sendself : obj -> label -> 'a = "%sendself"
external get_public_method : obj -> tag -> closure
    = "caml_get_public_method" "noalloc"

(**** table collection access ****)

type tables = Empty | Cons of closure * tables * tables
type mut_tables =
    {key: closure; mutable data: tables; mutable next: tables}
external mut : tables -> mut_tables = "%identity"

let build_path n keys tables =
  let res = Cons (Obj.magic 0, Empty, Empty) in
  let r = ref res in
  for i = 0 to n do
    r := Cons (keys.(i), !r, Empty)
  done;
  tables.data <- !r;
  res

let rec lookup_keys i keys tables =
  if i < 0 then tables else
  let key = keys.(i) in
  let rec lookup_key tables =
    if tables.key == key then lookup_keys (i-1) keys tables.data else
    if tables.next <> Empty then lookup_key (mut tables.next) else
    let next = Cons (key, Empty, Empty) in
    tables.next <- next;
    build_path (i-1) keys (mut next)
  in
  lookup_key (mut tables)

let lookup_tables root keys =
  let root = mut root in
  if root.data <> Empty then
    lookup_keys (Array.length keys - 1) keys root.data
  else
    build_path (Array.length keys - 1) keys root

(**** builtin methods ****)

let get_const x =
  (* 
     hack so if you say
       let foo x = ...
       method foo = foo
     then the result can be called from Javascript with
       o.foo(x)
     instead of
       o.foo()(x)
  *)
  << typeof $x$ === "function" ? $x$ : $ret (fun obj -> x)$ >>

let get_var n   = ret (fun obj -> Array.unsafe_get << this >> n)
let get_env e n =
  ret (fun obj ->
    Array.unsafe_get (Obj.magic (Array.unsafe_get << this >> e) : obj) n)
let get_meth n  = ret (fun obj -> sendself << this >> n)
let set_var n   = ret (fun obj x -> Array.unsafe_set << this >> n x)
let app_const f x = ret (fun obj -> f x)
let app_var f n   = ret (fun obj -> f (Array.unsafe_get << this >> n))
let app_env f e n =
  ret (fun obj ->
    f (Array.unsafe_get (Obj.magic (Array.unsafe_get << this >> e) : obj) n))
let app_meth f n  = ret (fun obj -> f (sendself << this >> n))
let app_const_const f x y = ret (fun obj -> f x y)
let app_const_var f x n   = ret (fun obj -> f x (Array.unsafe_get << this >> n))
let app_const_meth f x n = ret (fun obj -> f x (sendself << this >> n))
let app_var_const f n x = ret (fun obj -> f (Array.unsafe_get << this >> n) x)
let app_meth_const f n x = ret (fun obj -> f (sendself << this >> n) x)
let app_const_env f x e n =
  ret (fun obj ->
    f x (Array.unsafe_get (Obj.magic (Array.unsafe_get << this >> e) : obj) n))
let app_env_const f e n x =
  ret (fun obj ->
    f (Array.unsafe_get (Obj.magic (Array.unsafe_get << this >> e) : obj) n) x)
let meth_app_const n x = ret (fun obj -> (sendself << this >> n : _ -> _) x)
let meth_app_var n m =
  ret (fun obj -> (sendself << this >> n : _ -> _) (Array.unsafe_get << this >> m))
let meth_app_env n e m =
  ret (fun obj -> (sendself << this >> n : _ -> _)
      (Array.unsafe_get (Obj.magic (Array.unsafe_get << this >> e) : obj) m))
let meth_app_meth n m =
  ret (fun obj -> (sendself << this >> n : _ -> _) (sendself << this >> m))
let send_const m x =
  ret (fun obj -> send x m)
let send_var m n =
  ret (fun obj ->
    send (Obj.magic (Array.unsafe_get << this >> n) : obj) m)
let send_env m e n =
  ret (fun obj ->
    send
      (Obj.magic (Array.unsafe_get
                    (Obj.magic (Array.unsafe_get << this >> e) : obj) n) : obj)
      m)
let send_meth m n =
  ret (fun obj ->
    send (sendself << this >> n) m)

type impl =
    GetConst
  | GetVar
  | GetEnv
  | GetMeth
  | SetVar
  | AppConst
  | AppVar
  | AppEnv
  | AppMeth
  | AppConstConst
  | AppConstVar
  | AppConstEnv
  | AppConstMeth
  | AppVarConst
  | AppEnvConst
  | AppMethConst
  | MethAppConst
  | MethAppVar
  | MethAppEnv
  | MethAppMeth
  | SendConst
  | SendVar
  | SendEnv
  | SendMeth
  | Closure of closure

let method_impl table i arr =
  let next () = incr i; magic arr.(!i) in
  match next() with
    GetConst -> let x : t = next() in get_const x
  | GetVar   -> let n = next() in get_var n
  | GetEnv   -> let e = next() and n = next() in get_env e n
  | GetMeth  -> let n = next() in get_meth n
  | SetVar   -> let n = next() in set_var n
  | AppConst -> let f = next() and x = next() in app_const f x
  | AppVar   -> let f = next() and n = next () in app_var f n
  | AppEnv   ->
      let f = next() and e = next() and n = next() in app_env f e n
  | AppMeth  -> let f = next() and n = next () in app_meth f n
  | AppConstConst ->
      let f = next() and x = next() and y = next() in app_const_const f x y
  | AppConstVar ->
      let f = next() and x = next() and n = next() in app_const_var f x n
  | AppConstEnv ->
      let f = next() and x = next() and e = next () and n = next() in
      app_const_env f x e n
  | AppConstMeth ->
      let f = next() and x = next() and n = next() in app_const_meth f x n
  | AppVarConst ->
      let f = next() and n = next() and x = next() in app_var_const f n x
  | AppEnvConst ->
      let f = next() and e = next () and n = next() and x = next() in
      app_env_const f e n x
  | AppMethConst ->
      let f = next() and n = next() and x = next() in app_meth_const f n x
  | MethAppConst ->
      let n = next() and x = next() in meth_app_const n x
  | MethAppVar ->
      let n = next() and m = next() in meth_app_var n m
  | MethAppEnv ->
      let n = next() and e = next() and m = next() in meth_app_env n e m
  | MethAppMeth ->
      let n = next() and m = next() in meth_app_meth n m
  | SendConst ->
      let m = next() and x = next() in send_const m x
  | SendVar ->
      let m = next() and n = next () in send_var m n
  | SendEnv ->
      let m = next() and e = next() and n = next() in
      send_env m e n
  | SendMeth ->
      let m = next() and n = next () in send_meth m n
  | Closure _ as clo -> magic clo

let set_methods table methods =
  let len = Array.length methods and i = ref 0 in
  while !i < len do
    let label = methods.(!i) and clo = method_impl table i methods in
    set_method table label clo;
    incr i
  done

(**** Statistics ****)

type stats =
  { classes: int; methods: int; inst_vars: int; }

let stats () =
  { classes = !table_count;
    methods = !method_count; inst_vars = !inst_var_count; }
