type state =
    Unknown
  | Initialising
  | InitWait
  | Initialised
  | Connected
  | Closing
  | Closed
  | Reconfiguring
  | Reconfigured
val of_string : string -> state
val to_string : state -> string
val prettyprint : state -> string
