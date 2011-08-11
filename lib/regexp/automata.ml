
open Regular_expr

type automaton =
    {
      auto_trans : (int * int array) array;
      auto_accept : bool array;
    }


let exec_automaton auto s pos =
  let state = ref 0
  and last_accept_pos = ref (if auto.auto_accept.(0) then pos else -1)
  and i = ref pos
  and l = String.length s
  in
  try
    while !i < l do
      let (offset,m) = auto.auto_trans.(!state) in
      let index = Char.code(String.get s !i)-offset in
      if index <0 || index >= Array.length m then raise Exit;
      state := m.(index);
      if !state = -1 then raise Exit;
      incr i;
      if auto.auto_accept.(!state) then last_accept_pos := !i;
    done;
    !last_accept_pos;
  with
    Exit -> !last_accept_pos


let match_string a s i =
  let res = exec_automaton a s i in
  if res = -1 then
    None
  else
    Some (res - i)


let rec search_forward auto s pos =
  if pos >= String.length s then begin
    raise Not_found
  end else begin
    let n = exec_automaton auto s pos in
    if n > pos then
      pos,n
    else
      search_forward auto s (succ pos)
  end


let split_strings auto line =
  let rec loop pos =
    try
      let b,e = search_forward auto line pos in
      let id = String.sub line b (e-b) in
      id::(loop e)
    with
      Not_found -> []
  in
  loop 0


let split_delim auto line  =
  let rec loop pos =
    try
      let b,e = search_forward auto line pos in
      let id = String.sub line pos (b-pos) in
      id::(loop e)
    with
      Not_found -> [String.sub line pos (String.length line - pos)]
  in
  loop 0

let replace auto line replacement =
  String.concat replacement (split_delim auto line)

let substitute auto line map =
  let rec loop pos =
    try
      let b,e = search_forward auto line pos in
      let id = String.sub line pos (b-pos) in
      id :: map (String.sub line b (e - b)) :: loop e
    with
      Not_found -> [String.sub line pos (String.length line - pos)]
  in
  String.concat "" (loop 0)


module IntMap = Inttagmap.Make(struct type t = int let tag x = x end)
module IntSet = Inttagset.Make(struct type t = int let tag x = x end)

let rec compute_max b l =
  match l with
  | [] -> b
  | (_,x,_)::r -> compute_max x l

module HashRegexp =
  Hashtbl.Make
    (struct
      type t    = Regular_expr.regexp
      let equal = (==)
      let hash  = Regular_expr.uniq_tag
    end)


let compile r =

  (*[hashtabl] to avoid several compilation of the same regexp,
    [transtable] is the transition table to fill, and
    [acceptable] is the table of accepting states.

    [transtable] maps any state into a [CharMap.t], which itself maps characters
    to states. *)

  let hashtable = HashRegexp.create 257
  and transtable = ref IntMap.empty
  and acceptable = ref IntSet.empty
  and next_state = ref 0
  in

  (* [loop r] fills the tables for the regexp [r], and return the
     initial state  of the resulting automaton. *)

  let rec loop r =
    try
      HashRegexp.find hashtable r
    with
    Not_found ->
      (* generate a new state *)
      let init = !next_state
      and next_chars = Regular_expr.firstchars r
      in
      incr next_state;
      HashRegexp.add hashtable r init;
      if nullable r then acceptable := IntSet.add init !acceptable;
      let t = build_sparse_array next_chars in
      transtable := IntMap.add init t !transtable;
      init

  and build_sparse_array next_chars =
    match next_chars with
      | [] -> (0,[||])
      | (a,b,_)::r ->
      let mini = a
      and maxi = List.fold_left (fun _ (_,x,_) -> x) b r
      in
      let t = Array.create (maxi-mini+1) (-1) in
      List.iter
        (fun (a,b,r) ->
          let s = loop r in
          for i=a to b do
            t.(i-mini) <- s
          done)
        next_chars;
      (mini,t)

  in
  let _ = loop r in

  (* we then fill the arrays defining the automaton *)
  {
    auto_trans = Array.init !next_state (fun i -> IntMap.find i !transtable);
    auto_accept = Array.init !next_state (fun i -> IntSet.mem i !acceptable);
  }
