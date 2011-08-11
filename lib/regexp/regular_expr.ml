
(*


\subsection{regexp datatype and simplifying constructors}

*)

open Hashcons;;

type regexp = regexp_struct Hashcons.hash_consed

and regexp_struct =
  | Empty
  | Epsilon
  | Char_interv of int * int
  | String of string          (*r length at least 2 *)
  | Star of regexp
  | Alt of regexp_struct Ptset.t
  | Seq of regexp * regexp
;;

let uniq_tag r = r.tag;;

let regexp_eq (r1,r2) =
  match (r1,r2) with
    | Empty,Empty -> true
    | Epsilon,Epsilon -> true
    | Alt s1,Alt s2 -> Ptset.equalq s1 s2
    | Star r1,Star r2 -> r1 == r2
    | Seq(s11,s12),Seq(s21,s22) -> s11 == s21 && s12 == s22
    | String s1,String s2 -> s1=s2
    | Char_interv(a1,b1),Char_interv(a2,b2) -> a1==a2 && b1 == b2
    | _ -> false

module Hash = Hashcons.Make(struct type t = regexp_struct
                   let equal = regexp_eq
                   let hash = Hashtbl.hash end)

let hash_consing_table = Hash.create 257;;

let hash_cons = Hash.hashcons hash_consing_table

let empty = hash_cons Empty;;

let epsilon = hash_cons Epsilon;;

let star e =
  match e.node with
    | Empty | Epsilon -> epsilon
    | Star _ -> e
    | _ -> hash_cons (Star e)
;;

let alt e1 e2 =
  match e1.node,e2.node with
    | Empty,_ -> e2
    | _,Empty -> e1
    | Alt(l1),Alt(l2) -> hash_cons (Alt(Ptset.union l1 l2))
    | Alt(l1),_ -> hash_cons(Alt(Ptset.add e2 l1))
    | _,Alt(l2) -> hash_cons(Alt(Ptset.add e1 l2))
    | _ ->
    if e1==e2 then e1
    else hash_cons(Alt(Ptset.add e1 (Ptset.singleton e2)))
;;

let seq e1 e2 =
  match e1.node,e2.node with
    | Empty,_ -> empty
    | _,Empty -> empty
    | Epsilon,_ -> e2
    | _,Epsilon -> e1
    | _ -> hash_cons(Seq(e1,e2))
;;

let char c = let c = Char.code c in hash_cons(Char_interv(c,c))

let char_interv a b = hash_cons(Char_interv(Char.code a,Char.code b))

let string s =
  if s=""
  then
    epsilon
  else
    if String.length s = 1
    then let c = String.get s 0 in char c
    else hash_cons(String s);;

(*

\subsection{extended regexp}

*)




let some e = (seq e (star e));;

let opt e = (alt e epsilon);;

(*

  \subsection{Regexp match by run-time interpretation of regexp}

*)

let rec nullable r =
  match r.node with
    | Empty -> false
    | Epsilon ->  true
    | Char_interv(n1,n2) -> false
    | String _ -> false  (*r cannot be [""] *)
    | Star e -> true
    | Alt(l) -> Ptset.exists nullable l
    | Seq(e1,e2) -> nullable e1 && nullable e2
;;

let rec residual r c =
  match r.node with
    | Empty -> empty
    | Epsilon ->  empty
    | Char_interv(a,b) -> if a<=c && c<=b then epsilon else empty
    | String s -> (*r [s] cannot be [""] *)
    if c=Char.code(String.get s 0)
    then string (String.sub s 1 (pred (String.length s)))
    else empty
    | Star e -> seq (residual e c) r
    | Alt(l) ->
    Ptset.fold
      (fun e accu -> alt (residual e c) accu)
      l
      empty
    | Seq(e1,e2) ->
    if nullable(e1)
    then alt (seq (residual e1 c) e2) (residual e2 c)
    else seq (residual e1 c) e2
;;

let match_string r s =
  let e = ref r in
  for i=0 to pred (String.length s) do
    e := residual !e (Char.code(String.get s i))
  done;
  nullable !e
;;

(*

  [firstchars r] returns the set of characters that may start a word
  in the language of [r]

*)

let add a b r l = if a>b then l else (a,b,r)::l

let rec insert a b r l =
  match l with
    | [] -> [(a,b,r)]
    | (a1,b1,r1)::rest ->
    if b < a1
    then
      (* a <= b < a1 <= b1 *)
      (a,b,r)::l
    else
      if b <= b1
      then
        if a <= a1
        then
          (* a <= a1 <= b <= b1 *)
          add a (a1-1) r ((a1,b,alt r r1)::(add (b+1) b1 r1 rest))
        else
          (* a1 < a <= b <= b1 *)
          (a1,a-1,r1)::(a,b,alt r r1)::(add (b+1) b1 r1 rest)
      else
        if a <= a1
        then
          (* a <= a1 <= b1 < b *)
          add a (a1-1) r ((a1,b1,alt r r1)::(insert (b1+1) b r rest))
        else
          if a <= b1
          then
        (* a1 < a <= b1 < b *)
        (a1,a-1,r1)::(a,b1,alt r r1)::(insert (b1+1) b r rest)
          else
        (* a1 <= b1 < a <= b *)
        (a1,b1,r1)::(insert a b r rest)

let insert_list l1 l2 =
  List.fold_right
    (fun (a,b,r) accu -> insert a b r accu)
    l1
    l2
;;


let rec firstchars r =
  match r.node with
    | Empty -> []
    | Epsilon ->  []
    | Char_interv(a,b) -> [(a,b,epsilon)]
    | String s ->
    let c=Char.code(String.get s 0) in
    [(c,c,string (String.sub s 1 (pred (String.length s))))]
    | Star e ->
    let l = firstchars e in
    List.map (fun (a,b,res) -> (a,b,seq res r)) l
    | Alt(s) ->
    Ptset.fold
      (fun e accu -> insert_list (firstchars e) accu)
      s
      []
    | Seq(e1,e2) ->
    if nullable e1
    then
      let l1 = firstchars e1 and l2 = firstchars e2 in
      insert_list
        (List.map (fun (a,b,res) -> (a,b,seq res e2)) l1)
        l2
    else
      let l1 = firstchars e1 in
      List.map (fun (a,b,res) -> (a,b,seq res e2)) l1
;;

let _ =
  let r = seq(star (alt (char 'a') (char 'b'))) (char 'c') in
  firstchars r;;




open Format;;

let rec fprint fmt r =
  match r.node with
    | Empty -> fprintf fmt "(empty)"
    | Epsilon ->  fprintf fmt "(epsilon)"
    | Char_interv(a,b) -> fprintf fmt "['%c'-'%c']" (Char.chr a) (Char.chr b)
    | String s -> fprintf fmt "\"%s\"" s
    | Star e -> fprintf fmt "(%a)*" fprint e
    | Alt(l) ->
    fprintf fmt "(";
    Ptset.iter (fun e -> fprintf fmt "|%a" fprint e) l;
    fprintf fmt ")"
    | Seq(e1,e2) -> fprintf fmt "(%a %a)" fprint e1 fprint e2
;;

let print = fprint std_formatter;;
