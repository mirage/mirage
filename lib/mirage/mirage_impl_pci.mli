type pci

val pci : pci Functoria.typ

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

val pcidev : ?group:string -> device_info -> string -> pci Functoria.impl

val dma_request : int ref

val all_pci_devices : (device_info * string) list ref
