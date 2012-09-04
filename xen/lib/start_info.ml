type t = {
	magic: string;
	nr_pages: int;
	shared_info: int;
	flags: int;
	store_mfn: int;
	store_evtchn: int;
	console_mfn: int;
	console_evtchn: int;
	pt_base: int;
	nr_pt_frames: int;
	mfn_list: int;
	mod_start: int;
	mod_len: int;
	cmd_line: string;
	first_p2m_pfn: int;
	nr_p2m_frames: int
}

external get: unit -> t = "stub_start_info_get"

