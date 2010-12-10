(*----------------------------------------------------------------------------
   Copyright (c) 2007-2009, Daniel C. Bünzli. All rights reserved.
   Distributed under a BSD license, see license at the end of the file.
   Xmlm version 1.0.2
  ----------------------------------------------------------------------------*)

(** Streaming XML IO.  

    A well-formed sequence of {{:#TYPEsignal}signals} represents an
    {{:http://www.w3.org/TR/REC-xml}XML} document tree traversal in
    depth first order (this has nothing to do with XML
    well-formedness). Input pulls a well-formed sequence of signals
    from a data source and output pushes a well-formed sequence of
    signals to a data destination. Functions are provided to easily 
    transform sequences of signals to/from arborescent data structures.

    Consult the {{:#io}features and limitations} and {{:#ex}examples} 
    of use.

    {e Version 1.0.2 - daniel.buenzl i\@erratique.ch }

    {b References.}

    Tim Bray. 
    {e {{:http://www.xml.com/axml/axml.html}The annotated XML Specification}}, 
    1998. 

    Tim Bray et al. 
    {e {{:http://www.w3.org/TR/xml-names11}Namespaces in XML 1.1 (2nd ed.)}},
    2006.

    {1 Basic types and values} *)

(** The type for character encodings. For [`UTF_16], endianness is
    determined from the 
    {{:http://www.unicode.org/unicode/faq/utf_bom.html#BOM}BOM}. *)
type encoding = [ 
  | `UTF_8 
  | `UTF_16   
  (** Endianness determined from the 
      {{:http://www.unicode.org/unicode/faq/utf_bom.html#BOM}BOM}. *)
  | `UTF_16BE 
  | `UTF_16LE 
  | `ISO_8859_1
  | `US_ASCII ]
      
type dtd = string option
(** The type for the optional
    {{:http://www.w3.org/TR/REC-xml/#dt-doctype}DTD}. *)

type name = string * string 
(** The type for attribute and element's
    {{:http://www.w3.org/TR/xml-names11/#dt-expname}expanded names} 
    [(uri,local)]. An empty [uri] represents a name without a
    namespace name, i.e. an unprefixed name 
    that is not under the scope of a default namespace. *)

type attribute = name * string
(** The type for attributes. Name and attribute data. *)

type tag = name * attribute list
(** The type for an element tag. Tag name and attribute list. *)

type signal = [ `Dtd of dtd | `El_start of tag | `El_end | `Data of string |`Raw of string]
(** The type for signals. A {e well-formed} sequence of signals belongs
    to the language of the [doc] grammar :
    {[doc ::= `Dtd tree
tree ::= `El_start child `El_end
child ::= `Data | tree | epsilon ]}
    Input and output deal only with well-formed sequences or
    exceptions are raised.
*)
    
val ns_xml : string 
(** Namespace name {{:http://www.w3.org/XML/1998/namespace}value} bound to the 
    reserved ["xml"] prefix. *)

val ns_xmlns : string
(** Namespace name {{:http://www.w3.org/2000/xmlns/}value} bound to the 
    reserved ["xmlns"] prefix. *)

(** {1 Input} *)

type pos = int * int 
(** The type for input positions. Line and column number, both start
    with 1. *)

(** The type for input errors. *)
type error = [
  | `Max_buffer_size 
  (** Maximal buffer size exceeded ([Sys.max_string_length]). *)
  | `Unexpected_eoi 
  (** Unexpected end of input. *)
  | `Malformed_char_stream 
  (** Malformed underlying character stream. *)
  | `Unknown_encoding of string 
  (** Unknown encoding. *)
  | `Unknown_entity_ref of string 
  (** Unknown entity reference, {{:#inentity} details}. *)
  | `Unknown_ns_prefix of string 
  (** Unknown namespace prefix {{:#inns} details} *)
  | `Illegal_char_ref of string 
  (** Illegal character reference. *)
  | `Illegal_char_seq of string 
  (** Illegal character sequence. *)
  | `Expected_char_seqs of string list * string
  (** Expected one of the character sequences in the list but found another. *)
  | `Expected_root_element 
  (** Expected the document's root element. *) ]

val error_message : error -> string
(** Converts the error to an english error message. *)

exception Error of pos * error
(** Raised on input errors. *)

type source = [ 
  `String of int * string | `Fun of (unit -> int) ]
(** The type for input sources. For [`String] starts reading at the
    given integer position. For [`Fun] the function must return the
    next {e byte} as an [int] and raise [End_of_file] if there is no
    such byte. *)

type input
(** The type for input abstractions. *)

val make_input :
  ?templates:bool ->
  ?enc:encoding option -> ?strip:bool -> 
  ?ns:(string -> string option) -> 
	?entity: (string -> string option) -> source -> input
(** Returns a new input abstraction reading from the given source.
    {ul 
    {- [enc], character encoding of the document, {{:#inenc} details}. 
       Defaults to [None].}
    {- [strip], strips whitespace in character data, {{:#inwspace} details}.
       Defaults to [false].} 
    {- [ns] is called to bind undeclared namespace prefixes,
       {{:#inns} details}. Default returns always [None].}
    {- [entity] is called to resolve non predefined entity references,
       {{:#inentity} details}. Default returns always [None].}} *)

val input : input -> signal
(** Inputs a signal. Repeated invocation of the function with the same
    input abstraction will generate a {{:#TYPEsignal}well-formed} sequence
    of signals or an {!Error} is raised. Furthermore there will be no
    two consecutive [`Data] signals in the sequence and their string
    is always non empty. After a well-formed sequence was input another may 
    be input, see {!eoi} and {{:#iseq}details}.

    {b Raises} {!Error} on input errors. *)

val input_tree : el:(tag -> 'a list -> 'a) -> data:(string -> 'a)  -> 
                 input -> 'a
(** If the next signal is a :
    {ul
    {- [`Data] signal, inputs it and invokes [data] with the character data.}
    {- [`El_start] signal, inputs the sequence of signals until its 
       matching [`El_end] and invokes [el] and [data] as follows
    {ul
    {- [el], is called on each [`El_end] signals with the corresponding 
      [`El_start] tag and the result of the callback invocation for the 
      element's children.}
    {- [data], is called on each [`Data] signals with the character data. 
      This function won't be called twice consecutively or with the empty 
      string.}}}
    {- Other signals, raises [Invalid_argument].}}

    {b Raises} {!Error} on input errors and [Invalid_argument]
      if the next signal is not [`El_start] or [`Data]. *)

val input_doc_tree : el:(tag -> 'a list -> 'a) -> data:(string -> 'a) -> 
                     input -> (dtd * 'a)
(** Same as {!input_tree} but reads a complete {{:#TYPEsignal}well-formed}  
    sequence of signals. 

    {b Raises} {!Error} on input errors and [Invalid_argument]
     if the next signal is not [`Dtd]. *)
    
val peek : input -> signal
(** Same as {!input} but doesn't remove the signal from the sequence. 

    {b Raises} {!Error} on input errors. *)

val eoi : input -> bool
(** Returns [true] if the end of input is reached. See {{:#iseq}details}.
 
    {b Raises} {!Error} on input errors. *)

val pos : input -> pos 
(** Current position in the input abstraction. *)

(** {1 Output} *)

type 'a frag = [ `El of tag * 'a list | `Data of string ]
(** The type for deconstructing data structures of type ['a]. *)

type t = (('a frag as 'a) frag) list
(** The type for XML fragments *)

type dest = [ `Buffer of Buffer.t | 
              `Fun of (int -> unit) ]
(** The type for output destinations. For [`Buffer], the buffer won't
    be cleared. For [`Fun] the function is called with the output {e
    bytes} as [int]s. *)

type output
(** The type for output abstractions. *)

val make_output : ?nl:bool -> ?indent:int option -> 
                  ?ns_prefix:(string -> string option) -> dest -> output
(** Returns a new output abstraction writing to the given destination.
    {ul 
    {- [nl], if [true] a newline is output when the root's element [`El_end] 
     signal is output.
    Defaults to [false].}
    {- [indent], identation behaviour, see {{:#outindent} details}. Defaults to
      [None].}
    {- [ns_prefix], undeclared namespace prefix bindings, 
       see {{:#outns}details}. Default returns always [None].}} *)


val output : output -> signal -> unit
(** Outputs a signal. After a well-formed sequence of signals was 
    output a new well-formed sequence can be output.

    {b Raises} [Invalid_argument] if the resulting signal sequence on
    the output abstraction is not {{:#TYPEsignal}well-formed} or if a
    namespace name could not be bound to a prefix. *)

val output_tree : ('a -> 'a frag) -> output -> 'a -> unit
(** Outputs signals corresponding to a value by recursively
    applying the given value deconstructor.

    {b Raises} see {!output}. *)

val output_doc_tree : ('a -> 'a frag) -> output -> (dtd * 'a) -> unit   
(** Same as {!output_tree} but outputs a complete {{:#TYPEsignal}well-formed} 
    sequence of signals.

    {b Raises} see {!output}. *)

(** {1:sto Functorial interface} 

    {!Make} allows client to specify types for strings and internal
    buffers. Among other things this can be used to perform
    hash-consing or to process the character stream, e.g. to normalize
    unicode characters or to convert to a custom encoding. *)

type std_string = string
type std_buffer = Buffer.t

(** Input signature for strings. *)
module type XMLString = sig
  
  type t
  (** The type for strings. *)

  val empty : t
  (** The empty string. *)
	
  val length : t -> int
  (** Returns the length of the string. *)
	
  val append : t -> t -> t
  (** Concatenates two strings. *)

  val lowercase : t -> t
  (** New string with uppercase letter translated
      to lowercase (correctness is only needed for ASCII
      {{:http://www.unicode.org/glossary/#code_point}code point}). *)

  val iter : (int -> unit) -> t -> unit
  (** Iterates over the unicode 
      {{:http://www.unicode.org/glossary/#code_point}code point}
      of the given string. *)

  val of_string : std_string -> t
  (** String from an OCaml string. *)

  val to_utf_8 : ('a -> std_string -> 'a) -> 'a -> t -> 'a
  (** [to_utf_8 f v s], is [f (... (f (f v s1) s2) ...) sn]. Where the
      concatenation of [s1], [s2], ... [sn] is [s] as an UTF-8 stream. *)

  val compare : t -> t -> int
  (** String comparison. Binary comparison is sufficent. *)
end

(** Input signature for internal buffers. *)
module type XMLBuffer = sig

  type string
  (** The type for strings. *)
	
  type t 
  (** The type for buffers. *)

  exception Full
  (** Raised if the buffer cannot be grown. *)
	  
  val create : int -> t
  (** Creates a buffer of the given size. *)

  val add_uchar : t -> int -> unit
  (** Adds the given (guaranteed valid) unicode
      {{:http://www.unicode.org/glossary/#code_point}code point} to a
      buffer. 

      {b Raises} {!Full} if the buffer cannot be grown. *)

  val clear : t -> unit
  (** Clears the buffer. *)

  val contents : t -> string
  (** Returns the buffer contents. *)
  
  val length : t -> int
  (** Returns the number of characters contained in the buffer. *)
end

(** Output signature of {!Make}. *)
module type S = sig 
  
  (** {1 Basic types and values} *)  

  type string 

  type encoding = [ 
    | `UTF_8 | `UTF_16 | `UTF_16BE | `UTF_16LE | `ISO_8859_1| `US_ASCII ]
  type dtd = string option
  type name = string * string 
  type attribute = name * string
  type tag = name * attribute list
  type signal = [ `Dtd of dtd | `El_start of tag | `El_end | `Data of string |`Raw of string]
	
  val ns_xml : string 
  val ns_xmlns : string
      
  (** {1 Input} *)  

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
    ?enc:encoding option -> ?strip:bool -> 
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

  (** {1 Output} *)

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

(** Functor building streaming XML IO with the given strings and buffers. *)
module Make (String : XMLString) (Buffer : XMLBuffer with type string = String.t) : S
with type string = String.t

(** {1:io Features and limitations}
    
    The module assumes strings are immutable, thus strings
    the client gives or receives {e during} the input and output process 
    must not be modified.
    {2:input Input}
    {3:inenc Encoding}    

    The parser supports ASCII, US-ASCII, 
    {{:http://www.faqs.org/rfcs/rfc3629.html} UTF-8},
    {{:http://www.faqs.org/rfcs/rfc2781.html} UTF-16},
    {{:http://www.faqs.org/rfcs/rfc2781.html} UTF-16LE},
    {{:http://www.faqs.org/rfcs/rfc2781.html} UTF-16BE} and
    {{:http://anubis.dkuug.dk/JTC1/SC2/WG3/docs/n411.pdf}ISO-8559-1} 
    (Latin-1) encoded documents. But strings returned by
    the library are {b always} UTF-8 encoded (unless you use the functor). 
    
    The encoding can be specified explicitly using the optional
    argument [enc]. Otherwise the parser uses UTF-16 or UTF-8 if there is a
    {{:http://www.unicode.org/unicode/faq/utf_bom.html#BOM}BOM} at the
    beginning of the document. If there is no BOM it uses the encoding
    specified in the {{:http://www.w3.org/TR/REC-xml/#NT-XMLDecl} XML
    declaration}. Finally, if there is no XML declaration UTF-8 is assumed.
    {3:inwspace White space handling}

    The parser performs
    {{:http://www.w3.org/TR/REC-xml/#AVNormalize}attribute data
    normalization} on {e every} attribute data.  This means that
    attribute data does not have leading and trailling white space and that 
    any white space is collapsed and transformed to a single space 
    character ([U+0020]).

    White space handling of character data depends on the [strip]
    argument. If [strip] is [true], character data is treated like
    attribute data, white space before and after elements is removed
    and any white space is collapsed and transformed to a single
    space character ([U+0020]), except if the data is under the scope of a {e
    xml:space} attribute whose value is {e preserve}.  If [strip] is
    [false] all white space data is preserved as present in the
    document (however all kinds of
    {{:http://www.w3.org/TR/REC-xml/#sec-line-ends}line ends} are
    translated to the newline character ([U+000A]).  {3:inns Namespaces}

    Xmlm's {{:#TYPEname}names} are
    {{:http://www.w3.org/TR/xml-names11/#dt-expname}expanded names}.
    The parser automatically handles the document's namespace
    declarations.  Undeclared namespace prefixes can be bound via the
    callback [ns], which must return a namespace name. If [ns] returns
    [None] an [`Unknown_ns_prefix] error is raised.

    Attributes used for namespace declarations are preserved by the
    parser. They are in the {!ns_xmlns} namespace. Default namespace
    declarations made with {i xmlns} have the attribute name
    [(Xmlm.ns_xmlns, "xmlns")]. Prefix declarations have the prefix as
    the local name, for example {i xmlns:ex} results in the attribute name
    [(Xmlm.ns_xmlns, "ex")].

    Regarding constraints on the usage of the {i xml} and {i xmlns}
    prefixes by documents, the parser does not report errors on violations 
    of the {i must} constraints listed in
    {{:http://www.w3.org/TR/xml-names11/#xmlReserved}this paragraph}. 
    {3:inentity Character and entity references}

    {{:http://www.w3.org/TR/REC-xml/#dt-charref}Character references}
    and {{:http://www.w3.org/TR/REC-xml/#sec-predefined-ent}predefined
    entities} are automatically resolved. Other entity references can
    be resolved by the callback [entity], which must return an UTF-8
    (unless you use the functor) string corresponding to the
    replacement character data.  The replacement data is {e not}
    analysed for further references, it is added to the data as such
    modulo white space stripping. If [entity] returns [None] the error
    [`Unknown_entity_ref] is returned.    
    {3:iseq Sequences of documents}

    When a well-formed sequence of signals is input, no data is consumed beyond
    the closing ['>'] of the document's root element. 

    If you want to parse a document as
    {{:http://www.w3.org/TR/REC-xml/#NT-document}defined} in the XML
    specification, call {!eoi} after a well-formed sequence of
    signals, it must return [true]. If you expect another document on
    the same input abstraction a new well-formed sequence of signals
    can be {!input}. Use {!eoi} to check if a document follows (this
    may consume data).

    Invoking {!eoi} after a well-formed sequence of signals skips
    whitespaces, comments and processing instructions until it gets to
    either an {{:http://www.w3.org/TR/REC-xml/#NT-XMLDecl} XML
    declaration} or a {{:http://www.w3.org/TR/REC-xml/#dt-doctype}DTD}
    or the start of a new element or the end of input (in which case
    {!eoi} returns [true]).  If there is a new document but there is no
    XML declaration or the declaration specifies UTF-16, the same
    encoding as for the previous document is used.

    {3:inmisc Miscellaneous}
    {ul
    {- Parses the more liberal and simpler XML 1.1 
    {{:http://www.w3.org/TR/xml11/#NT-Name}Name} definition (minus [':'] because
    of namespaces).}
    {- The {{:http://www.w3.org/TR/REC-xml/#dt-doctype}DTD} is parsed
      roughly (no guarantee it is well formed) and its information is ignored.}
    {- The parser drops 
    {{:http://www.w3.org/TR/REC-xml/#dt-comment}comments}, 
    {{:http://www.w3.org/TR/REC-xml/#dt-pi}processing instructions}, and 
    {{:http://www.w3.org/TR/REC-xml/#sec-rmd}standalone declaration}.}
    {- Element attributes are not checked for uniqueness.}
    {- Attribute and character data chunks are limited by 
       [Sys.max_string_length] (unless you use the functor). 
       The error [`Max_buffer_size] is raised if the limit is hit.}
    {- Tail recursive.}
    {- Non validating.}
    }
    

    {2:output Output} 
    {3:outenc Encoding} 

    Outputs only {{:http://www.faqs.org/rfcs/rfc3629.html} UTF-8}
    encoded documents (even if you use the functor).  Strings given to
    output functions {b must be} UTF-8 encoded (unless you use the
    functor, but you need to provide a translation), no checks are
    performed.  {3:outns Namespaces}

    Xmlm's {{:#TYPEname}names} are
    {{:http://www.w3.org/TR/xml-names11/#dt-expname}expanded names}.
    Expanded names are automatically converted to
    {{:http://www.w3.org/TR/xml-names11/#dt-qualname}qualified
    names} by the output abstraction. There is no particular api to specify 
    prefixes and default namespaces, 
    the actual result depends solely on the output
    of attributes belonging to the {!ns_xmlns} namespace. For example to set 
    the default namespace of an element to {i http://example.org/myns}, 
    use the following attribute :
    {[(* xmlns='http://example.org/myns' *)
let default_ns = (Xmlm.ns_xmlns, "xmlns"), "http://example.org/myns"]}
    To bind the prefix ["ex"] to {i http://example.org/ex}, use the 
    following attribute :
    {[(* xmlns:ex='http://example.org/ex' *)
let ex_ns = (Xmlm.ns_xmlns, "ex"), "http://example.org/ex"]}
    Note that outputing input signals without
    touching namespace declaration attributes will preserve existing
    prefixes and bindings provided the same namespace name is not
    bound to different prefixes in a given context.

    The callback [ns_prefix] of an output abstraction can be used to
    give a prefix to a namespace name lacking a prefix binding in the
    current output scope. Given a namespace name the function must return 
    the prefix to use. Note that this
    will {b not} add any namespace declaration attribute to the
    output.  If the function returns [None], {!output} will raise
    [Invalid_argument].  The default function returns always [None].
    {3:outindent Indentation}

    Output can be indented by specifying the [indent] argument when an
       output abstraction is created. If [indent] is [None] (default)
       signal output does not introduce any extra white space.  If
       [ident] is [Some c], each {!signal} is output on its own line
       (for empty elements [`El_start] and [`El_end] are collapsed on a single
       line) and nested elements are indented with [c] space
       characters.
    {3:oseq Sequences of documents} 

    After a well-formed sequence of signals was output, the output
    abstraction can be reused to output a new well-formed sequence of
    signals.

    {3:outmisc Miscellaneous}
    {ul
    {- In attribute and character data you provide, markup 
       delimiters ['<'],['>'],['&'], and ['\"'] are 
        automatically escaped to 
        {{:http://www.w3.org/TR/REC-xml/#sec-predefined-ent}predefined
        entities}.}
    {- No checks are peformed on the prefix and local part of output
      names to verify they are
      {{:http://www.w3.org/TR/xml-names11/#NT-NCName}NCName}s.
      For example using the tag name [("","dip d")] will produce 
      a non well-formed document because of the space character.}
    {- Tail recursive.}}

    {2 Tips} 
    {ul 
    {- The best options to do an input/output round trip
       and preserve as much information as possible is to 
       input with [strip = false] and output with [indent = None].}
    {- Complete whitespace control on output is achieved 
       with [indent = None] and suitable [`Data] signals}}
*)

(** {1:ex Examples} 

    {2:exseq Sequential processing}    

    Sequential processing has the advantage that you don't need to get
    the whole document tree in memory to process it.

    The following function reads a {e single} document on an
    input channel and outputs it.
{[let id ic oc = 
  let i = Xmlm.make_input (`Channel ic) in 
  let o = Xmlm.make_output (`Channel oc) in 
  let rec pull i o depth = 
    Xmlm.output o (Xmlm.peek i);
    match Xmlm.input i with 
    | `El_start _ -> pull i o (depth + 1)
    | `El_end -> if depth = 1 then () else pull i o (depth - 1)
    | `Data _ -> pull i o depth 
    | `Dtd _ -> assert false
  in
  Xmlm.output o (Xmlm.input i); (* `Dtd *)
  pull i o 0;
  if not (Xmlm.eoi i) then invalid_arg "document not well-formed"]}
    The following function reads a {e sequence} of documents on an
    input channel and outputs it.
{[let id_seq ic oc = 
  let i = Xmlm.make_input (`Channel ic) in 
  let o = Xmlm.make_output ~nl:true (`Channel oc) in 
  while not (Xmlm.eoi i) do Xmlm.output o (Xmlm.input i) done]}
    The following function reads a {e sequence} of documents on the 
    input channel. In each document's tree it prunes non root elements
    whose name belongs to [prune_list].
{[let prune_docs prune_list ic oc = 
  let i = Xmlm.make_input (`Channel ic) in
  let o = Xmlm.make_output ~nl:true (`Channel oc) in
  let copy i o = Xmlm.output o (Xmlm.input i) in
  let prune (name, _) = List.mem name prune_list in
  let rec process i o d = 
    let rec skip i d = match Xmlm.input i with
    | `El_start _ -> skip i (d + 1)
    | `El_end -> if d = 1 then () else skip i (d - 1)
    | s -> skip i d
    in
    match Xmlm.peek i with 
    | `El_start tag when prune tag -> skip i 0; process i o d
    | `El_start _ -> copy i o; process i o (d + 1)
    | `El_end -> copy i o; if d = 0 then () else process i o (d - 1)
    | `Data _ -> copy i o; process i o d
    | `Dtd _ -> assert false
  in
  let rec docs i o = 
    copy i o; (* `Dtd *)
    copy i o; (* root start *)
    process i o 0;
    if Xmlm.eoi i then () else docs i o
  in
  docs i o]}

    {2:extree Tree processing} 

    A document's sequence of signals can be easily converted
    to an arborescent data structure. Assume your trees are defined by :
    {[type tree = E of Xmlm.tag * tree list | D of string]}
    The following functions input/output xml documents from/to abstractions 
    as value of type [tree].
{[let in_tree i = 
  let el tag childs = E (tag, childs)  in
  let data d = D d in
  Xmlm.input_doc_tree ~el ~data i

let out_tree o t = 
  let frag = function
  | E (tag, childs) -> `El (tag, childs) 
  | D d -> `Data d 
  in
  Xmlm.output_doc_tree frag o t]} 

    {2:exrow Tabular data processing}

    We show how to process XML data that represents tabular data (some
    people like do that).

    The file we need to deal with represents nominal data about
    {{:http://www.w3.org/}W3C bureaucrats}. There are no namespaces
    and attributes are ignored. The element structure of the document
    is :
    {ul {- <list>
     {ul {- <bureaucrat> represents a W3C bureaucrat
           (zero or more).

        A bureaucrat contains the following elements, in order.
        {ul {- <name> its name (mandatory, string).}
            {- <surname> its surname (mandatory, string).}
            {- <honest> present iff he implemented one of its spec 
               (optional, empty).}
            {- <obfuscation_level> its grade on the
               open scale of obfuscation (mandatory, float).}
            {- <tr> (zero or more, string), technical reports he
               worked on.}}}}}}

    In OCaml we represent a W3C bureaucrat by this type :
{[type w3c_bureaucrat = { 
    name : string; 
    surname : string; 
    honest : bool; 
    obfuscation_level : float;
    trs : string list; }]}
    The following functions input and output W3C bureaucrats as lists
    of values of type [w3c_bureaucrat].
{[let in_w3c_bureaucrats src = 
  let i = Xmlm.make_input ~strip:true src in
  let tag n = ("", n), [] in
  let error () = invalid_arg "parse error" in
  let accept s i = if Xmlm.input i = s then () else error () in
  let rec i_seq el acc i = match Xmlm.peek i with 
  | `El_start _ -> i_seq el ((el i) :: acc) i
  | `El_end -> List.rev acc
  | _ -> error ()
  in
  let i_el n i = 
    accept (`El_start (tag n)) i;
    let d = match Xmlm.peek i with
    | `Data d -> ignore (Xmlm.input i); d
    | `El_end -> ""
    | _ -> error ()
    in
    accept (`El_end) i;
    d
  in
  let i_bureaucrat i = 
    try
      accept (`El_start (tag "bureaucrat")) i;
      let name = i_el "name" i in
      let surname = i_el "surname" i in
      let honest = match Xmlm.peek i with
      | `El_start (("", "honest"), []) -> ignore (i_el "honest" i); true
      | _ -> false
      in
      let obf = float_of_string (i_el "obfuscation_level" i) in
      let trs = i_seq (i_el "tr") [] i in
      accept (`El_end) i;
      { name = name; surname = surname; honest = honest; 
        obfuscation_level = obf; trs = trs }
    with
    | Failure _ -> error () (* float_of_string *)
  in
  accept (`Dtd None) i;
  accept (`El_start (tag "list")) i;
  let bl = i_seq i_bureaucrat [] i in
  accept (`El_end) i;
  if not (Xmlm.eoi i) then invalid_arg "more than one document";
  bl

let out_w3c_bureaucrats dst bl = 
  let tag n = ("", n), [] in
  let o = Xmlm.make_output ~nl:true ~indent:(Some 2) dst in
  let out = Xmlm.output o in
  let o_el n d = 
    out (`El_start (tag n)); 
    if d <> "" then out (`Data d); 
    out `El_end 
  in
  let o_bureaucrat b = 
    out (`El_start (tag "bureaucrat"));
    o_el "name" b.name;
    o_el "surname" b.surname;
    if b.honest then o_el "honest" "";
    o_el "obfuscation_level" (string_of_float b.obfuscation_level);
    List.iter (o_el "tr") b.trs;
    out `El_end
  in
  out (`Dtd None);
  out (`El_start (tag "list"));
  List.iter o_bureaucrat bl;
  out (`El_end)]}
*)

val to_string : t -> string
val of_string :
  ?entity:(string -> string option) ->
  ?templates:( (string * t) list ) ->
  ?enc:encoding ->
  string -> t

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
