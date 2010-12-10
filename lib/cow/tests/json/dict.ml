open Cow

type key = string with json

type t = ((* XXX this doesn't work yet : key*) string * float) list with json

let run () = 
	let t = [ "foo", 3. ; "bar", 4. ] in

  Printf.printf "\n==Testing dictionary encoding==\n";

	let json = json_of_t t in
	Printf.printf "\n * json:\n";
	Printf.printf "   - r = %s\n%!" (Json.to_string json);

	Printf.printf "\n * sanity check:\n";

	let t' = t_of_json json in
	Printf.printf "    - t = t' : %b\n%!" (t = t');
	assert (t = t')
