type t = [ `foo | `bar of int * string ] with json

let run () =
	let t1 = `foo in
	let t2 = `bar (3, "bar") in

  Printf.printf "Testing variant encoding\n";

	let j1 = json_of_t t1 in
	let j2 = json_of_t t2 in

	Printf.printf "r1 = %s\nr2 = %s\n%!" (Json.to_string r1) (Json.to_string r2);

	let t1' = t_of_json j1 in
	let t2' = t_of_json j2 in

	Printf.printf "t1 = t1' : %b\nt2 = t2' : %b\n%!" (t1 = t1') (t2 = t2');
	assert (t1 = t1' && t2 = t2')
