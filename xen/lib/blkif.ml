(*
 * Copyright (c) 2011 Anil Madhavapeddy <anil@recoil.org>
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

open Lwt
open Printf

type proto = | X86_64 | X86_32 | Native

(* Block requests; see include/xen/io/blkif.h *)
module Req = struct

  (* Defined in include/xen/io/blkif.h, BLKIF_REQ_* *)
  cenum op {
    Read          = 0;
    Write         = 1;
    Write_barrier = 2;
    Flush         = 3;
    Op_reserved_1 = 4; (* SLES device-specific packet *)
    Trim          = 5
  } as uint8_t

  let string_of_op = function
  | Read -> "Read" | Write -> "Write" | Write_barrier -> "Write_barrier"
  | Flush -> "Flush" | Op_reserved_1 -> "Op_reserved_1" | Trim -> "Trim"

  exception Unknown_request_type of int

  (* Defined in include/xen/io/blkif.h BLKIF_MAX_SEGMENTS_PER_REQUEST *)
  let segments_per_request = 11

  type seg = {
    gref: int32;
    first_sector: int;
    last_sector: int;
  }

  let string_of_seg seg =
    Printf.sprintf "{gref=%ld first=%d last=%d}" seg.gref seg.first_sector seg.last_sector

  let string_of_segs segs = 
    Printf.sprintf "[%s]" (String.concat "," (List.map string_of_seg (Array.to_list segs)))

  (* Defined in include/xen/io/blkif.h : blkif_request_t *)
  type t = {
    op: op option;
    handle: int;
    id: int64;
    sector: int64;
    segs: seg array;
  }

  let string_of t =
    Printf.sprintf "op=%s\nhandle=%d\nid=%Ld\nsector=%Ld\nsegs=%s\n"
    (match t.op with Some x -> string_of_op x | None -> "None")
      t.handle t.id t.sector (string_of_segs t.segs)

  (* The segment looks the same in both 32-bit and 64-bit versions *)
  cstruct segment {
    uint32_t       gref;
    uint8_t        first_sector;
    uint8_t        last_sector;
    uint16_t       _padding
  } as little_endian
  let _ = assert (sizeof_segment = 8)

  (* The request header has a slightly different format caused by
     not using __attribute__(packed) and letting the C compiler pad *)
  module type PROTO = sig
    val sizeof_hdr: int
    val get_hdr_op: Io_page.t -> int
    val set_hdr_op: Io_page.t -> int -> unit
    val get_hdr_nr_segs: Io_page.t -> int
    val set_hdr_nr_segs: Io_page.t -> int -> unit
    val get_hdr_handle: Io_page.t -> int
    val set_hdr_handle: Io_page.t -> int -> unit
    val get_hdr_id: Io_page.t -> int64
    val set_hdr_id: Io_page.t -> int64 -> unit
    val get_hdr_sector: Io_page.t -> int64
    val set_hdr_sector: Io_page.t -> int64 -> unit
  end

  module Marshalling = functor(P: PROTO) -> struct
    open P
    (* total size of a request structure, in bytes *)
    let total_size = sizeof_hdr + (sizeof_segment * segments_per_request)

    (* Write a request to a slot in the shared ring. *)
    let write_request req slot =
      set_hdr_op slot (match req.op with None -> -1 | Some x -> op_to_int x);
      set_hdr_nr_segs slot (Array.length req.segs);
      set_hdr_handle slot req.handle;
      set_hdr_id slot req.id;
      set_hdr_sector slot req.sector;
      let payload = Cstruct.shift slot sizeof_hdr in
      Array.iteri (fun i seg ->
          let buf = Cstruct.shift payload (i * sizeof_segment) in
          set_segment_gref buf seg.gref;
          set_segment_first_sector buf seg.first_sector;
          set_segment_last_sector buf seg.last_sector
      ) req.segs;
      req.id

    (* Read a request out of an Io_page.t; to be used by the Ring.Back for serving
       requests, so this is untested for now *)
    let read_request slot =
      let payload = Cstruct.shift slot sizeof_hdr in
      let segs = Array.init (get_hdr_nr_segs slot) (fun i ->
          let seg = Cstruct.shift payload (i * sizeof_segment) in {
              gref = get_segment_gref seg;
              first_sector = get_segment_first_sector seg;
              last_sector = get_segment_last_sector seg;
          }
      ) in {
          op = int_to_op (get_hdr_op slot);
          handle = get_hdr_handle slot;
          id = get_hdr_id slot;
          sector = get_hdr_sector slot;
          segs = segs
      }

  end
  module Proto_64 = Marshalling(struct
    cstruct hdr {
      uint8_t        op;
      uint8_t        nr_segs;
      uint16_t       handle;
      uint32_t       _padding; (* emitted by C compiler *)
      uint64_t       id;
      uint64_t       sector
    } as little_endian
  end)
  module Proto_32 = Marshalling(struct
    cstruct hdr {
      uint8_t        op;
      uint8_t        nr_segs;
      uint16_t       handle;
      (* uint32_t       _padding; -- not included *)
      uint64_t       id;
      uint64_t       sector
    } as little_endian
  end)
end

module Res = struct

  (* Defined in include/xen/io/blkif.h, BLKIF_RSP_* *)
  cenum rsp {
    OK            = 0;
    Error         = 0xffff;
    Not_supported = 0xfffe
  } as uint16_t

  (* Defined in include/xen/io/blkif.h, blkif_response_t *)
  type t = {
    op: Req.op option;
    st: rsp option;
  }

  (* The same structure is used in both the 32- and 64-bit protocol versions,
     modulo the extra padding at the end. *)
  cstruct response_hdr {
    uint64_t       id;
    uint8_t        op;
    uint8_t        _padding;
    uint16_t       st;
    (* 64-bit only but we don't need to care since there aren't any more fields: *)
    uint32_t       _padding
  } as little_endian

  let write_response (id, t) slot =
    set_response_hdr_id slot id;
    set_response_hdr_op slot (match t.op with None -> -1 | Some x -> Req.op_to_int x);
    set_response_hdr_st slot (match t.st with None -> -1 | Some x -> rsp_to_int x)

  let read_response slot =
    get_response_hdr_id slot, {
      op = Req.int_to_op (get_response_hdr_op slot);
      st = int_to_rsp (get_response_hdr_st slot)
    }
end

module Backend = struct
  type ops = {
    read : Io_page.t -> int64 -> int -> int -> unit Lwt.t;
    write : Io_page.t -> int64 -> int -> int -> unit Lwt.t;
  }

  type t = {
    domid:  int;
    xg:     Gnttab.handle;
    evtchn: int;
    ops :   ops;
    parse_req : Io_page.t -> Req.t;
  }

  let process t ring slot =
    let open Req in
    let req = t.parse_req slot in
    let fn = match req.op with
      | Some Read -> t.ops.read
      | Some Write -> t.ops.write
      | _ -> failwith "Unhandled request type"
    in
    let (_,threads) = List.fold_left (fun (off,threads) seg ->
      let sector = Int64.add req.sector (Int64.of_int off) in
      let perm = match req.op with
        | Some Read -> Gnttab.RO 
        | Some Write -> Gnttab.RW
        | _ -> failwith "Unhandled request type" in
      let thread = Gnttab.with_mapping t.xg t.domid seg.gref perm
        (fun page -> fn page sector seg.first_sector seg.last_sector) in
      let newoff = off + (seg.last_sector - seg.first_sector + 1) in
      (newoff,thread::threads)
    ) (0, []) (Array.to_list req.segs) in
    let _ = (* handle the work in a background thread *)
      lwt () = Lwt.join threads in
      let open Res in 
      let slot = Ring.Back.(slot ring (next_res_id ring)) in
      write_response (req.id, {op=req.Req.op; st=Some OK}) slot;
      let notify = Ring.Back.push_responses_and_check_notify ring in
      (* XXX: what is this:
        if more_to_do then Activations.wake t.evtchn; *)
      if notify then Evtchn.notify t.evtchn;
      Lwt.return ()
    in ()

    let init xg domid ring_ref evtchn_ref proto ops =
      let evtchn = Evtchn.bind_interdomain domid evtchn_ref in
      let parse_req, idx_size = match proto with
        | X86_64 -> Req.Proto_64.read_request, Req.Proto_64.total_size
        | X86_32 -> Req.Proto_32.read_request, Req.Proto_64.total_size
        | Native -> Req.Proto_64.read_request, Req.Proto_64.total_size
      in
      let buf = Gnttab.map_contiguous_grant_refs xg domid [ ring_ref ] Gnttab.RW in
      let ring = Ring.of_buf ~buf ~idx_size ~name:"blkback" in
      let r = Ring.Back.init ring in
      let t = { domid; xg; evtchn; ops; parse_req } in
      let th = Ring.Back.service_thread r evtchn (process t r) in
      on_cancel th (fun () -> Gnttab.unmap xg buf);
      th
end


type features = {
  barrier: bool;
  removable: bool;
  sector_size: int64; (* stored as int64 for convenient division *)
  sectors: int64;
  readwrite: bool;
}

type t = {
  backend_id: int;
  backend: string;
  vdev: int;
  ring: (Res.t,int64) Ring.Front.t;
  gnts: Gnttab.r list;
  evtchn: int;
  features: features;
}

type id = string
exception IO_error of string

(** Set of active block devices *)
let devices : (id, t) Hashtbl.t = Hashtbl.create 1

(* Allocate a ring, given the vdev and backend domid *)
let alloc ~order (num,domid) =
  let name = sprintf "Blkif.%d" num in
  let idx_size = Req.Proto_64.total_size in (* bigger than res *)
  lwt (rx_gnts, buf) = Ring.allocate ~domid ~order in
  let sring = Ring.of_buf ~buf ~idx_size ~name in
  let fring = Ring.Front.init ~sring in
  return (rx_gnts, fring)

(* Thread to poll for responses and activate wakeners *)
let rec poll t =
  Activations.wait t.evtchn >>
  let () = Ring.Front.poll t.ring (Res.read_response) in
  poll t

(* Given a VBD ID and a backend domid, construct a blkfront record *)
let plug (id:id) =
  lwt vdev = try return (int_of_string id)
    with _ -> fail (Failure "invalid vdev") in
  printf "Blkfront.create; vdev=%d\n%!" vdev;
  let node = sprintf "device/vbd/%d/%s" vdev in
  lwt backend_id = Xs.(t.read (node "backend-id")) in
  lwt backend_id = try_lwt return (int_of_string backend_id)
    with _ -> fail (Failure "invalid backend_id") in
  lwt backend = Xs.(t.read (node "backend")) in

  let backend_read fn default k =
    let backend = sprintf "%s/%s" backend in
      try_lwt
        lwt s = Xs.(t.read (backend k)) in
        return (fn s)
      with exn -> return default in

  (* The backend can advertise a multi-page ring: *)
  lwt backend_max_ring_page_order = backend_read int_of_string 0 "max-ring-page-order" in
  if backend_max_ring_page_order = 0
  then printf "Blkback can only use a single-page ring\n%!"
  else printf "Blkback advertises multi-page ring (size 2 ** %d pages)\n%!" backend_max_ring_page_order;

  let our_max_ring_page_order = 2 in (* 4 pages *)
  let ring_page_order = min our_max_ring_page_order backend_max_ring_page_order in
  printf "Negotiated a %s\n%!" (if ring_page_order = 0 then "singe-page ring" else sprintf "multi-page ring (size 2 ** %d pages)" ring_page_order);

  lwt (gnts, ring) = alloc ~order:ring_page_order (vdev,backend_id) in
  let evtchn = Evtchn.alloc_unbound_port backend_id in

  let ring_info =
    (* The new protocol writes (ring-refN = G) where N=0,1,2 *)
    let rfs = snd(List.fold_left (fun (i, acc) g ->
      i + 1, ((sprintf "ring-ref%d" i, Gnttab.to_string g) :: acc)
    ) (0, []) gnts) in
    if ring_page_order = 0
    then [ "ring-ref", Gnttab.to_string (List.hd gnts) ] (* backwards compat *)
    else [ "ring-page-order", string_of_int ring_page_order ] @ rfs in
  let info = [
    "event-channel", string_of_int evtchn;
    "protocol", "x86_64-abi";
    "state", Xb.State.(to_string Connected)
  ] @ ring_info in
  Xs.(transaction t (fun xst ->
    let wrfn k v = xst.Xst.write (node k) v in
    Lwt_list.iter_s (fun (k, v) -> wrfn k v) info
  )) >>
  lwt monitor_t = Xs.(monitor_path Xs.t
    (sprintf "%s/state" backend, "XXX") 20. 
    (fun (k,_) ->
        lwt state = try_lwt Xs.t.Xs.read k with _ -> return "" in
	    return Xb_state.(of_string state = Connected)
	)) in
  (* Read backend features *)
  lwt features =
    lwt state = backend_read (Xb_state.of_string) Xb_state.Unknown "state" in
    printf "state=%s\n%!" (Xb_state.prettyprint state);
    lwt barrier = backend_read ((=) "1") false "feature-barrier" in
    lwt removable = backend_read ((=) "1") false "removable" in
    lwt sectors = backend_read Int64.of_string (-1L) "sectors" in
    lwt sector_size = backend_read Int64.of_string 0L "sector-size" in
    lwt readwrite = backend_read (fun x -> x = "w") false "mode" in
    return { barrier; removable; sector_size; sectors; readwrite }
  in
  printf "Blkfront features: barrier=%b removable=%b sector_size=%Lu sectors=%Lu\n%!" 
    features.barrier features.removable features.sector_size features.sectors;
  Evtchn.unmask evtchn;
  let t = { backend_id; backend; vdev; ring; gnts; evtchn; features } in
  Hashtbl.add devices id t;
  (* Start the background poll thread *)
  let _ = poll t in
  return t

(* Unplug shouldn't block, although the Xen one might need to due
   to Xenstore? XXX *)
let unplug id =
  Console.log (sprintf "Blkif.unplug %s: not implemented yet" id);
  ()

(** Return a list of valid VBDs *)
let enumerate () =
  try_lwt Xs.(t.directory "device/vbd") with Xb.Noent -> return []

let create fn =
  let th,_ = Lwt.task () in
  Lwt.on_cancel th (fun _ -> Hashtbl.iter (fun id _ -> unplug id) devices);
  lwt ids = enumerate () in
  let pt = Lwt_list.iter_p (fun id ->
    lwt t = plug id in
    fn id t) ids in
  th <?> pt

(* Write a single page to disk.
   Offset is the sector number, which must be sector-aligned
   Page must be an Io_page *)
let write_page t offset page =
  let sector = Int64.div offset t.features.sector_size in
  if not t.features.readwrite
  then fail (IO_error "read-only")
  else Gnttab.with_ref
    (fun r ->
      Gnttab.with_grant ~domid:t.backend_id ~perm:Gnttab.RW r page
        (fun () ->
          let gref = Gnttab.to_int32 r in
          let id = Int64.of_int32 gref in
          let segs =[| { Req.gref; first_sector=0; last_sector=7 } |] in
          let req = Req.({op=Some Req.Write; handle=t.vdev; id; sector; segs}) in
          let res = Ring.Front.push_request_and_wait t.ring (Req.Proto_64.write_request req) in
          if Ring.Front.push_requests_and_check_notify t.ring then
            Evtchn.notify t.evtchn;
          let open Res in
          lwt res = res in
          Res.(match res.st with
          | Some Error -> fail (IO_error "write")
          | Some Not_supported -> fail (IO_error "unsupported")
          | None -> fail (IO_error "unknown error")
          | Some OK -> return ())
        )
    )

module Single_request = struct
  (** A large request must be broken down into a series of smaller page-aligned requests: *)
  type t = {
    start_sector: int64; (* page-aligned sector to start reading from *)
    start_offset: int;   (* sector offset into the page of our data *)
    end_sector: int64;   (* last page-aligned sector to read *)
    end_offset: int;     (* sector offset into the page of our data *)
  }

  (** Number of pages required to issue this request *)
  let npages_of t = Int64.(to_int (div (sub t.end_sector t.start_sector) 8L))

  let to_string t =
    sprintf "(%Lu, %u) -> (%Lu, %u)" t.start_sector t.start_offset t.end_sector t.end_offset

  (* Transforms a large read of [num_sectors] starting at [sector] into a Lwt_stream
     of single_requests, where each request will fit on the ring. *)
  let stream_of sector num_sectors =
    let from (sector, num_sectors) =
      assert (sector >= 0L);
      assert (num_sectors > 0L);
      (* Round down the starting sector in order to get a page aligned sector *)
      let start_sector = Int64.(mul 8L (div sector 8L)) in
      let start_offset = Int64.(to_int (sub sector start_sector)) in
      (* Round up the ending sector to the page boundary *)
      let end_sector = Int64.(mul 8L (div (add (add sector num_sectors) 7L) 8L)) in
      (* Calculate number of sectors needed *)
      let total_sectors_needed = Int64.(sub end_sector start_sector) in
      (* Maximum of 11 segments per request; 1 page (8 sectors) per segment so: *)
      let total_sectors_possible = min 88L total_sectors_needed in
      let possible_end_sector = Int64.add start_sector total_sectors_possible in
      let end_offset = min 7 (Int64.(to_int (sub 7L (sub possible_end_sector (add sector num_sectors))))) in

      let first = { start_sector; start_offset; end_sector = possible_end_sector; end_offset } in
      if total_sectors_possible < total_sectors_needed
      then
        let num_sectors = Int64.(sub num_sectors (sub total_sectors_possible (of_int start_offset))) in
        first, Some ((Int64.add start_sector total_sectors_possible), num_sectors)
      else
        first, None in
    let state = ref (Some (sector, num_sectors)) in
    Lwt_stream.from
      (fun () ->
        match !state with
        | None -> return None
        | Some x ->
          let item, state' = from x in
          state := state';
          return (Some item)
      )
end

(* Issues a single request to read from [start_sector + start_offset] to [end_sector - end_offset]
   where: [start_sector] and [end_sector] are page-aligned; and the total number of pages will fit
   in a single request. *)
let read_single_request t r =
  let open Single_request in
  let len = npages_of r in
  if len > 11 then
    fail (Failure (sprintf "len > 11 %s" (Single_request.to_string r)))
  else 
    let pages = Io_page.get_n len in
	Gnttab.with_refs len
          (fun rs ->
            Gnttab.with_grants ~domid:t.backend_id ~perm:Gnttab.RW rs pages
	      (fun () ->
		let segs = Array.mapi
		  (fun i rf ->
		    let first_sector = match i with
		      |0 -> r.start_offset
		      |_ -> 0 in
		    let last_sector = match i with
		      |n when n == len-1 -> r.end_offset
		      |_ -> 7 in
		    let gref = Gnttab.to_int32 rf in
		    { Req.gref; first_sector; last_sector }
		  ) (Array.of_list rs) in
		let id = Int64.of_int32 (Gnttab.to_int32 (List.hd rs)) in
		let req = Req.({ op=Some Read; handle=t.vdev; id; sector=r.start_sector; segs }) in
		let res = Ring.Front.push_request_and_wait t.ring (Req.Proto_64.write_request req) in
		if Ring.Front.push_requests_and_check_notify t.ring then
		  Evtchn.notify t.evtchn;
		let open Res in
		    lwt res = res in
		match res.st with
		  | Some Error -> fail (IO_error "read")
		  | Some Not_supported -> fail (IO_error "unsupported")
		  | None -> fail (IO_error "unknown error")
		  | Some OK ->
		    (* Get the pages, and convert them into Istring views *)
		    return (Lwt_stream.of_list (List.rev (snd (List.fold_left
		      (fun (i, acc) page ->
			let start_offset = match i with
			  |0 -> r.start_offset * 512
			  |_ -> 0 in
			let end_offset = match i with
			  |n when n = len-1 -> (r.end_offset + 1) * 512
			  |_ -> 4096 in
			let bytes = end_offset - start_offset in
			let subpage = Io_page.sub page start_offset bytes in
			i + 1, subpage :: acc
		      ) (0, []) pages
		    ))))
	      )
	  )

(* Reads [num_sectors] starting at [sector], returning a stream of Io_page.ts *)
let read_512 t sector num_sectors =
  let requests = Single_request.stream_of sector num_sectors in
  Lwt_stream.(concat (map_s (read_single_request t) requests))

let create ~id : Devices.blkif Lwt.t =
  printf "Xen.Blkif: create %s\n%!" id;
  lwt dev = plug id in
  printf "Xen.Blkif: success\n%!";
  return (object
    method id = id
    method read_512 = read_512 dev
    method write_page = write_page dev
    method sector_size = 4096
    method size = Int64.mul dev.features.sectors dev.features.sector_size
    method readwrite = dev.features.readwrite
    method ppname = sprintf "Xen.blkif:%s" id
    method destroy = unplug id
  end)

(* Register Xen.Blkif provider with the device manager *)
let _ =
  let plug_mvar = Lwt_mvar.create_empty () in
  let unplug_mvar = Lwt_mvar.create_empty () in
  let provider = object(self)
     method id = "Xen.Blkif"
     method plug = plug_mvar 
     method unplug = unplug_mvar
     method create ~deps ~cfg id =
	  (* no cfg required: we will check xenstore instead *)
      lwt blkif = create ~id in
      let entry = Devices.({
        provider=self; 
        id=self#id; 
        depends=[];
        node=Blkif blkif }) in
      return entry
  end in
  Devices.new_provider provider;
  (* Iterate over the plugged in VBDs and plug them in *)
  Main.at_enter (fun () ->
    (* Hack to let console attach before crash :) *)
    Time.sleep 1.0 >>
    lwt ids = enumerate () in
	let vbds = List.map (fun id ->
		{ Devices.p_dep_ids = []; p_cfg = []; p_id = id }
	) ids in
    Lwt_list.iter_s (Lwt_mvar.put plug_mvar) vbds
  )

