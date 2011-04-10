
exception MalFormed
exception InvalidCodepoint of int

type byte_order = Little_endian | Big_endian

let get_byte_order c0 c1 =
  match (Char.code c0, Char.code c1) with
    | (0xfe,0xff) -> Big_endian
    | (0xff,0xfe) -> Little_endian
    | _ -> raise MalFormed

let number_of_char_pair bo c1 c2 = match bo with
  | Little_endian -> ((Char.code c2) lsl 8) + (Char.code c1)
  | Big_endian -> ((Char.code c1) lsl 8) + (Char.code c2)

let char_pair_of_number bo num = match bo with
  | Little_endian ->
      (Char.chr (num land 0xFF), Char.chr ((num lsr 8) land 0xFF ))
  | Big_endian ->
      (Char.chr ((num lsr 8) land 0xFF), Char.chr (num land 0xFF))

let next_in_string bo s pos bytes =
  if (pos + 1 >= bytes) then raise MalFormed;
  number_of_char_pair bo s.[pos] s.[pos+1]

let next_code bo s pos bytes =
  let w1 = next_in_string bo s pos bytes in
  if w1 = 0xfffe then raise (InvalidCodepoint w1);
  if w1 < 0xd800 || 0xdfff < w1 then (w1, pos+2)
  else if w1 <= 0xdbff
  then
    let w2 = next_in_string bo s (pos + 2) bytes in
    if w2 < 0xdc00 || w2 > 0xdfff then raise MalFormed;
    let upper10 = (w1 land 0x3ff) lsl 10
    and lower10 = w2 land 0x3ff in
    (0x10000 + upper10 + lower10, pos + 4)
  else raise MalFormed
    
let next_in_stream bo s =
  let c1 = Stream.next s in
  let c2 = Stream.next s in
  number_of_char_pair bo c1 c2

let from_stream bo s w1 =
  if w1 = 0xfffe then raise (InvalidCodepoint w1);
  if w1 < 0xd800 || 0xdfff < w1 then w1
  else if w1 <= 0xdbff
  then
    let w2 = next_in_stream bo s in
    if w2 < 0xdc00 || w2 > 0xdfff then raise MalFormed;
    let upper10 = (w1 land 0x3ff) lsl 10
    and lower10 = w2 land 0x3ff in
    0x10000 + upper10 + lower10
  else raise MalFormed

let stream_from_char_stream opt_bo s =
  let bo = ref opt_bo in
  Stream.from
    (fun _ ->
       try
         let c1 = Stream.next s in
         let c2 = Stream.next s in
         let o = match !bo with
           | Some o -> o
           | None ->
               let o = match (Char.code c1, Char.code c2) with
                 | (0xff,0xfe) -> Little_endian
                 | _ -> Big_endian in
               bo := Some o;
               o in
         Some (from_stream o s (number_of_char_pair o c1 c2))
       with Stream.Failure -> None)
    

let compute_len opt_bo str pos bytes =
  let s = stream_from_char_stream opt_bo
    (Stream.from (fun i -> if i + pos >= bytes then None
                  else Some (str.[i + pos])))
  in 
  let l = ref 0 in
  Stream.iter (fun _ -> incr l) s ;
  !l

let rec blit_to_int opt_bo s spos a apos bytes =
  let s = stream_from_char_stream opt_bo
    (Stream.from (fun i -> if i+spos >= bytes then None
                  else Some (s.[i + spos]))) in
  let p = ref apos in
  try while true do a.(!p) <- Stream.next s ; incr p done; assert false
  with Stream.Failure -> ()
    
let to_int_array opt_bo s pos bytes =
  let len = compute_len opt_bo s pos bytes in
  let a = Array.create len 0 in
  blit_to_int opt_bo s pos a 0 bytes ;
  a
    
let store bo buf code =
  if code < 0x10000
  then (
    let (c1,c2) = char_pair_of_number bo code in
    Buffer.add_char buf c1;
    Buffer.add_char buf c2
  ) else (
    let u' = code - 0x10000  in
    let w1 = 0xd800 + (u' lsr 10)
    and w2 = 0xdc00 + (u' land 0x3ff) in
    let (c1,c2) = char_pair_of_number bo w1
    and (c3,c4) = char_pair_of_number bo w2 in
    Buffer.add_char buf c1;
    Buffer.add_char buf c2;
    Buffer.add_char buf c3;
    Buffer.add_char buf c4
  )

let from_int_array bo a apos len bom =
  let b = Buffer.create (len * 4) in
  if bom then store bo b 0xfeff ; (* first, store the BOM *)
  let rec aux apos len =
    if len > 0
    then (store bo b a.(apos); aux (succ apos) (pred len))
    else Buffer.contents b  in
  aux apos len


let from_stream bo s =
  from_stream bo s (next_in_stream bo s)



let from_utf16_stream s opt_bo =
  Ulexing.from_stream (stream_from_char_stream opt_bo s)

let from_utf16_channel ic opt_bo =
  from_utf16_stream ((Stream.of_channel ic)) opt_bo
    
let from_utf16_string s opt_bo =
  let a = to_int_array opt_bo s 0 (String.length s) in
  Ulexing.from_int_array a
       
let utf16_sub_lexeme lb pos len bo bom  =
  from_int_array bo (Ulexing.get_buf lb) (Ulexing.get_start lb + pos) len bom

let utf16_lexeme lb bo bom =
  utf16_sub_lexeme lb 0 (Ulexing.get_pos lb - Ulexing.get_start lb) bo bom
