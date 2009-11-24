
#define A0 r0
#define A0L r0l
#define A0H r0h

#define A1 r1
#define A1L r1l
#define A1H r1h

#define A2 r2
#define A2L r2l
#define A2H r2h

#define A3 r3
#define A3L r3l
#define A3H r3h

#define S0 r4
#define S0L r4l
#define S0H r4h

#define S1 r5
#define S1L r5l
#define S1H r5h

#define S2 r6
#define S2L r6l
#define S2H r6h

#ifdef __H8300__

#define MOVP	mov.w	/* pointers are 16 bits */
#define ADDP	add.w
#define CMPP	cmp.w
#define PUSHP	push
#define POPP	pop

#define A0P	r0
#define A1P	r1
#define A2P	r2
#define A3P	r3
#define S0P	r4
#define S1P	r5
#define S2P	r6

#endif /* __H8300__ */

#ifdef __H8300H__

#ifdef __NORMAL_MODE__

#define MOVP	mov.w	/* pointers are 16 bits */
#define ADDP	add.w
#define CMPP	cmp.w
#define PUSHP	push
#define POPP	pop

#define A0P	r0
#define A1P	r1
#define A2P	r2
#define A3P	r3
#define S0P	r4
#define S1P	r5
#define S2P	r6

#else /* !__NORMAL_MODE__ */

#define MOVP	mov.l	/* pointers are 32 bits */
#define ADDP	add.l
#define CMPP	cmp.l
#define PUSHP	push.l
#define POPP	pop.l

#define A0P	er0
#define A1P	er1
#define A2P	er2
#define A3P	er3
#define S0P	er4
#define S1P	er5
#define S2P	er6

#endif /* !__NORMAL_MODE__ */

#define A0E	e0
#define A1E	e1
#define A2E	e2
#define A3E	e3

#endif /* __H8300H__ */

#if defined (__H8300S__) || defined (__H8300SX__)

#ifdef __NORMAL_MODE__

#define MOVP	mov.w	/* pointers are 16 bits */
#define ADDP	add.w
#define CMPP	cmp.w
#define PUSHP	push
#define POPP	pop

#define A0P	r0
#define A1P	r1
#define A2P	r2
#define A3P	r3
#define S0P	r4
#define S1P	r5
#define S2P	r6

#else /* !__NORMAL_MODE__ */

#define MOVP	mov.l	/* pointers are 32 bits */
#define ADDP	add.l
#define CMPP	cmp.l
#define PUSHP	push.l
#define POPP	pop.l

#define A0P	er0
#define A1P	er1
#define A2P	er2
#define A3P	er3
#define S0P	er4
#define S1P	er5
#define S2P	er6

#endif /* !__NORMAL_MODE__ */

#define A0E	e0
#define A1E	e1
#define A2E	e2
#define A3E	e3


#ifdef __NORMAL_MODE__
#define LEN(X) X
#else
#define LEN(X) e##X
#endif
#endif /* __H8300S__ */
