open Cow

type t = {
	foo : int option;
	bar : int list option;
	gni : int list;
	gna : int * (int option)
} with json

let run () =
	let t1 = { foo = None; bar = None; gni = []; gna = 1, None } in
	let t2 = { foo = None; bar = Some []; gni = [1]; gna = 1, None } in

	let r1 = json_of_t t1 in
	let r2 = json_of_t t2 in

  Printf.printf "\n==Testing option types==\n";

	Printf.printf "\n * json:\n";
  Printf.printf "   - r1 = %s\n" (Json.to_string r1);
  Printf.printf "   - r2 = %s\n" (Json.to_string r2);

	let t1' = t_of_json r1 in
	let t2' = t_of_json r2 in

	Printf.printf "\n * sanity check:\n";

	Printf.printf "   - t1 = t1' : %b\n%!" (t1=t1');
	assert (t1 = t1');

	Printf.printf "   - t2 = t2' : %b\n%!" (t2 = t2');
	assert (t2 = t2')
