open Functoria

type time = TIME
let time = Type TIME

let time_conf = object
  inherit [_] base_configurable
  method ty = time
  method name = "time"
  method module_name = "OS.Time"
end

let default_time = impl time_conf
