(* Buffered reading and writing over the flow API *)

type outch = {
  ibuf: OS.Istring.View.t Lwt_sequence.t;
  obuf: OS.Istring.View.t Lwt_sequence.t;
  mutable ilen: int;
  mutable ipos: int;
  mutable opos: int;
  abort_t: unit Lwt.t;
  abort_u: unit Lwt.u;
  flow: Flow.t;
}

exception Closed

let t flow =
  let ibuf = Lwt_sequence.create () in
  let obuf = Lwt_sequence.create () in
  let ilen = 0 in
  let ipos = 0 in
  let opos = 0 in
  let abort_t, abort_u = Lwt.task () in
  { ibuf; obuf; ipos; opos; flow; abort_t; abort_u }

(* Ensure the input buffer has enough for our purposes *)
let rec ibuf_need t amt =
  if t.ilen < t.ipos + amt then begin
    lwt res = Flow.read t in
    match res with
    |None -> fail Closed
    |Some view ->
      let _ = Lwt_sequence.add_r view t.ibuf in
      t.ilen <- OS.Istring.View.length view + t.ilen;
      ibuf_need t amt
  end else
    return (Lwt_sequence.peek_r t.ibuf)

(* Increment the input buffer position *)
let rec ibuf_incr t amt =
  let buf = Lwt_sequence.peek_r t.ibuf in
  let buf_len = OS.Istring.View.length buf in
  let ipos = t.ipos in
  if (ipos + amt) >= buf_len then begin
    (* This buf has been consumed. Free it *)
    let _ = Lwt_sequence.take_l t.ibuf in
    t.ilen <- i.ilen - buf_len;
    t.ipos <- 0;
    if ipos + amt - buf_len > 0 then begin
      (* More buffers need removing *)
      ibuf_incr t (ipos + amt - buf_len)
    end
  end else begin
    (* Continue to partially consume head buf *)
    t.ipos <- t.ipos + amt
  end

let read_char t =
  lwt view = ibuf_need t 1 in
  let ch = OS.Istring.View.get_char view t.ipos in
  ibuf_incr t 1;
  ch

(* Read until a character is encountered *)
let read_until t ch =
  (* require at least one character to start with *)
  lwt view = ibuf_need t 1 in
  match OS.Istring.View.scan_char view t.ipos ch with
  |(-1) -> 
    (* slow path, need another segment *)
    let segs = Lwt_sequence.create () in
    let headview = Lwt_sequence.take_l t.ibuf in
    let start_pos = t.ipos in
    let start_len = OS.Istring.View.length headview - start_pos in
    t.ipos <- 0;
    t.ilen <- t.ilen - (OS.Istring.View.length headview);
    let rec scan () =
      lwt view = ibuf_need t 1 in
      match OS.Istring.View.scan_char view 0 ch with
      |(-1) ->
        let view = Lwt_sequence.take_l t.ibuf in
        let _ = Lwt_sequence.add_r view segs in
        t.ilen <- t.ilen - (OS.Istring.View.length buf);
        scan ()
      |idx ->
        let segs_len = Lwt_sequence.fold_l
          (fun v a -> OS.Istring.View.length v + a) segs 0 in
        (* Total length, not including delimiter *)
        let total_len = start_len + segs_len + idx in
        let s = String.create total_len in
        (* Blit the head view in *)
        OS.Istring.View.blit headview start_pos s 0 start_len;
        (* Blit intermediate views in *)
        let last_off = Lwt_sequence.fold_l (fun view off ->
          let len = OS.Istring.View.length view in
          OS.Istring.View.blit view 0 s off len;
          off + len) segs start_pos in
        (* Blit last view in *)
        OS.Istring.View.blit view 0 s last_off idx;
        ibuf_incr t (idx+1);
        return s
    in scan ()
  |idx ->
    let len = idx - t.pos in
    if len <= 0 then 
      return (String.create 0) 
    else begin
      let s = OS.Istring.View.to_string view t.pos len in
      ibuf_incr t (len+1);
    end
