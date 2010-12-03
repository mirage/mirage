(*
  Copyright (c) 2009 Mauricio Fernández <mfp@acm.org>
  Copyright (c) 2009-2010 Anil Madhavapeddy <anil@recoil.org>
  Copyright (c) 2010 Thomas Gazagnaire <thomas@gazagnaire.org>

  Permission is hereby granted, free of charge, to any person
  obtaining a copy of this software and associated documentation
  files (the "Software"), to deal in the Software without
  restriction, including without limitation the rights to use,
  copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the
  Software is furnished to do so, subject to the following
  conditions:

  The above copyright notice and this permission notice shall be
  included in all copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
  OTHER DEALINGS IN THE SOFTWARE.
*)

open Printf

type ref = { src : string; desc : string }

type paragraph =
    Normal of par_text
  | Pre of string * string option
  | Heading of int * par_text
  | Quote of paragraph list
  | Ulist of paragraph list * paragraph list list
  | Olist of paragraph list * paragraph list list

and par_text = text list

and text =
    Text of string
  | Emph of string
  | Bold of string
  | Struck of par_text
  | Code of string
  | Link of href
  | Anchor of string
  | Image of img_ref

and href = { href_target : string; href_desc : string; }

and img_ref = { img_src : string; img_alt : string; }

type t = paragraph list 

type parse_state = { max : int; current : Buffer.t; fragments : text list; }

let indentation ?(ts=8) s =
  let rec loop n indent max =
    if n >= max then indent
    else match s.[n] with
        ' ' -> loop (n + 1) (indent + 1) max
      | '\t' -> loop (n + 1) (indent + 8) max
      | _ -> indent
  in loop 0 0 (String.length s)

let unescape s =
  let b = Buffer.create (String.length s) in
  let len = String.length s in
  let rec loop i =
    if i >= len then Buffer.contents b
    else match s.[i] with
        '\\' when i < len - 1 -> Buffer.add_char b s.[i+1]; loop (i + 2)
      | c -> Buffer.add_char b c; loop (i + 1)
  in loop 0

let slice ?(first=0) ?(last=Sys.max_string_length) s =
        let clip _min _max x = max _min (min _max x) in
        let i = clip 0 (String.length s)
                (if (first<0) then (String.length s) + first else first)
        and j = clip 0 (String.length s)
                (if (last<0) then (String.length s) + last else last)
        in
        if i>=j || i=String.length s then
                String.create 0
        else
                String.sub s i (j-i)

let strip ?(chars=" \t\r\n") s =
        let p = ref 0 in
        let l = String.length s in
        while !p < l && String.contains chars (String.get s !p) do
                incr p;
        done;
        let p = !p in
        let l = ref (l - 1) in
        while !l >= p && String.contains chars (String.get s !l) do
                decr l;
        done;
        String.sub s p (!l - p + 1)

let unescape_slice s ~first ~last =
  unescape (strip (slice ~first ~last s))

let snd_is s c = String.length s > 1 && s.[1] = c
let snd_is_space s = snd_is s ' ' || snd_is s '\t'

let collect f x =
  let rec loop acc = match f x with
      None -> List.rev acc
    | Some y -> loop (y :: acc)
  in loop []

let push_remainder ?(first=2) indent s e =
  let s = slice ~first s in
  let s' = strip s in
    Enum.push e (indent + first + indentation s, s', s' = "")

let adds = Buffer.add_string

let addc = Buffer.add_char

let new_fragment () = Buffer.create 8

let push_current st =
  if Buffer.length st.current > 0 then
    Text (Buffer.contents st.current) :: st.fragments
  else st.fragments

let rec read_paragraph ?(skip_blank=true) indent e = match Enum.peek e with
    None -> None
  | Some (indentation, line, isblank) -> match isblank with
        true ->
          Enum.junk e;
          if skip_blank then read_paragraph indent e else None
      | false ->
          if indentation < indent then
            None
          else begin
            Enum.junk e;
            read_nonempty indentation e line
          end

and skip_blank_line e = match Enum.peek e with
    None | Some (_, _, false) -> ()
  | Some (_, _, true) -> Enum.junk e; skip_blank_line e

and read_nonempty indent e s = match s.[0] with
    '!' -> read_heading s
  | '*' when snd_is_space s -> push_remainder indent s e; read_ul indent e
  | '#' when snd_is_space s -> push_remainder indent s e; read_ol indent e
  | '{' when snd_is s '{' -> read_pre (slice s ~first:2) e
  | '>' when snd_is_space s || s = ">" ->
      (* last check needed because "> " becomes ">" *)
      Enum.push e (indent, s, false); read_quote indent e
  | _ -> Enum.push e (indent, s, false); read_normal e

