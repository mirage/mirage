(*
 * The Computer Language Benchmarks Game
 * http://shootout.alioth.debian.org/
 *
 * Contributed by Christophe TROESTLER
 * Enhanced by Christian Szegedy, Yaron Minsky.
 * Optimized & parallelized by Mauricio Fernandez.
 *
 *)

let nworkers = 16
let niter = 50
let limit = 2.

type complex = { mutable r: float; mutable i: float }

(* semi-standard function for parallelism *)
let invoke (f : 'a -> 'b) x : unit -> 'b =
  let v = f x in fun () -> v

let calc size =
  let w = size in
  let h = w in
  let fw = float w and fh = float h in
  let z = {r=0.; i=0.;} in
  let limit2 = limit *. limit in
  let byte = ref 0 in

  let mandelbrot (ymin, ymax) =
    let b = Buffer.create (((ymax - ymin + 1) * w + 7) / 8) in
    for y = ymin to ymax do
      let ci = 2. *. float y /. fh -. 1. in
        for x = 0 to w - 1 do
          let cr = 2. *. float x /. fw -. 1.5 in
            z.r <- 0.; z.i <- 0.;
            let bit = ref 1 and i = ref niter in
              while !i > 0 do
                let zr = z.r and zi = z.i in
                let zi = 2. *. zr *. zi +. ci and zr = zr *. zr -. zi *. zi +. cr in
                  z.r <- zr;
                  z.i <- zi;
                  decr i;
                  if zr *. zr +. zi *. zi > limit2 then begin
                    bit := 0;
                    i := 0;
                  end;
              done;
              byte := (!byte lsl 1) lor !bit;
              if x land 0x7 = 7 then Buffer.add_char b (Char.unsafe_chr !byte);
        done;
        if w mod 8 != 0 then (* the row doesnt divide evenly by 8*)
          Buffer.add_char b (Char.unsafe_chr (!byte lsl (8-w mod 8)));
        byte := 0;
    done;
    Buffer.contents b in

  let dy = h / nworkers in
  let y = ref 0 in
  let rs = Array.init (nworkers - 1)
             (fun _ -> let y'= !y + dy in let r = (!y, y') in y := y'+1; r) in
  let _ = Array.map (invoke mandelbrot) (Array.append rs [|!y, h-1|]) in
  w, h
(* Array.iter (fun w -> output_string stdout (w ())) workers *)

let _ =
  let _ = Gc.create_alarm (fun () -> Printf.printf "gc\n%!") in 
  let sizes = [ 1600; 3200; 10000 ] in
  List.iter (fun sz ->
    let t1 = Mir.gettimeofday () in
    let w,h = calc sz in
    let t2 = Mir.gettimeofday () in
    Printf.printf "%d,%d,%d,%.3f\n%!" sz w h (t2 -. t1)
  ) sizes
