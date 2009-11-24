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

  .global SYM (memcpy)
  SOTYPE_FUNCTION(memcpy)

SYM (memcpy):
  movq    rdi, rax                /* Store destination in return value */
  cmpq    $16, rdx
  jb      byte_copy

  movq    rdi, r8                 /* Align destination on quad word boundary */
  andq    $7, r8
  jz      quadword_aligned
  movq    $8, rcx
  subq    r8, rcx
  subq    rcx, rdx
  rep     movsb

quadword_aligned:
  cmpq    $256, rdx
  jb      quadword_copy

#if 1
  subq    $32, rsp
  movq    rax, 24 (rsp)
  movq    r12, 16 (rsp)
  movq    r13, 8  (rsp)
  movq    r14, 0  (rsp)
#else
  movq    rax, -8  (rsp)
  movq    r12, -16 (rsp)
  movq    r13, -24 (rsp)
  movq    r14, -32 (rsp)
#endif

  movq    rdx, rcx                /* Copy 128 bytes at a time with minimum cache polution */
  shrq    $7, rcx

  .p2align 4
loop:
  prefetchnta   768 (rsi)
  prefetchnta   832 (rsi)

  movq       (rsi), rax
  movq     8 (rsi), r8
  movq    16 (rsi), r9
  movq    24 (rsi), r10
  movq    32 (rsi), r11
  movq    40 (rsi), r12
  movq    48 (rsi), r13
  movq    56 (rsi), r14

  movnti rax,    (rdi)
  movnti r8 ,  8 (rdi)
  movnti r9 , 16 (rdi)
  movnti r10, 24 (rdi)
  movnti r11, 32 (rdi)
  movnti r12, 40 (rdi)
  movnti r13, 48 (rdi)
  movnti r14, 56 (rdi)

  movq     64 (rsi), rax
  movq     72 (rsi), r8
  movq     80 (rsi), r9
  movq     88 (rsi), r10
  movq     96 (rsi), r11
  movq    104 (rsi), r12
  movq    112 (rsi), r13
  movq    120 (rsi), r14

  movnti rax,  64 (rdi)
  movnti r8 ,  72 (rdi)
  movnti r9 ,  80 (rdi)
  movnti r10,  88 (rdi)
  movnti r11,  96 (rdi)
  movnti r12, 104 (rdi)
  movnti r13, 112 (rdi)
  movnti r14, 120 (rdi)

  leaq    128 (rsi), rsi
  leaq    128 (rdi), rdi

  dec     rcx
  jnz     loop

  sfence
  movq    rdx, rcx
  andq    $127, rcx
  rep     movsb
#if 1
  movq    24 (rsp), rax
  movq    16 (rsp), r12
  movq    8  (rsp), r13
  movq    0  (rsp), r14
  addq    $32, rsp
#else
  movq    -8  (rsp), rax
  movq    -16 (rsp), r12
  movq    -24 (rsp), r13
  movq    -32 (rsp), r14
#endif
  ret


byte_copy:
  movq    rdx, rcx
  rep     movsb
  ret


quadword_copy:
  movq    rdx, rcx
  shrq    $3, rcx
  .p2align 4
  rep     movsq
  movq    rdx, rcx
  andq    $7, rcx
  rep     movsb                   /* Copy the remaining bytes */
  ret
