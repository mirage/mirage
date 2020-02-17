type t = { bin : (Fpath.t * Fpath.t) list; etc : Fpath.t list }

let v ?(bin = []) ?(etc = []) () = { bin; etc }

let empty = v ()

let pp_cp_to_bin ppf bins =
  let pp ppf (src, dst) =
    Fmt.pf ppf {|[ "cp" "%a" "%%{bin}%%/%a" ]@.|} Fpath.pp src Fpath.pp dst
  in
  Fmt.list ~sep:(Fmt.unit "@ ") pp ppf bins

let pp_cp_to_etc ppf etcs =
  let pp ppf src = Fmt.pf ppf {|[ "cp" "%a" "%%{etc}%%" ]@.|} Fpath.pp src in
  Fmt.list ~sep:(Fmt.unit "@ ") pp ppf etcs

let pp ppf i = Fmt.pf ppf "%a%a" pp_cp_to_bin i.bin pp_cp_to_etc i.etc

let union_etc x y = Fpath.Set.(elements (union (of_list x) (of_list y)))

let union_bin x y = x @ y

let union x y = { bin = union_bin x.bin y.bin; etc = union_etc x.etc y.etc }
