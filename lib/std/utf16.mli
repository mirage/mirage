
(** UTF-16 support for Ulex.
   Implementation as described in "http://www.ietf.org/rfc/rfc2781.txt".
 *)

exception MalFormed

(** UTF-16 can be encoded in little endian format (0xabcd ->
   (0xcd|0xab)) or big endian format (0xabcd -> (0xab|0xcd).  *)

type byte_order = Little_endian | Big_endian

(** {6 Interface } *)

(** [to_int_array opt_bo str spos bytes] decodes the string [str] of
   length [bytes] starting in position [spos]. If [opt_bo] matches
   with [None] the functions tries to detect a BOM, if it can't it
   assumes big endian byte order. If [opt_bo] matches with [Some bo]
   byte order [bo] is assumed and potential byte order marks are
   interpreted as code points 0xfeff. *)
val to_int_array: byte_order option -> string -> int -> int -> int array

(** [from_int_array bo a apos len bom] encodes an int array [a]
   containing [len] code points from position [apos] into a string
   with byte order [bo]. The results starts with a BOM if [bom =
   true]. *)
val from_int_array: byte_order -> int array -> int -> int -> bool -> string

(** [stream_from_char_stream opt_stro] creates a new int stream
   containing the code points encoded in [str]. Treats [opt_bo] as
   [to_int_array]. *)
val stream_from_char_stream: byte_order option -> char Stream.t -> int Stream.t

(** {6 Low level} *)

(** [get_byte_order c1 c2] determines the byte order by a pair of
   bytes/characters [c1] and [c2].  *)
val get_byte_order: char -> char -> byte_order


(** [from_stream bo s] reads the next code point from a stream encoded
   in byte order [bo]. *)
val from_stream: byte_order -> char Stream.t -> int

(** [number_of_char_pair bo c1 c2] returns the code point encoded in
   [c1] and [c2] following byte order [bo]. *)
val number_of_char_pair: byte_order -> char -> char -> int

(** [char_pair_of_number bo cp] encodes code point [cp] into two
   characters with byte order [bo].  *)
val char_pair_of_number: byte_order -> int -> char * char

(** [next_code bo s pos bytes bo] reads the code point starting at
   position [pos] in a string [s] of total length [bytes].  *)
val next_code: byte_order -> string -> int -> int -> int * int

(** [compute_len opt_bo str pos len] computes the
   number of encoded code points in string [str] from position
   [pos] to [pos+len-1]. *)
val compute_len: byte_order option -> string -> int -> int -> int

(** [blit_to_int bo str spos a apos n] decode [len] bytes
   from string [str] starting at position [spos] into
   array [a], at position [apos]. *)
val blit_to_int:
 byte_order option -> string -> int -> int array -> int -> int -> unit


(** [store bo buf cp] adds a codepoint [cp] to a buffer [buf]
   following the byte order [bo]. *)
val store: byte_order -> Buffer.t -> int -> unit




val from_utf16_stream: char Stream.t -> byte_order option -> Ulexing.lexbuf
  (** [from_utf16_stream s opt_bo] creates a lexbuf from an UTF-16
      encoded stream. If [opt_bo] matches with [None] the function
      expects a BOM (Byte Order Mark), and takes the byte order as
      [Utf16.Big_endian] if it cannot find one. When [opt_bo] matches 
      with [Some bo], [bo] is taken as byte order. In this case a
      leading BOM is kept in the stream - the lexer has to ignore it
      and a `wrong' BOM ([0xfffe]) will raise Utf16.InvalidCodepoint.
    *)

val from_utf16_channel: in_channel -> byte_order option-> Ulexing.lexbuf
  (** Works as [from_utf16_stream] with an [in_channel]. *)
                                                                  
val from_utf16_string: string -> byte_order option -> Ulexing.lexbuf 
  (** Works as [from_utf16_stream] with a [string]. *)
                                                              
val utf16_lexeme: Ulexing.lexbuf -> byte_order -> bool -> string
  (** [utf16_lexeme lb bo bom] as [Ulexing.lexeme] with a result encoded in
      UTF-16 in byte_order [bo] and starting with a BOM if [bom = true].
  *)
                                                  
val utf16_sub_lexeme: Ulexing.lexbuf -> int -> int -> byte_order -> bool -> string
  (** [utf16_sub_lexeme lb pos len bo bom] as [Ulexing.sub_lexeme] with a 
      result encoded in UTF-16 with byte order [bo] and starting with a BOM
      if [bom=true]  *)
