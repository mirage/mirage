open Functoria
module Key = Mirage_key

type io_page = IO_PAGE
let io_page = Type IO_PAGE

let io_page_conf = object
  inherit base_configurable
  method ty = io_page
  method name = "io_page"
  method module_name = "Io_page"
  method! packages =
    Key.(if_ is_unix)
      [ package ~sublibs:["unix"] "io-page" ]
      [ package "io-page" ]
end

let default_io_page = impl io_page_conf