and read_heading s =
  let s' = strip ~chars:"!" s in
  let level = String.length s - (String.length s') in
    Some (Heading (level, parse_text s'))

and read_ul indent e =
  read_list
    (fun fst others -> Ulist (fst, others))
    (fun s -> snd_is_space s && s.[0] = '*')
    indent e

and read_ol indent e =
  read_list
    (fun fst others -> Olist (fst, others))
    (fun s -> snd_is_space s && s.[0] = '#')
    indent e

and read_list f is_item indent e =
  let read_item indent ps = collect (read_paragraph (indent + 1)) e in
  let rec read_all fst others =
    skip_blank_line e;
    match Enum.peek e with
      | Some (indentation, s, _) when indentation >= indent && is_item s ->
          Enum.junk e;
          push_remainder indentation s e;
          read_all fst (read_item indentation [] :: others)
      | None | Some _ -> f fst (List.rev others)
  in Some (read_all (read_item indent []) [])

and read_pre kind e =
  let kind = match kind with "" -> None | s -> Some s in
  let re = Str.regexp "^\\\\+}}$" in
  let unescape = function
      s when Str.string_match re s 0 -> slice ~first:1 s
    | s -> s in
  (*  don't forget the last \n *)
  let ret ls = Some (Pre (String.concat "\n" (List.rev ("" :: ls)), kind)) in
  let rec read_until_end fstindent ls = match Enum.get e with
      None | Some (_, "}}", _) -> ret ls
    | Some (indentation, s, _) ->
        let spaces = String.make (max 0 (indentation - fstindent)) ' ' in
          read_until_end fstindent ((spaces ^ unescape s) :: ls)
  in match Enum.get e with
      None | Some (_, "}}", _) -> ret []
    | Some (indentation, s, _) -> read_until_end indentation [s]

and read_quote indent e =
  let push_and_finish e elm = Enum.push e elm; raise Enum.No_more_elements in
  let next_without_lt e = function
    | (_, _, true) as line -> push_and_finish e line
    | (n, s, false) as line ->
        if n < indent || s.[0] <> '>' then
          push_and_finish e line
        else
          let s = slice ~first:1 s in
          let s' = strip s in
            (String.length s - String.length s', s', s' = "")

  in match collect (read_paragraph 0) (Enum.map (next_without_lt e) e) with
      [] -> None
    | ps -> Some (Quote ps)

and read_normal e =
  let rec gettxt ls =
    let return () = String.concat " " (List.rev ls) in
    match Enum.peek e with
      None | Some (_, _, true) -> return ()
    | Some (_, l, _) -> match l.[0] with
            '!' | '*' | '#' | '>' when snd_is_space l -> return ()
          | '{' when snd_is l '{' -> return ()
          | _ -> Enum.junk e; gettxt (l :: ls) in
  let txt = gettxt [] in
    Some (Normal (parse_text txt))

and parse_text s =
  scan
    s
    { max = String.length s;
      fragments = [];
      current = new_fragment (); }
    0

  (* scan s starting from n, upto max (exclusive) *)
and scan s st n =
  let max = st.max in
  if n >= max then List.rev (push_current st)

  else match s.[n] with
    | '`' ->
        delimited (fun ~first ~last -> Code (unescape_slice s ~first ~last)) "`"
          s st n
    | '*' ->
        delimited (fun ~first ~last -> Bold (unescape_slice s ~first ~last)) "*"
          s st n
    | '_' ->
        delimited (fun ~first ~last -> Emph (unescape_slice s ~first ~last)) "__"
          s st n
    | '=' ->
        delimited
          (fun ~first ~last ->
             Struck (scan s
                       { max = last; fragments = []; current = new_fragment (); }
                       first))
          "==" s st n
    | '!' when matches_at s ~max n "![" ->
        maybe_link
          "![" (fun ref -> Image { img_src = ref.src; img_alt = ref.desc })
          s st (n + 2)
    | '[' ->
        maybe_link "["
          (fun ref -> match ref.src, ref.desc with
               "", "" -> Text ""
             | "", desc -> Link { href_target = desc; href_desc = desc }
             | src, "" when src.[0] = '#' -> Anchor (slice ~first:1 src)
             | src, desc -> Link { href_target = ref.src; href_desc = ref.desc})
          s st (n + 1)
    | '\\' when (n + 1) < max -> addc st.current s.[n+1]; scan s st (n + 2)
    | c -> addc st.current c; scan s st (n + 1)

(* [delimited f delim first] tries to match [delim] starting from [first],
 * returns Some (offset of char after closing delim) or None *)
and delimited f delim s st first =
  let max = st.max in
  let delim_len = String.length delim in
  let scan_from_next_char () =
    addc st.current s.[first];
    scan s st (first + 1)
  in
    if not (matches_at s ~max first delim) then scan_from_next_char ()
    else match scan_past ~delim s ~max (first + String.length delim) with
        Some n ->
          let chunk = f ~first:(first + delim_len)
                        ~last:(n - String.length delim)
          in scan s
               { st with fragments = chunk :: push_current st;
                         current = new_fragment () }
               n
      | None -> scan_from_next_char ()

and maybe_link delim f s st n = match scan_link s ~max:st.max n with
    None -> adds st.current delim; scan s st n
  | Some (ref, n) ->
      scan s
        { st with fragments = f ref :: push_current st;
                  current = (new_fragment ()) }
        n

(* return None if delim not found, else Some (offset of char *after* delim) *)
and scan_past ~delim s ~max n =
  let re = Str.regexp (Str.quote delim) in
  let rec loop m ~max =
    if m >= max then None else
      match (try Some (Str.search_forward re s m) with Not_found -> None) with
        | Some m when m < max && s.[m-1] <> '\\' -> Some (m + String.length delim)
        | Some m when m < max -> loop (m + 1) ~max
        | _ -> None (* no match or >= max  *)
  in loop n ~max

(* returns None or offset of char after the reference
 * (i.e. after closing ')'). *)
and scan_link s ~max n = match scan_past ~delim:"]" s ~max n with
    None -> None
  | Some end_of_desc ->
      if end_of_desc >= max then None
      else match s.[end_of_desc] with
          '(' ->
            begin match scan_past ~delim:")" s ~max (end_of_desc + 1) with
                None -> None
              | Some end_of_uri ->
                  let ref =
                    {
                      desc = unescape_slice s ~first:n ~last:(end_of_desc - 1);
                      src = unescape_slice s
                              ~first:(end_of_desc + 1)
                              ~last:(end_of_uri - 1)
                    }
                  in Some (ref, end_of_uri)
            end
        | _ -> None

and matches_at s ~max n delim =
  let len = String.length delim in
    if n + len > max then false
    else
      let rec loop n m k =
        if k = 0 then true
        else if s.[n] = delim.[m] then loop (n + 1) (m + 1) (k - 1)
        else false
      in loop n 0 len

let parse_enum e =
  collect (read_paragraph 0)
    (Enum.map (fun l -> let l' = strip l in (indentation l, l', l' = "")) e)

let parse_lines ls = parse_enum (Enum.of_list ls)
let parse_text s = parse_lines ((Str.split (Str.regexp "\n") s))

let rec text = function
    Text t    -> <:html< $str:t$ >>
  | Emph t    -> <:html< <i>$str:t$</i> >>
  | Bold t    -> <:html< <b>$str:t$</b> >>
  | Struck pt -> <:html< <del>$par_text pt$</del> >>
  | Code t    -> <:html< <code>$str:t$ </code> >>
  | Link href -> <:html< <a href=$str:href.href_target$>$str:href.href_desc$</a> >>
  | Anchor a  -> <:html< <a name=$str:a$/> >>
  | Image img -> <:html< <img src=$str:img.img_src$ alt=$str:img.img_alt$/> >>

and para = function
    Normal pt        -> <:html< $par_text pt$ >>
  | Pre (t,kind)     -> <:html< <pre><code>$str:t$</code></pre> >>
  | Heading (1,pt)   -> <:html< <h1>$par_text pt$</h1> >>
  | Heading (2,pt)   -> <:html< <h2>$par_text pt$</h2> >>
  | Heading (3,pt)   -> <:html< <h3>$par_text pt$</h3> >>
  | Heading (_,pt)   -> <:html< <h4>$par_text pt$</h4> >>
  | Quote pl         -> <:html< <blockquote>$paras pl$</blockquote> >>
  | Ulist (pl,pll)   -> let l = pl :: pll in <:html< <ul>$li l$ </ul> >>
  | Olist (pl,pll)   -> let l = pl :: pll in <:html< <ol>$li l$ </ol> >>

and par_text pt = <:html< $list:List.map text pt$ >>

and li pl =
  let aux p = <:html< <li>$paras p$</li> >> in
  <:html< $list:List.map aux pl$ >>

and paras ps =
  let aux p = <:html< <p>$para p$</p> >> in
  <:html< $list:List.map aux  ps$ >>

let to_html ps =
  <:html< <div class="post"> $paras ps$ </div> >>

let of_string = parse_text
