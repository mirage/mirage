(*
 * Copyright (c) 2009 Anil Madhavapeddy <anil@recoil.org>
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

open Printf

module Printer = struct    
    type env = {
        fn: int -> string -> unit;
        p: string -> unit;         (* printer function *)
        i: int;                    (* indent level *)
        nl: unit -> unit;          (* new line *)
        dbg: bool;
    }

    let indent e = { e with i = succ e.i; p = e.fn (succ e.i) }

    let indent_fn e fn =
        let e = indent e in
        fn e


    let list_iter_indent e fn l =
        List.iter (indent_fn e fn) l

    let hashtbl_iter_indent e fn h =
        Hashtbl.iter (indent_fn e fn) h

    let may fn = function
        |None -> ()
        |Some x -> fn x

    let must fn = function
        |None -> failwith "must"
        |Some x -> fn x

    let init_printer ?(msg=None) ?(debug=false) fout =
        let ind i s = String.make (i * 2) ' ' ^ s in
        let out i s = output_string fout ((ind i s) ^ "\n") in
        may (out 0) msg;
        {
            fn = out;
            i = 0;
            p = (out 0);
            nl = (fun (x:unit) -> out 0 "");
            dbg = debug;
        }
        
    let print_module e n fn =
        e.p (sprintf "module %s = struct" (String.capitalize n));
        indent_fn e fn;
        e.p "end";
        e.nl ()

    let print_module_sig e n fn =
        e.p (sprintf "module %s : sig" (String.capitalize n));
        indent_fn e fn;
        e.p "end"
    
    let print_record e nm fn =
        e.p (sprintf "type %s = {" nm);
        indent_fn e fn;
        e.p "}";
        e.nl ()

    let print_object e nm fn =
        e.p (sprintf "type %s = <" nm);
        indent_fn e fn;
        e.p ">";
        e.nl ()

    let print_comment e fmt =
        let xfn s = e.p ("(* " ^ s ^ " *)") in
        kprintf xfn fmt

    let print_ocamldoc e ?(raises="") ?(args="") body =
        e.p (sprintf "(** %s%s" (match args with "" -> "" |x -> sprintf "[%s] " x)  body);
        (match raises with "" -> () |r -> e.p (" @raise " ^ r));
        e.p "  *)"
    
    let pfn e fmt =
        let xfn s = e.p s in
        kprintf xfn fmt

    let dbg e fmt =
        let xfn s = if e.dbg then pfn e "print_endline (%s);" s in
        kprintf xfn fmt

    let (--*) = print_comment
    let (-->) e fn = indent_fn e fn
    let (+=) = pfn 
    let (-=) = dbg
    let ($) f x = f x
 
end

