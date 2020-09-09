open Functoria
open Mirage_impl_misc

module Key = Mirage_key

type pci = PCI

let pci = Type.v PCI

type device_info =
  { bus_master_enable : bool
  ; map_bar0 : bool
  ; map_bar1 : bool
  ; map_bar2 : bool
  ; map_bar3 : bool
  ; map_bar4 : bool
  ; map_bar5 : bool
  ; vendor_id : int
  ; device_id : int
  ; class_code : int
  ; subclass_code : int
  ; progif : int
  ; dma_size : int
  }

let all_pci_devices = ref []

let dma_request = ref 0

let pci_conf device_info (dev : string Key.key) =
  let key = Key.v dev in
  let keys = [ key ] in
  let packages_v =
    Key.match_ Key.(value target) @@ function
    | `Unix -> [ package "mirage-pci-unix" ]
    | #Mirage_key.mode_solo5 -> [ package "mirage-pci-solo5" ]
    | target ->
      Log.err (fun m -> m "target not supported: %a" Key.pp_target target);
      failwith "target not supported" in
  let connect i modname _ =
    match Mirage_key.(get (Functoria.Info.context i) target) with
    | `Unix ->
      Fmt.strf
        "%s.connect Pci.{ bus_master_enable = %b; map_bar0 = %b; map_bar1 = %b; map_bar2 = %b; map_bar3 = %b; map_bar4 = %b; map_bar5 = %b; vendor_id = %d; device_id = %d; class_code = %d; subclass_code = %d; progif = %d; dma_size = %d } %a"
        modname
        device_info.bus_master_enable
        device_info.map_bar0
        device_info.map_bar1
        device_info.map_bar2
        device_info.map_bar3
        device_info.map_bar4
        device_info.map_bar5
        device_info.vendor_id
        device_info.device_id
        device_info.class_code
        device_info.subclass_code
        device_info.progif
        device_info.dma_size
        Key.serialize_call key
    | `Hvt ->
      let dma_offset = !dma_request in
      dma_request := !dma_request + device_info.dma_size;
      Fmt.strf
        "%s.connect ~dma_offset:%d ~dma_size:%d %a"
        modname
        dma_offset (* TODO take alignment into account, request might be weirdly sized *)
        device_info.dma_size
        Key.serialize_call key
    | target ->
      Log.err (fun m -> m "target not supported: %a" Key.pp_target target);
      failwith "target not supported" in
  let configure i =
    all_pci_devices := (device_info, Key.get (Info.context i) dev) :: !all_pci_devices;
    Action.ok () in
  impl ~keys ~packages_v ~connect ~configure "Pci" pci

let pcidev ?group device_info dev =
  pci_conf device_info @@ Key.pci ?group dev
