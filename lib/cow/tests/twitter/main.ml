open Cow.Twitter
open Lwt

let pretty_print t =
  OS.Console.log (Printf.sprintf "<%s> says: %s" t.Status.user.User.screen_name t.Status.text)

let run screen_name =
  OS.Console.log "[Connecting to twitter]";
  lwt tweets = Status.user_timeline ~screen_name () in
  OS.Console.log "[Tweets succesfully received]";
  List.iter pretty_print tweets;
  return (OS.Console.log (Printf.sprintf "[Done]"))

let _ =
  OS.Main.run (run "eriangazag")
  
