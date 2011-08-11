(*----------------------------------------------------------------------------
   Copyright (c) 2007-2009, Daniel C. Bünzli. All rights reserved.
   Distributed under a BSD license, see license at the end of the file.
   Xmlm version 1.0.2
  ----------------------------------------------------------------------------*)

module Std_string = String
module Std_buffer = Buffer
    
type std_string = string
type std_buffer = Buffer.t
      
module type XMLString = sig
  type t
  val empty : t
  val length : t -> int
  val append : t -> t -> t
  val lowercase : t -> t
  val iter : (int -> unit) -> t -> unit
  val of_string : std_string -> t
  val to_utf_8 : ('a -> std_string -> 'a) -> 'a -> t -> 'a
  val compare : t -> t -> int
end
      
module type XMLBuffer = sig
  type string
  type t 
  exception Full
  val create : int -> t
  val add_uchar : t -> int -> unit
  val clear : t -> unit
  val contents : t -> string
  val length : t -> int
end

module type S = sig 
  type string 
  type encoding = [ 
    | `UTF_8 | `UTF_16 | `UTF_16BE | `UTF_16LE | `ISO_8859_1 | `US_ASCII ]
  type dtd = string option
  type name = string * string 
  type attribute = name * string
  type tag = name * attribute list
  type signal = [ `Dtd of dtd | `El_start of tag | `El_end | `Data of string |`Raw of string ]
    
  val ns_xml : string 
  val ns_xmlns : string

  type pos = int * int 
  type error = [
    | `Max_buffer_size			
    | `Unexpected_eoi
    | `Malformed_char_stream
    | `Unknown_encoding of string
    | `Unknown_entity_ref of string				 
    | `Unknown_ns_prefix of string				
    | `Illegal_char_ref of string 
    | `Illegal_char_seq of string 
    | `Expected_char_seqs of string list * string
    | `Expected_root_element ]	

  exception Error of pos * error
  val error_message : error -> string      

  type source = [ 
    | `String of int * std_string 
    | `Fun of (unit -> int) ]

  type input 
	
  val make_input :
    ?templates:bool ->
    ?enc:encoding option ->
    ?strip:bool -> 
    ?ns:(string -> string option) -> 
	  ?entity: (string -> string option) -> source -> input
	  
  val input : input -> signal

  val input_tree : el:(tag -> 'a list -> 'a) -> data:(string -> 'a)  -> 
                   input -> 'a

  val input_doc_tree : el:(tag -> 'a list -> 'a) -> data:(string -> 'a) -> 
                       input -> (dtd * 'a)
    
  val peek : input -> signal
  val eoi : input -> bool
  val pos : input -> pos 

  type 'a frag = [ `El of tag * 'a list | `Data of string ]
  type t = (('a frag as 'a) frag) list
  type dest = [ 
    `Buffer of std_buffer | `Fun of (int -> unit) ]

  type output
  val make_output : ?nl:bool -> ?indent:int option -> 
                    ?ns_prefix:(string -> string option) -> dest -> output

  val output : output -> signal -> unit
  val output_tree : ('a -> 'a frag) -> output -> 'a -> unit
  val output_doc_tree : ('a -> 'a frag) -> output -> (dtd * 'a) -> unit   
end


(* Unicode character lexers *)
      
exception Malformed                 (* for character stream, internal only. *)

let utf8_len = [|        (* Char byte length according to first UTF-8 byte. *)
  1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 
  1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 
  1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 
  1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 
  1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 
  1; 1; 1; 1; 1; 1; 1; 1; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 
  0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 
  0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 
  0; 0; 2; 2; 2; 2; 2; 2; 2; 2; 2; 2; 2; 2; 2; 2; 2; 2; 2; 2; 2; 2; 2; 2; 
  2; 2; 2; 2; 2; 2; 2; 2; 3; 3; 3; 3; 3; 3; 3; 3; 3; 3; 3; 3; 3; 3; 3; 3; 
  4; 4; 4; 4; 4; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0 |]
    
let uchar_utf8 i =
  let b0 = i () in
  begin match utf8_len.(b0) with
  | 0 -> raise Malformed
  | 1 -> b0
  | 2 ->
      let b1 = i () in
      if b1 lsr 6 != 0b10 then raise Malformed else
      ((b0 land 0x1F) lsl 6) lor (b1 land 0x3F)
  | 3 ->
      let b1 = i () in
      let b2 = i () in
      if b2 lsr 6 != 0b10 then raise Malformed else
      begin match b0 with
      | 0xE0 -> if b1 < 0xA0 || 0xBF < b1 then raise Malformed else ()
      | 0xED -> if b1 < 0x80 || 0x9F < b1 then raise Malformed else ()
      | _ -> if b1 lsr 6 != 0b10 then raise Malformed else ()
      end;
      ((b0 land 0x0F) lsl 12) lor ((b1 land 0x3F) lsl 6) lor (b2 land 0x3F)
  | 4 -> 
      let b1 = i () in
      let b2 = i () in
      let b3 = i () in
      if  b3 lsr 6 != 0b10 || b2 lsr 6 != 0b10 then raise Malformed else
      begin match b0 with
      | 0xF0 -> if b1 < 0x90 || 0xBF < b1 then raise Malformed else ()
      | 0xF4 -> if b1 < 0x80 || 0x8F < b1 then raise Malformed else ()
      | _ -> if b1 lsr 6 != 0b10 then raise Malformed else ()
      end;
      ((b0 land 0x07) lsl 18) lor ((b1 land 0x3F) lsl 12) lor 
      ((b2 land 0x3F) lsl 6) lor (b3 land 0x3F)
  | _ -> assert false	
  end
    
let int16_be i = 
  let b0 = i () in
  let b1 = i () in
  (b0 lsl 8) lor b1
    
let int16_le i = 
  let b0 = i () in
  let b1 = i () in
  (b1 lsl 8) lor b0 
    
let uchar_utf16 int16 i = 
  let c0 = int16 i in
  if c0 < 0xD800 || c0 > 0xDFFF then c0 else
  if c0 >= 0xDBFF then raise Malformed else
  let c1 = int16 i in
  (((c0 land 0x3FF) lsl 10) lor (c1 land 0x3FF)) + 0x10000
    
let uchar_utf16be = uchar_utf16 int16_be
let uchar_utf16le = uchar_utf16 int16_le 
let uchar_byte i = i ()
let uchar_iso_8859_1 i = i ()
let uchar_ascii i = let b = i () in if b > 127 then raise Malformed else b

(* Functorized streaming XML IO *)

module Make (String : XMLString) (Buffer : XMLBuffer with type string = String.t) = 
struct
  type string = String.t
	
  let str = String.of_string
  let str_eq s s' = (compare s s') = 0
  let str_empty s = (compare s String.empty) = 0
  let cat = String.append 
  let str_of_char u = 
    let b = Buffer.create 4 in 
    Buffer.add_uchar b u;
    Buffer.contents b

  module Ht = Hashtbl.Make (struct type t = string 
	                           let equal = str_eq
				   let hash = Hashtbl.hash end)
      
  let u_nl = 0x000A     (* newline *)
  let u_cr = 0x000D     (* carriage return *)
  let u_space = 0x0020  (* space *)
  let u_quot = 0x0022   (* quote *)
  let u_sharp = 0x0023  (* # *)
  let u_amp = 0x0026    (* & *)
  let u_apos = 0x0027   (* ' *)
  let u_minus = 0x002D  (* - *)
  let u_slash = 0x002F  (* / *)
  let u_colon = 0x003A  (* : *)
  let u_scolon = 0x003B (* ; *)
  let u_lt = 0x003C     (* < *)
  let u_eq = 0x003D     (* = *)
  let u_gt = 0x003E     (* > *)
  let u_qmark = 0x003F  (* ? *)
  let u_emark = 0x0021  (* ! *)
  let u_lbrack = 0x005B (* [ *)
  let u_rbrack = 0x005D (* ] *)
  let u_x = 0x0078      (* x *)
  let u_bom = 0xFEFF    (* BOM *)
  let u_9 = 0x0039      (* 9 *)
  let u_F = 0x0046      (* F *)
  let u_D = 0X0044      (* D *)
  let u_dollar = 0X0024 (* dollar *)
      
  let s_cdata = str "CDATA["      
  let ns_xml = str "http://www.w3.org/XML/1998/namespace"
  let ns_xmlns = str "http://www.w3.org/2000/xmlns/"      
  let n_xml = str "xml"
  let n_xmlns = str "xmlns"
  let n_space = str "space"
  let n_version = str "version"
  let n_encoding = str "encoding"
  let n_standalone = str "standalone"
  let v_yes = str "yes"
  let v_no = str "no"
  let v_preserve = str "preserve"
  let v_default = str "default"
  let v_version_1_0 = str "1.0"
  let v_version_1_1 = str "1.1"
  let v_utf_8 = str "utf-8"
  let v_utf_16 = str "utf-16"
  let v_utf_16be = str "utf-16be"
  let v_utf_16le = str "utf-16le"
  let v_iso_8859_1 = str "iso-8859-1"
  let v_us_ascii = str "us-ascii" 
  let v_ascii = str "ascii"
      
  let name_str (p,l) = if str_empty p then l else cat p (cat (str ":") l)
      
  (* Basic types and values *)

  type encoding = [ 
    | `UTF_8 | `UTF_16 | `UTF_16BE | `UTF_16LE | `ISO_8859_1 | `US_ASCII ]
  type dtd = string option
  type name = string * string 
  type attribute = name * string
  type tag = name * attribute list
  type signal = [ `Dtd of dtd | `El_start of tag | `El_end | `Data of string | `Raw of string ]

  (* Input *)
    
  type pos = int * int 
  type error = [
    | `Max_buffer_size			
    | `Unexpected_eoi
    | `Malformed_char_stream
    | `Unknown_encoding of string
    | `Unknown_entity_ref of string
    | `Unknown_ns_prefix of string				
    | `Illegal_char_ref of string 
    | `Illegal_char_seq of string 
    | `Expected_char_seqs of string list * string
    | `Expected_root_element ]
	
  exception Error of pos * error

  let error_message e = 
    let bracket l v r = cat (str l) (cat v (str r)) in
    match e with
    | `Expected_root_element -> str "expected root element"
    | `Max_buffer_size -> str "maximal buffer size exceeded"
    | `Unexpected_eoi -> str "unexpected end of input"
    | `Malformed_char_stream -> str "malformed character stream"
    | `Unknown_encoding e -> bracket "unknown encoding (" e ")"
    | `Unknown_entity_ref e -> bracket "unknown entity reference (" e ")"
    | `Unknown_ns_prefix e -> bracket "unknown namespace prefix (" e ")"
    | `Illegal_char_ref s -> bracket "illegal character reference (#" s ")"
    | `Illegal_char_seq s ->
	bracket "character sequence illegal here (\"" s "\")"
    | `Expected_char_seqs (exps, fnd) -> 
	let exps = 
	  let exp acc v = cat acc (bracket "\"" v "\", ") in
	  List.fold_left exp String.empty exps
	in
	cat (str "expected one of these character sequence: ") 
	  (cat exps (bracket "found \"" fnd "\""))

  type limit =                                        (* XML is odd to parse. *)
    | Stag of name   (* '<' qname *) 
    | Etag of name   (* '</' qname whitespace* *) 
    | Pi of name     (* '<?' qname *) 
    | Comment        (* '<!--' *)
    | Cdata          (* '<![CDATA[' *)
    | Dtd            (* '<!' *) 
    | Text           (* other character *)
    | Eoi            (* End of input *)
    | Dollar         (* Template *)
	
  type source = [ 
    | `String of int * std_string
    | `Fun of (unit -> int) ]

  type input = 
    { enc : encoding option;                            (* Expected encoding. *)
      strip : bool;                (* Whitespace stripping default behaviour. *)
      fun_ns : string -> string option;                (* Namespace callback. *)
      fun_entity : string -> string option;     (* Entity reference callback. *)
      i : unit -> int;                                   (* Byte level input. *)
      templates : bool;                                    (* parse templates *)
      mutable uchar : (unit -> int) -> int;       (* Unicode character lexer. *)
      mutable c : int;                                (* Character lookahead. *)
      mutable cr : bool;                          (* True if last u was '\r'. *)
      mutable line : int;                             (* Current line number. *)
      mutable col : int;                            (* Current column number. *)
      mutable limit : limit;                            (* Last parsed limit. *)
      mutable peek : signal;                             (* Signal lookahead. *)
      mutable stripping : bool;              (* True if stripping whitespace. *)
      mutable last_white : bool;              (* True if last char was white. *)
      mutable scopes : (name * string list * bool) list;
          (* Stack of qualified el. name, bound prefixes and strip behaviour. *)
      ns : string Ht.t;                            (* prefix -> uri bindings. *)
      ident : Buffer.t;                  (* Buffer for names and entity refs. *)
      data : Buffer.t; }          (* Buffer for character and attribute data. *)

  let err_input_tree = "input signal not `El_start or `Data"
  let err_input_doc_tree = "input signal not `Dtd"
  let err i e = raise (Error ((i.line, i.col), e))
  let err_illegal_char i u = err i (`Illegal_char_seq (str_of_char u))
  let err_expected_seqs i exps s = err i (`Expected_char_seqs (exps, s))
  let err_expected_chars i exps = 
    err i (`Expected_char_seqs (List.map str_of_char exps, str_of_char i.c))

  let u_eoi = max_int
  let u_start_doc = u_eoi - 1
  let u_end_doc = u_start_doc - 1
  let signal_start_stream = `Data String.empty

  let make_input
      ?(templates = false)
      ?(enc = None)
      ?(strip = false)
      ?(ns = fun _ -> None) 
      ?(entity = fun _ -> None)
      src = 
    let i = match src with
    | `Fun f -> f
    | `String (pos, s) -> 
	let len = Std_string.length s in
	let pos = ref (pos - 1) in
	fun () -> 
	  incr pos;
	  if !pos = len then raise End_of_file else 
	  Char.code (Std_string.get s !pos)
    in
    let bindings = 
      let h = Ht.create 15 in 
      Ht.add h String.empty String.empty;
      Ht.add h n_xml ns_xml;
      Ht.add h n_xmlns ns_xmlns;
      h
    in
    { enc = enc; strip = strip; fun_ns  = ns; fun_entity = entity; templates;
      i = i; uchar = uchar_byte; c = u_start_doc; cr = false;
      line = 1; col = 0; limit = Text; peek = signal_start_stream; 
      stripping = strip; last_white = true; scopes = []; ns = bindings; 
      ident = Buffer.create 64; data = Buffer.create 1024; }
      
(* Bracketed non-terminals in comments refer to XML 1.0 non terminals *)

  let r : int -> int -> int -> bool = fun u a b -> a <= u && u <= b
  let is_white = function 0x0020 | 0x0009 | 0x000D | 0x000A -> true | _ -> false
  
  let is_char = function                                            (* {Char} *)
    | u when r u 0x0020 0xD7FF -> true
    | 0x0009 | 0x000A | 0x000D -> true
    | u when r u 0xE000 0xFFFD
    || r u 0x10000 0x10FFFF -> true
    | _ -> false

  let is_digit u = r u 0x0030 0x0039
  let is_hex_digit u = 
    r u 0x0030 0x0039 || r u 0x0041 0x0046 || r u 0x0061 0x0066
	  
  let comm_range u = r u 0x00C0 0x00D6           (* common to functions below *)
  || r u 0x00D8 0x00F6 || r u 0x00F8 0x02FF || r u 0x0370 0x037D 
  || r u 0x037F 0x1FFF || r u 0x200C 0x200D || r u 0x2070 0x218F
  || r u 0x2C00 0x2FEF || r u 0x3001 0xD7FF || r u 0xF900 0xFDCF 
  || r u 0xFDF0 0xFFFD || r u 0x10000 0xEFFFF
      
  let is_name_start_char = function        (* {NameStartChar} - ':' (XML 1.1) *)
    | u when r u 0x0061 0x007A || r u 0x0041 0x005A -> true  (* [a-z] | [A-Z] *)
    | u when is_white u -> false
    | 0x005F -> true                                                   (* '_' *)
    | u when comm_range u -> true 
    | _ -> false
	  
  let is_name_char = function                   (* {NameChar} - ':' (XML 1.1) *)
    | u when r u 0x0061 0x007A || r u 0x0041 0x005A -> true  (* [a-z] | [A-Z] *)
    | u when is_white u -> false
    | u when  r u 0x0030 0x0039 -> true                              (* [0-9] *)
    | 0x005F | 0x002D | 0x002E | 0x00B7 -> true                (* '_' '-' '.' *)
    | u when comm_range u || r u 0x0300 0x036F || r u 0x203F 0x2040 -> true
    | _ -> false

  let rec nextc i =                    
    if i.c = u_eoi then err i `Unexpected_eoi;
    if i.c = u_nl then (i.line <- i.line + 1; i.col <- 1) 
    else i.col <- i.col + 1;
    i.c <- i.uchar i.i;
    if not (is_char i.c) then raise Malformed;
    if i.cr && i.c = u_nl then i.c <- i.uchar i.i;       (* cr nl business *)
    if i.c = u_cr then (i.cr <- true; i.c <- u_nl) else i.cr <- false
	  
  let nextc_eof i = try nextc i with End_of_file -> i.c <- u_eoi
  let skip_white i = while (is_white i.c) do nextc i done        
  let skip_white_eof i = while (is_white i.c) do nextc_eof i done
  let accept i c = if i.c = c then nextc i else err_expected_chars i [ c ]

  let clear_ident i = Buffer.clear i.ident
  let clear_data i = Buffer.clear i.data
  let addc_ident i c = Buffer.add_uchar i.ident c
  let addc_data i c = Buffer.add_uchar i.data c

  let addc_data_strip i c = 
    if is_white c then i.last_white <- true else
    begin
      if i.last_white && Buffer.length i.data <> 0 then addc_data i u_space;
      i.last_white <- false;
      addc_data i c
    end
      
  let expand_name i (prefix, local) = 
    let external_ prefix = match i.fun_ns prefix with
    | None -> err i (`Unknown_ns_prefix prefix)
    | Some uri -> uri
    in
    try
      let uri = Ht.find i.ns prefix in 
      if not (str_empty uri) then (uri, local) else
      if str_empty prefix then String.empty, local else 
      (external_ prefix), local              (* unbound with xmlns:prefix="" *)
    with Not_found -> external_ prefix, local

  let find_encoding i =                                    (* Encoding mess. *)
    let reset uchar i = i.uchar <- uchar; i.col <- 0; nextc i in 
    match i.enc with
    | None ->                                 (* User doesn't know encoding. *)
	begin match nextc i; i.c with          
	| 0xFE ->                                           (* UTF-16BE BOM. *)
	    nextc i; if i.c <> 0xFF then err i `Malformed_char_stream;
	    reset uchar_utf16be i;
	    true                                 
	| 0xFF ->                                           (* UTF-16LE BOM. *)
	    nextc i; if i.c <> 0xFE then err i `Malformed_char_stream;
	    reset uchar_utf16le i;
	    true   
        | 0xEF ->                                              (* UTF-8 BOM. *)
	    nextc i; if i.c <> 0xBB then err i `Malformed_char_stream;
	    nextc i; if i.c <> 0xBF then err i `Malformed_char_stream;
	    reset uchar_utf8 i;
	    true
	| 0x3C | _ ->                    (* UTF-8 or other, try declaration. *)
	    i.uchar <- uchar_utf8; 
	    false  
	end
    | Some e ->                                      (* User knows encoding. *)
	begin match e with                              
	| `US_ASCII -> reset uchar_ascii i
	| `ISO_8859_1 -> reset uchar_iso_8859_1 i
	| `UTF_8 ->                                  (* Skip BOM if present. *)
	    reset uchar_utf8 i; if i.c = u_bom then (i.col <- 0; nextc i)
	| `UTF_16 ->                             (* Which UTF-16 ? look BOM. *)
	    let b0 = nextc i; i.c in
	    let b1 = nextc i; i.c in
	    begin match b0, b1 with                
	    | 0xFE, 0xFF -> reset uchar_utf16be i
	    | 0xFF, 0xFE -> reset uchar_utf16le i
	    | _ -> err i `Malformed_char_stream;
	    end
	| `UTF_16BE ->                               (* Skip BOM if present. *)
	    reset uchar_utf16be i; if i.c = u_bom then (i.col <- 0; nextc i)
	| `UTF_16LE ->
	    reset uchar_utf16le i; if i.c = u_bom then (i.col <- 0; nextc i)
	end;
	true                                      (* Ignore xml declaration. *)


  let p_ncname i =                               (* {NCName} (Namespace 1.1) *)	
    clear_ident i;
    if not (is_name_start_char i.c) then err_illegal_char i i.c else
    begin 
      addc_ident i i.c; nextc i;
      while is_name_char i.c do addc_ident i i.c; nextc i done;
      Buffer.contents i.ident
    end
    
  let p_qname i =                                 (* {QName} (Namespace 1.1) *)
    let n = p_ncname i in
    if i.c <> u_colon then (String.empty, n) else (nextc i; (n, p_ncname i))
      
  let p_charref i =                             (* {CharRef}, '&' was eaten. *) 
    let c = ref 0 in
    clear_ident i;
    nextc i;
    if i.c = u_scolon then err i (`Illegal_char_ref String.empty) else
    begin 
      try
	if i.c = u_x then 
	  begin 
	    addc_ident i i.c;
	    nextc i;
	    while (i.c <> u_scolon) do 
	      addc_ident i i.c;               
	      if not (is_hex_digit i.c) then raise Exit else 
	      c := !c * 16 + (if i.c <= u_9 then i.c - 48 else
	                      if i.c <= u_F then i.c - 55 else 
			      i.c - 87);
	      nextc i;
	    done
	  end
	else
	  while (i.c <> u_scolon) do 
	    addc_ident i i.c;
	    if not (is_digit i.c) then raise Exit else 
	    c := !c * 10 + (i.c - 48);
	    nextc i
	  done
      with Exit -> 
	c := -1; while i.c <> u_scolon do addc_ident i i.c; nextc i done
    end;
    nextc i;
    if is_char !c then (clear_ident i; addc_ident i !c; Buffer.contents i.ident)
    else err i (`Illegal_char_ref (Buffer.contents i.ident))
	
  let predefined_entities = 
    let h = Ht.create 5 in
    let e k v = Ht.add h (str k) (str v) in
    e "lt" "<"; e "gt" ">"; e "amp" "&"; e "apos" "'"; e "quot" "\""; 
    h
      
  let p_entity_ref i =                        (* {EntityRef}, '&' was eaten. *)
    let ent = p_ncname i in
    accept i u_scolon;
    try Ht.find predefined_entities ent with Not_found -> 
      match i.fun_entity ent with
      | Some s -> s
      | None -> err i (`Unknown_entity_ref ent)

  let p_reference i =                                        (* {Reference} *)
    nextc i; if i.c = u_sharp then p_charref i else p_entity_ref i

  let p_attr_value i =                                   (* {S}? {AttValue} *)
    skip_white i;
    let delim = 
      if i.c = u_quot || i.c = u_apos then i.c else 
      err_expected_chars i [ u_quot; u_apos]
    in
    nextc i;
    skip_white i;
    clear_data i;
    i.last_white <- true;
    while (i.c <> delim) do
      if i.c = u_lt then err_illegal_char i u_lt else
      if i.c = u_amp then String.iter (addc_data_strip i) (p_reference i)
      else (addc_data_strip i i.c; nextc i)
    done;
    nextc i;
    Buffer.contents i.data

  let p_attributes i =                            (* ({S} {Attribute})* {S}? *) 
    let rec aux i pre_acc acc = 
      if not (is_white i.c) then pre_acc, acc else
      begin
	skip_white i;
	if i.c = u_slash or i.c = u_gt then pre_acc, acc else 
	begin 
	  let (prefix, local) as n = p_qname i in
	  let v = skip_white i; accept i u_eq; p_attr_value i in
	  let att = n, v in
	  if str_empty prefix && str_eq local n_xmlns then
	    begin  (* xmlns *)                                                
	      Ht.add i.ns String.empty v;
	      aux i (String.empty :: pre_acc) (att :: acc)
	    end
	  else if str_eq prefix n_xmlns then 
	    begin  (* xmlns:local *)                                        
	      Ht.add i.ns local v;
	      aux i (local :: pre_acc) (att :: acc)
	    end
	  else if str_eq prefix n_xml && str_eq local n_space then
	    begin  (* xml:space *)
	      if str_eq v v_preserve then i.stripping <- false else
	      if str_eq v v_default then i.stripping <- i.strip else ();
	      aux i pre_acc (att :: acc)
	    end
	  else
	    aux i pre_acc (att :: acc)
	end
      end
    in
    aux i [] []           (* Returns a list of bound prefixes and attributes *)

  let p_limit i =                                   (* Parses a markup limit *)
    i.limit <-
      if i.c = u_dollar then Dollar else
      if i.c = u_eoi then Eoi else
      if i.c <> u_lt then Text else 
      begin
	nextc i;
	if i.c = u_qmark then (nextc i; Pi (p_qname i)) else
	if i.c = u_slash then 
	  begin 
	    nextc i; 
	    let n = p_qname i in 
	    skip_white i;
	    Etag n
	  end
	else if i.c = u_emark then 
	  begin 
	    nextc i;
	    if i.c = u_minus then (nextc i; accept i u_minus; Comment) else
	    if i.c = u_D then Dtd else
	    if i.c = u_lbrack then 
	      begin 
		nextc i;
		clear_ident i;
		for k = 1 to 6 do (addc_ident i i.c; nextc i) done;
		let cdata = Buffer.contents i.ident in 
		if str_eq cdata s_cdata then Cdata else
		err_expected_seqs i [ s_cdata ] cdata
	      end
	    else
	      err i (`Illegal_char_seq (cat (str "<!") (str_of_char i.c)))
	  end
	else
	  Stag (p_qname i)
      end
	    
  let rec skip_comment i =                    (* {Comment}, '<!--' was eaten *)
    while (i.c <> u_minus) do nextc i done;
    nextc i;
    if i.c <> u_minus then skip_comment i else 
    begin 
      nextc i;
      if i.c <> u_gt then err_expected_chars i [ u_gt ];
      nextc_eof i
    end

  let rec skip_pi i =                          (* {PI}, '<?' qname was eaten *)
    while (i.c <> u_qmark) do nextc i done;
    nextc i;
    if i.c <> u_gt then skip_pi i else nextc_eof i

  let rec skip_misc i ~allow_xmlpi = match i.limit with          (* {Misc}* *)
  | Pi (p,l) when (str_empty p && str_eq n_xml (String.lowercase l)) -> 
      if allow_xmlpi then () else err i (`Illegal_char_seq l)
  | Pi _ -> skip_pi i; p_limit i; skip_misc i ~allow_xmlpi
  | Comment -> skip_comment i; p_limit i; skip_misc i ~allow_xmlpi
  | Text when is_white i.c -> 
      skip_white_eof i; p_limit i; skip_misc i ~allow_xmlpi
  | _ -> ()
      
  let p_dollar addc i =
    clear_data i;
    addc i i.c;
    nextc i;
    while (i.c <> u_dollar) do
      addc i i.c;
      nextc i;
    done;
    addc i i.c;
    nextc i;
    p_limit i;
    Buffer.contents i.data

  let p_chardata addc i =           (* {CharData}* ({Reference}{Chardata})* *)
    while (i.c <> u_lt) && (not i.templates || i.c <> u_dollar) do 
      if i.c = u_amp then String.iter (addc i) (p_reference i)
      else if i.c = u_rbrack then 
	begin 
	  addc i i.c;
	  nextc i;
	  if i.c = u_rbrack then begin 
	    addc i i.c;
	    nextc i;                                   (* detects ']'*']]>' *)
	    while (i.c = u_rbrack) do addc i i.c; nextc i done;
	    if i.c = u_gt then err i (`Illegal_char_seq (str "]]>"));
	  end
	end
      else
	(addc i i.c; nextc i)
    done


  let rec p_cdata addc i =                               (* {CData} {CDEnd} *)
    try while (true) do 
      if i.c = u_rbrack then begin
	nextc i;
	while i.c = u_rbrack do
	  nextc i;
	  if i.c = u_gt then (nextc i; raise Exit);
	  addc i u_rbrack
	done;
	addc i u_rbrack;
      end;
      addc i i.c;
      nextc i;
    done with Exit -> ()
	  
  let p_xml_decl i ~ignore_enc ~ignore_utf16 =                (* {XMLDecl}? *)
    let yes_no = [v_yes; v_no] in
    let p_val i = skip_white i; accept i u_eq; skip_white i; p_attr_value i in
    let p_val_exp i exp = 
      let v = p_val i in 
      if not (List.exists (str_eq v) exp) then err_expected_seqs i exp v
    in
    match i.limit with
    | Pi (p, l) when (str_empty p && str_eq l n_xml) ->  
	let v = skip_white i; p_ncname i in
	if not (str_eq v n_version) then err_expected_seqs i [ n_version ] v;
	p_val_exp i [v_version_1_0; v_version_1_1];
	skip_white i;
	if i.c <> u_qmark then begin
	  let n = p_ncname i in
	  if str_eq n n_encoding then begin
	    let enc = String.lowercase (p_val i) in
	    if not ignore_enc then begin 
	      if str_eq enc v_utf_8 then i.uchar <- uchar_utf8 else
	      if str_eq enc v_utf_16be then i.uchar <- uchar_utf16be else
	      if str_eq enc v_utf_16le then i.uchar <- uchar_utf16le else
	      if str_eq enc v_iso_8859_1 then i.uchar <- uchar_iso_8859_1 else
	      if str_eq enc v_us_ascii then i.uchar <- uchar_ascii else
	      if str_eq enc v_ascii then i.uchar <- uchar_ascii else
	      if str_eq enc v_utf_16 then 
		if ignore_utf16 then () else (err i `Malformed_char_stream)
                                             (* A BOM should have been found. *)
	      else
		err i (`Unknown_encoding enc)
	    end;
	    skip_white i;
	    if i.c <> u_qmark then begin 
	      let n = p_ncname i in 
	      if str_eq n n_standalone then p_val_exp i yes_no else
	      err_expected_seqs i [ n_standalone; str "?>" ] n 
	    end
	  end 
	  else if str_eq n n_standalone then
	    p_val_exp i yes_no
	  else
	    err_expected_seqs i [ n_encoding; n_standalone; str "?>" ] n
	end;
	skip_white i;
	accept i u_qmark;
	accept i u_gt;
	p_limit i
    | _ -> ()

  let p_dtd_signal i =(* {Misc}* {doctypedecl} {Misc}* *)
    skip_misc i ~allow_xmlpi:false;
    if i.limit <> Dtd then `Dtd None else
    begin
      let buf = addc_data i in
      let nest = ref 1 in                               
      clear_data i; 
      buf u_lt; buf u_emark;                             (* add eaten "<!" *)
      while (!nest > 0) do
	if i.c = u_lt then 
	  begin 
	    nextc i;
	    if i.c <> u_emark then 
	      (buf u_lt; incr nest) 
	    else
	      begin 
		nextc i;
		if i.c <> u_minus then         (* Carefull with comments ! *) 
		  (buf u_lt; buf u_emark; incr nest) 
		else
		  begin 
		    nextc i;
		    if i.c <> u_minus then 
		      (buf u_lt; buf u_emark; buf u_minus; incr nest) 
		    else                        
		      (nextc i; skip_comment i)
		  end
	      end
	  end
	else if i.c = u_quot or i.c = u_apos then
	  begin 
	    let c = i.c in
	    buf c; nextc i;
	    while (i.c <> c) do (buf i.c; nextc i) done;
	    buf c; nextc i
	  end
	else if i.c = u_gt then (buf u_gt; nextc i; decr nest)
	else (buf i.c; nextc i)
      done;
      let dtd = Buffer.contents i.data in 
      p_limit i;
      skip_misc i ~allow_xmlpi:false;
      `Dtd (Some dtd);
    end
      	  
  let p_data i = 
    let rec bufferize addc i = match i.limit with 
    | Dollar when i.templates -> ()
    | Text | Dollar -> p_chardata addc i; p_limit i; bufferize addc i
    | Cdata -> p_cdata addc i; p_limit i; bufferize addc i
    | Stag _ | Etag _ -> ()
    | Pi _ -> skip_pi i; p_limit i; bufferize addc i
    | Comment -> skip_comment i; p_limit i; bufferize addc i
    | Dtd -> err i (`Illegal_char_seq (str "<!D"))
    | Eoi -> err i `Unexpected_eoi
    in
    clear_data i;
    i.last_white <- true;
    bufferize (if i.stripping then addc_data_strip else addc_data) i;
    let d = Buffer.contents i.data in 
    d
    
  let p_el_start_signal i n = 
    let expand_att (((prefix, local) as n, v) as att) = 
      if not (str_eq prefix String.empty) then expand_name i n, v else
      if str_eq local n_xmlns then (ns_xmlns, n_xmlns), v else
      att (* default namespaces do not influence attributes. *)
    in
    let strip = i.stripping in  (* save it here, p_attributes may change it. *) 
    let prefixes, atts = p_attributes i in
    i.scopes <- (n, prefixes, strip) :: i.scopes;
    `El_start ((expand_name i n), List.rev_map expand_att atts)

  let p_el_end_signal i n = match i.scopes with
  | (n', prefixes, strip) :: scopes ->
      if i.c <> u_gt then err_expected_chars i [ u_gt ];
      if not (str_eq n n') then err_expected_seqs i [name_str n'] (name_str n); 
      i.scopes <- scopes;
      i.stripping <- strip;
      List.iter (Ht.remove i.ns) prefixes;
      if scopes = [] then i.c <- u_end_doc else (nextc i; p_limit i);
      `El_end
  | _ -> assert false
          
  let p_signal i = 
    if i.scopes = [] then 
      match i.limit with 
      | Stag n -> p_el_start_signal i n
      | _ -> err i `Expected_root_element
    else 
      let rec find i = match i.limit with 
      | Stag n -> p_el_start_signal i n
      | Etag n -> p_el_end_signal i n
      | Dollar when i.templates -> `Data (p_dollar addc_data i)
      | Text | Cdata | Dollar ->
	  let d = p_data i in
	  if str_empty d then find i else `Data d
      | Pi _ -> skip_pi i; p_limit i; find i
      | Comment -> skip_comment i; p_limit i; find i
      | Dtd -> err i (`Illegal_char_seq (str "<!D"))
      | Eoi -> err i `Unexpected_eoi
      in
      begin match i.peek with          
      | `El_start (n, _) ->                   (* finish to input start el. *)
	  skip_white i;
	  if i.c = u_gt then (accept i u_gt; p_limit i) else
	  if i.c = u_slash then 
	    begin 
	      let tag = match i.scopes with
	      | (tag, _, _) :: _ -> tag | _ -> assert false
	      in
	      (nextc i; i.limit <- Etag tag) 
	    end
	  else
	    err_expected_chars i [ u_slash; u_gt ]
      | _ -> ()
      end;
      find i

  let eoi i = 
    try
      if i.c = u_eoi then true else
      if i.c <> u_start_doc then false else                 (* In a document. *)
      if i.peek <> `El_end then                (* Start of document sequence. *)
      begin 
	let ignore_enc = find_encoding i in
	p_limit i;
	p_xml_decl i ~ignore_enc ~ignore_utf16:false;
	i.peek <- p_dtd_signal i;
	false
      end
    else                                            (* Subsequent documents. *)
      begin 
	nextc_eof i;
	p_limit i;
	if i.c = u_eoi then true else
	begin 
	  skip_misc i ~allow_xmlpi:true;
	  if i.c = u_eoi then true else 
	  begin 
	    p_xml_decl i ~ignore_enc:false ~ignore_utf16:true;
	    i.peek <- p_dtd_signal i;
	    false
	  end
	end
      end
    with 
    | Buffer.Full -> err i `Max_buffer_size
    | Malformed -> err i `Malformed_char_stream
    | End_of_file -> err i `Unexpected_eoi

  let peek i = if eoi i then err i `Unexpected_eoi else i.peek

  let input i =
    try
      if i.c = u_end_doc then (i.c <- u_start_doc; i.peek) else
      let s = peek i in 
      i.peek <- p_signal i;
      s
    with 
    | Buffer.Full -> err i `Max_buffer_size
    | Malformed -> err i `Malformed_char_stream
    | End_of_file -> err i `Unexpected_eoi

  let input_tree ~el ~data i = match input i with
  | `Data d -> data d 
  | `El_start tag -> 
      let rec aux i tags context = match input i with
      | `El_start tag -> aux i (tag :: tags) ([] :: context)
      | `El_end -> 
	  begin match tags, context with
	  | tag :: tags', childs :: context' ->
	      let el = el tag (List.rev childs) in 
	      begin match context' with
	      | parent :: context'' -> aux i tags' ((el :: parent) :: context'')
	      | [] -> el
	      end
	  | _ -> assert false
	  end
      | `Data d ->
	  begin match context with
	  | childs :: context' -> aux i tags (((data d) :: childs) :: context')
	  | [] -> assert false
	  end
      | `Raw _ -> assert false
      | `Dtd _ -> assert false
      in 
      aux i (tag :: []) ([] :: [])
  | _ -> invalid_arg err_input_tree


  let input_doc_tree ~el ~data i = match input i with
  | `Dtd d -> d, input_tree ~el ~data i
  | _ -> invalid_arg err_input_doc_tree
    	
  let pos i = i.line, i.col

  (* Output *)

  type 'a frag = [ `El of tag * 'a list | `Data of string ]
  type t = (('a frag as 'a) frag) list
  type dest = [ 
    `Buffer of std_buffer | `Fun of (int -> unit) ]

  type output = 
      { nl : bool;                (* True if a newline is output at the end. *)
	indent : int option;                        (* Optional indentation. *)
	fun_prefix : string -> string option;            (* Prefix callback. *)
        prefixes : string Ht.t;                   (* uri -> prefix bindings. *)
	outs : std_string -> int -> int -> unit;           (* String output. *)
	outc : char -> unit;                            (* character output. *)
	mutable last_el_start : bool;   (* True if last signal was `El_start *)
	mutable scopes : (name * (string list)) list;
                                       (* Qualified el. name and bound uris. *)
	mutable depth : int; }                               (* Scope depth. *) 

  let err_prefix uri = "unbound namespace (" ^ uri ^ ")"
  let err_dtd = "dtd signal not allowed here"
  let err_el_start = "start signal not allowed here"
  let err_el_end = "end signal without matching start signal"
  let err_data = "data signal not allowed here"

  let make_output ?(nl = false) ?(indent = None) ?(ns_prefix = fun _ ->None) d =
    let outs, outc = match d with 
    | `Buffer b -> (Std_buffer.add_substring b), (Std_buffer.add_char b)
    | `Fun f -> 
	let os s p l = 
	  for i = p to p + l - 1 do f (Char.code (Std_string.get s p)) done 
	in
	let oc c = f (Char.code c) in 
	os, oc
    in
    let prefixes = 
      let h = Ht.create 10 in 
      Ht.add h String.empty String.empty;
      Ht.add h ns_xml n_xml;
      Ht.add h ns_xmlns n_xmlns;
      h
    in
    { outs = outs; outc = outc; nl = nl; indent = indent; last_el_start = false;
      prefixes = prefixes; scopes = []; depth = -1; fun_prefix = ns_prefix; }
 
  let outs o s = o.outs s 0 (Std_string.length s)
  let str_utf_8 s = String.to_utf_8 (fun _ s -> s) "" s
  let out_utf_8 o s = ignore (String.to_utf_8 (fun o s -> outs o s; o) o s)

  let prefix_name o (ns, local) = 
    try 
      if str_eq ns ns_xmlns && str_eq local n_xmlns then (String.empty, n_xmlns)
      else (Ht.find o.prefixes ns, local)
    with Not_found -> 
      match o.fun_prefix ns with
      | None -> invalid_arg (err_prefix (str_utf_8 ns))
      | Some prefix -> prefix, local

  let bind_prefixes o atts = 
    let add acc ((ns, local), uri) = 
      if not (str_eq ns ns_xmlns) then acc else
      begin 
	let prefix = if str_eq local n_xmlns then String.empty else local in
	Ht.add o.prefixes uri prefix; 
	uri :: acc
      end
    in
    List.fold_left add [] atts

  let out_data o s =
    let out () s = 
      let len = Std_string.length s in
      let start = ref 0 in
      let last = ref 0 in
      let escape e = 
	o.outs s !start (!last - !start);
	outs o e;
	incr last;
	start := !last
      in
      while (!last < len) do match Std_string.get s !last with 
      | '<' -> escape "&lt;"         (* Escape markup delimiters. *)
      | '>' -> escape "&gt;"
      | '&' -> escape "&amp;"
   (* | '\'' -> escape "&apos;" *) (* Not needed we use \x22 for attributes. *)
      | '\x22' -> escape "&quot;"
      | _ -> incr last
      done;
      o.outs s !start (!last - !start)
    in
    String.to_utf_8 out () s

  (* XXX an avsm hack to be able to output XML strings from other sources *)
  let out_raw o s =
    out_utf_8 o s
 
  let out_qname o (p, l) = 
    if not (str_empty p) then (out_utf_8 o p; o.outc ':'); 
    out_utf_8 o l

  let out_attribute o (n, v) = 
    o.outc ' '; out_qname o (prefix_name o n); outs o "=\x22"; 
    out_data o v; 
    o.outc '\x22'
    
  let output o (s:signal) = 
    let indent o = match o.indent with
    | None -> ()
    | Some c -> for i = 1 to (o.depth * c) do o.outc ' ' done
    in
    let unindent o = match o.indent with None -> () | Some _ -> o.outc '\n' in
    if o.depth = -1 then 
      begin match s with
      | `Dtd d ->
	  begin match d with 
	  | Some dtd ->
	  outs o "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
	  out_utf_8 o dtd; o.outc '\n' 
	  | None -> ()
	  end;
	  o.depth <- 0
      | `Data _ | `Raw _-> invalid_arg err_data
      | `El_start _ -> invalid_arg err_el_start
      | `El_end -> invalid_arg err_el_end
      end
    else
      begin match s with
      | `El_start (n, atts) -> 
	  if o.last_el_start then (outs o ">"; unindent o);
	  indent o;
	  let uris = bind_prefixes o atts in
	  let qn = prefix_name o n in
	  o.outc '<'; out_qname o qn; List.iter (out_attribute o) atts;
	  o.scopes <- (qn, uris) :: o.scopes;
	  o.depth <- o.depth + 1;
	  o.last_el_start <- true
      | `El_end -> 
	  begin match o.scopes with
	  | (n, uris) :: scopes' ->
	      o.depth <- o.depth - 1;
	      if o.last_el_start then outs o "/>" else
	      begin 
		indent o;
		outs o "</"; out_qname o n; o.outc '>';
	      end;
	      o.scopes <- scopes';
	      List.iter (Ht.remove o.prefixes) uris;
	      o.last_el_start <- false;
	      if o.depth = 0 then (if o.nl then o.outc '\n'; o.depth <- -1;) 
	      else unindent o
	  | [] -> invalid_arg err_el_end
	  end
      | `Data d -> 
	  if o.last_el_start then (outs o ">"; unindent o);
	  indent o;
	  out_data o d;
	  unindent o;
	  o.last_el_start <- false
      | `Raw d ->
	  if o.last_el_start then (outs o ">"; unindent o);
          out_raw o d;
	  o.last_el_start <- false
      | `Dtd _ -> failwith err_dtd
      end

  let output_tree frag o v =
    let rec aux o = function
      | (v :: rest) :: context ->
	  begin match frag v with
	  | `El (tag, childs) ->
	      output o (`El_start tag);
	      aux o (childs :: rest :: context)
	  | (`Data d) as signal -> 
	      output o signal;
	      aux o (rest :: context)
	  end
      | [] :: [] -> ()
      | [] :: context -> output o `El_end; aux o context
      | [] -> assert false
    in
    aux o ([v] :: [])

  let output_doc_tree frag o (dtd, v) = 
    output o (`Dtd dtd); 
    output_tree frag o v

end

(* Default streaming XML IO *)

module XMLString = struct
  type t = string
  let empty = ""
  let length = String.length
  let append = ( ^ )
  let lowercase = String.lowercase
  let iter f s = 
    let len = Std_string.length s in
    let pos = ref ~-1 in
    let i () = 
      incr pos; 
      if !pos = len then raise Exit else 
      Char.code (Std_string.get s !pos)
    in
    try while true do f (uchar_utf8 i) done with Exit -> ()

  let of_string s = s    
  let to_utf_8 f v x = f v x
  let compare = String.compare
end
    
module XMLBuffer = struct
  type string = String.t
  type t = Buffer.t
  exception Full 
  let create = Buffer.create
  let add_uchar b u =  
    try
      (* UTF-8 encodes an uchar in the buffer, assumes u is valid code point. *)
      let buf c = Buffer.add_char b (Char.chr c) in
      if u <= 0x007F then 
	(buf u)
      else if u <= 0x07FF then 
	(buf (0xC0 lor (u lsr 6)); 
	 buf (0x80 lor (u land 0x3F)))
      else if u <= 0xFFFF then
	(buf (0xE0 lor (u lsr 12));
	 buf (0x80 lor ((u lsr 6) land 0x3F));
       buf (0x80 lor (u land 0x3F)))
      else
	(buf (0xF0 lor (u lsr 18));
	 buf (0x80 lor ((u lsr 12) land 0x3F));
	 buf (0x80 lor ((u lsr 6) land 0x3F));
	 buf (0x80 lor (u land 0x3F)))
    with Failure _ -> raise Full
	  
  let clear b = Buffer.clear b
  let contents = Buffer.contents
  let length = Buffer.length
end

include Make(XMLString) (XMLBuffer)

(* XXX: add a proper output_subtree function*)
let id x = x

let rec output_t o = function
  | (`Data _ as d) :: t ->
    output o d;
    output_t o t
  | (`El _ as e) :: t   ->
    output_tree id o e;
    output o (`Dtd None);
    output_t o t
  | [] -> ()

let to_string t =
  let buf = Buffer.create 1024 in
  let o = make_output (`Buffer buf) in
  output o (`Dtd (Some ""));
  output_t o t;
  Buffer.contents buf

(* XXX: do a proper input_subtree integration *)
(*** XHTML parsing (using Xml) ***)
let _input_tree (templates : (string * t) list) input : t =
  let el (name, attrs) body : t = [ `El ((name, attrs), List.flatten body) ] in
  let data str : t =
    if List.mem_assoc str templates then
      List.assoc str templates
    else
      [`Data str] in
  input_tree ~el ~data input

let of_string ?entity ?(templates : (string * t) list = []) ?enc str =
  let templates = List.map (fun (k,v) -> "$"^k^"$", v) templates in
  (* It is illegal to write <:html<<b>foo</b>>> so we use a small trick and write
     <:html<<b>foo</b>&>> *)
  let str = if str.[String.length str - 1] = '&' then
    String.sub str 0 (String.length str - 1)
  else
    str in
  (* input needs a root tag *)
  let str = Printf.sprintf "<xxx>%s</xxx>" str in
  try
    let i = make_input ~templates:true ~enc ?entity (`String (0,str)) in
    (* make_input builds a well-formed document, so discard the Dtd *)
    (match peek i with
      | `Dtd _ -> let _ = input i in ()
      | _      -> ());
    (* Remove the dummy root tag *)
    match _input_tree templates i with
      | [ `El ((("","xxx"), []), body) ]-> body
      | _ -> raise Parsing.Parse_error
  with Error (pos, e) ->
    Printf.eprintf "[XMLM:%d-%d] %s: %s\n"(fst pos) (snd pos) str (error_message e);
    raise Parsing.Parse_error
  
(*----------------------------------------------------------------------------
  Copyright (c) 2007-2009, Daniel C. Bünzli
  All rights reserved.

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are
  met:
        
  1. Redistributions of source code must retain the above copyright
     notice, this list of conditions and the following disclaimer.

  2. Redistributions in binary form must reproduce the above copyright
     notice, this list of conditions and the following disclaimer in the
     documentation and/or other materials provided with the
     distribution.

  3. Neither the name of the Daniel C. Bünzli nor the names of
     contributors may be used to endorse or promote products derived
     from this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
  A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
  OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
  ----------------------------------------------------------------------------*)
