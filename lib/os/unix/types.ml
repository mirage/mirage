type blkif = <
  read_page: int64 -> Bitstring.t Lwt.t;
  sector_size: int;
  ppname: string;
  destroy: unit;
>
