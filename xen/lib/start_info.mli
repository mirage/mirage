(** Get the start info page. *)

type t = {
	magic: string; (** "xen-<version>-<platform>". *)
	nr_pages: int; (** Total pages allocated to this domain. *)
	shared_info: int; (** MACHINE address of shared info struct. *)
	flags: int; (** SIF_xxx flags. *)
	store_mfn: int; (** MACHINE page number of the shared page used for communication with the XenStore. *)
	store_evtchn: int; (** Event channel for communication with the XenStore. *)
	console_mfn: int; (** MACHINE page number of console page. *)
	console_evtchn: int; (** Event channel for console page. *)

  (** THE FOLLOWING ARE ONLY FILLED IN ON INITIAL BOOT (NOT RESUME). *)
	pt_base: int; (** VIRTUAL address of page directory. *)
	nr_pt_frames: int; (** Number of bootstrap p.t. frames. *)
	mfn_list: int; (** VIRTUAL address of page-frame list. *)
	mod_start: int; (** VIRTUAL address of pre-loaded module. *)
	mod_len: int; (** Size (bytes) of pre-loaded module. *)
	cmd_line: string; (** Command-line arguments passed to the unikernel. *)
	first_p2m_pfn: int; (** 1st pfn forming initial P->M table. *)
	nr_p2m_frames: int (** # of pfns forming initial P->M table. *)
}

val get: unit -> t
(** [get ()] is the record containing the start info page. *)
