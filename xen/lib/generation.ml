exception Invalid

type 'a t = {
	generation : int;
	value : 'a
}

let generation = ref 0

let wrap x = { generation = !generation; value = x }
let maybe t f d = if t.generation <> !generation then d else (f t.value)
let extract t = t.value
let resume () = incr generation


