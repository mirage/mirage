/*
 * ====================================================
 * Copyright (C) 2007 by Ellips BV. All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this
 * software is freely granted, provided that this notice
 * is preserved.
 * ====================================================
 */

  #include "x86_64mach.h"

  .global SYM (memset)
  SOTYPE_FUNCTION(memset)

SYM (memset):
  movq    rdi, r9                 /* Save return value */
  movq    rsi, rax
  movq    rdx, rcx
  cmpq    $16, rdx
  jb      byte_set

  movq    rdi, r8                 /* Align on quad word boundary */
  andq    $7, r8
  jz      quadword_aligned
  movq    $8, rcx
  subq    r8, rcx
  subq    rcx, rdx
  rep     stosb
  movq    rdx, rcx

quadword_aligned:
  movabs  $0x0101010101010101, r8
  movzbl  sil, eax
  imul    r8, rax
  cmpq    $256, rdx
  jb      quadword_set

  shrq    $7, rcx                 /* Store 128 bytes at a time with minimum cache polution */

  .p2align 4
loop:
  movnti rax,     (rdi)
  movnti rax,   8 (rdi)
  movnti rax,  16 (rdi)
  movnti rax,  24 (rdi)
  movnti rax,  32 (rdi)
  movnti rax,  40 (rdi)
  movnti rax,  48 (rdi)
  movnti rax,  56 (rdi)
  movnti rax,  64 (rdi)
  movnti rax,  72 (rdi)
  movnti rax,  80 (rdi)
  movnti rax,  88 (rdi)
  movnti rax,  96 (rdi)
  movnti rax, 104 (rdi)
  movnti rax, 112 (rdi)
  movnti rax, 120 (rdi)

  leaq    128 (rdi), rdi

  dec     rcx
  jnz     loop

  sfence
  movq    rdx, rcx
  andq    $127, rcx
  rep     stosb
  movq    r9, rax
  ret


byte_set:
  rep     stosb
  movq    r9, rax
  ret


quadword_set:
  shrq    $3, rcx
  .p2align 4
  rep     stosq
  movq    rdx, rcx
  andq    $7, rcx
  rep     stosb                   /* Store the remaining bytes */
  movq    r9, rax
  ret

