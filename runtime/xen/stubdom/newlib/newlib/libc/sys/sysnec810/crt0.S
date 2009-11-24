        .set    STACKTOP, 0x100000

        .extern __tp_TEXT, 4
        .extern __gp_DATA, 4
        .extern _main
        .globl  __start
        .globl  _exit
        .globl  __exit

        .text
__start:
        mov     2, r10                  -- set Cache Control Word
        ldsr    r10, 24                 --
#
        mov     STACKTOP, sp            -- set stack pointer
        mov     #__tp_TEXT, tp          -- set tp register
        mov     #__gp_DATA, gp          -- set gp register offset
        add     tp, gp                  -- set gp register
        jal     _main                   -- call main function
__exit:
	halt				-- end of the program

