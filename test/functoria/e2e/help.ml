(*
 * Copyright (c) 2015 Jeremy Yallop
 * Copyright (c) 2021 Thomas Gazagnaire <thomas@gazagnaire.org>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *)

open Astring

(* cut a man page into sections *)
let by_sections s =
  let lines = String.cuts ~sep:"\n" s in
  let return l =
    match List.rev l with [] -> assert false | h :: t -> (h, t)
  in
  let rec aux current sections = function
    | [] -> List.rev (return current :: sections)
    | h :: t ->
        if
          String.length h > 1
          && String.for_all (fun x -> Char.Ascii.(is_upper x || is_white x)) h
        then aux [ h ] (return current :: sections) t
        else aux (h :: current) sections t
  in
  aux [ "INIT" ] [] lines

let sections = [ "CONFIGURE OPTIONS"; "APPLICATION OPTIONS"; "COMMON OPTIONS" ]

let read file =
  let ic = open_in_bin file in
  let str = really_input_string ic (in_channel_length ic) in
  close_in ic;
  by_sections str

let err_usage () =
  Fmt.pr "[usage]: ./help.exe [diff|show] PARAMS\n";
  exit 1

let () =
  if Array.length Sys.argv <> 4 then err_usage ()
  else
    match Sys.argv.(1) with
    | "diff" ->
        let s1 = read Sys.argv.(2) in
        let s2 = read Sys.argv.(3) in
        List.iter
          (fun name ->
            match (List.assoc_opt name s1, List.assoc_opt name s2) with
            | Some s1, Some s2 ->
                if List.length s1 <> List.length s2 then
                  Fmt.failwith "Number of lines in %S differs" name
                else
                  List.iter2
                    (fun s1 s2 ->
                      if s1 <> s2 then
                        Fmt.failwith "Lines in section %S differ:\n  %S\n  %S\n"
                          name s1 s2)
                    s1 s2
            | _ -> Fmt.failwith "Section %S differs" name)
          sections
    | "show" -> (
        let s1 = read Sys.argv.(2) in
        let name = Sys.argv.(3) in
        match List.assoc_opt name s1 with
        | None -> ()
        | Some s -> List.iter print_endline s)
    | _ -> err_usage ()
