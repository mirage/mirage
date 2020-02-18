type t = { bin : (Fpath.t * Fpath.t) list; etc : Fpath.t list }

let v ?(bin = []) ?(etc = []) () = { bin; etc }

let empty = v ()

let dump ppf t =
  let bin ppf t = Fmt.Dump.(list (pair Fpath.pp Fpath.pp)) ppf t.bin in
  let etc ppf t = Fmt.Dump.(list Fpath.pp) ppf t.etc in
  Fmt.Dump.record [ bin; etc ] ppf t

let pp ppf t =
  let pp_bin ppf (src, dst) =
    Fmt.pf ppf "\n  \"%a\" {\"%a\"}" Fpath.pp src Fpath.pp dst
  in
  let pp_etc ppf file =
    Fmt.pf ppf "\n  \"%a\" {\"%s\"}" Fpath.pp file Fpath.(basename file)
  in
  let bins = List.map (Fmt.to_to_string pp_bin) t.bin in
  let etcs = List.map (Fmt.to_to_string pp_etc) t.etc in
  Fmt.pf ppf "bin: [%s%s]\n" (String.concat "" bins)
    (match bins with [] -> "" | _ -> "\n");
  Fmt.pf ppf "etc: [%s%s]\n" (String.concat "" etcs)
    (match etcs with [] -> "" | _ -> "\n")

let union_etc x y = Fpath.Set.(elements (union (of_list x) (of_list y)))

let union_bin x y = x @ y

let union x y = { bin = union_bin x.bin y.bin; etc = union_etc x.etc y.etc }
