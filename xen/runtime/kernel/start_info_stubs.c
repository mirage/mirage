/*
 * Copyright (c) 2012 Citrix Systems Inc
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */

#include <stdio.h>
#include <stdint.h>
#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <caml/fail.h>
#include <caml/bigarray.h>

#include <xen/xen.h>
#include <mini-os/x86/os.h>

CAMLprim value
stub_start_info_get(value unit)
{
  CAMLparam1(unit);
  CAMLlocal2(result, tmp);
  char buf[MAX_GUEST_CMDLINE+1];

  result = caml_alloc_tuple(16);
  memcpy(buf, start_info.magic, sizeof(start_info.magic));
  buf[sizeof(start_info.magic)] = 0;
  tmp = caml_copy_string(buf);
  Store_field(result, 0, tmp);
  Store_field(result, 1, Val_int(start_info.nr_pages));
  Store_field(result, 2, Val_int(start_info.shared_info));
  Store_field(result, 3, Val_int(start_info.flags));
  Store_field(result, 4, Val_int(start_info.store_mfn));
  Store_field(result, 5, Val_int(start_info.store_evtchn));
  Store_field(result, 6, Val_int(start_info.console.domU.mfn));
  Store_field(result, 7, Val_int(start_info.console.domU.evtchn));
  Store_field(result, 8, Val_int(start_info.pt_base));
  Store_field(result, 9, Val_int(start_info.nr_pt_frames));
  Store_field(result, 10, Val_int(start_info.mfn_list));
  Store_field(result, 11, Val_int(start_info.mod_start));
  Store_field(result, 12, Val_int(start_info.mod_len));
  memcpy(buf, start_info.cmd_line, MAX_GUEST_CMDLINE);
  buf[MAX_GUEST_CMDLINE] = 0;
  tmp = caml_copy_string(buf);
  Store_field(result, 13, tmp);
  Store_field(result, 14, Val_int(start_info.first_p2m_pfn));
  Store_field(result, 15, Val_int(start_info.nr_p2m_frames));

  CAMLreturn(result);
}

CAMLprim value
caml_console_start_page(value v_unit)
{
  CAMLparam1(v_unit);
  CAMLlocal1(v_ret);
  intnat dims[] = { Long_val(PAGE_SIZE) };
  unsigned char *page = mfn_to_virt(start_info.console.domU.mfn);
  v_ret = caml_ba_alloc(CAML_BA_UINT8 | CAML_BA_C_LAYOUT, 1, page, dims);
  CAMLreturn(v_ret);
}

CAMLprim value
caml_xenstore_start_page(value v_unit)
{
  CAMLparam1(v_unit);
  CAMLlocal1(v_ret);
  intnat dims[] = { Long_val(PAGE_SIZE) };
  unsigned char *page = mfn_to_virt(start_info.store_mfn);
  v_ret = caml_ba_alloc(CAML_BA_UINT8 | CAML_BA_C_LAYOUT, 1, page, dims);
  CAMLreturn(v_ret);
}
