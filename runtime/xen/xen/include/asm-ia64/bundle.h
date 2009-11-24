#ifndef _XEN_IA64_BUNDLE_H
#define _XEN_IA64_BUNDLE_H

typedef unsigned long IA64_INST;

typedef union U_IA64_BUNDLE {
    unsigned long i64[2];
    struct { unsigned long template:5,slot0:41,slot1a:18,slot1b:23,slot2:41; };
    // NOTE: following doesn't work because bitfields can't cross natural
    // size boundaries
    //struct { unsigned long template:5, slot0:41, slot1:41, slot2:41; };
} IA64_BUNDLE;

typedef enum E_IA64_SLOT_TYPE { I, M, F, B, L, ILLEGAL } IA64_SLOT_TYPE;

typedef union U_INST64_A5 {
    IA64_INST inst;
    struct { unsigned long qp:6, r1:7, imm7b:7, r3:2, imm5c:5, imm9d:9, s:1, major:4; };
} INST64_A5;

typedef union U_INST64_B4 {
    IA64_INST inst;
    struct { unsigned long qp:6, btype:3, un3:3, p:1, b2:3, un11:11, x6:6, wh:2, d:1, un1:1, major:4; };
} INST64_B4;

typedef union U_INST64_B8 {
    IA64_INST inst;
    struct { unsigned long qp:6, un21:21, x6:6, un4:4, major:4; };
} INST64_B8;

typedef union U_INST64_B9 {
    IA64_INST inst;
    struct { unsigned long qp:6, imm20:20, :1, x6:6, :3, i:1, major:4; };
} INST64_B9;

typedef union U_INST64_I18 {
    IA64_INST inst;
    struct { unsigned long qp:6, imm20:20, y:1, x6:6, x3:3, i:1, major:4; };
} INST64_I18;

typedef union U_INST64_I19 {
    IA64_INST inst;
    struct { unsigned long qp:6, imm20:20, :1, x6:6, x3:3, i:1, major:4; };
} INST64_I19;

typedef union U_INST64_I26 {
    IA64_INST inst;
    struct { unsigned long qp:6, :7, r2:7, ar3:7, x6:6, x3:3, :1, major:4;};
} INST64_I26;

typedef union U_INST64_I27 {
    IA64_INST inst;
    struct { unsigned long qp:6, :7, imm:7, ar3:7, x6:6, x3:3, s:1, major:4;};
} INST64_I27;

typedef union U_INST64_I28 { // not privileged (mov from AR)
    IA64_INST inst;
    struct { unsigned long qp:6, r1:7, :7, ar3:7, x6:6, x3:3, :1, major:4;};
} INST64_I28;

typedef union U_INST64_M28 {
    IA64_INST inst;
    struct { unsigned long qp:6, :14, r3:7, x6:6, x3:3, x:1, major:4;};
} INST64_M28;

typedef union U_INST64_M29 {
    IA64_INST inst;
    struct { unsigned long qp:6, :7, r2:7, ar3:7, x6:6, x3:3, :1, major:4;};
} INST64_M29;

typedef union U_INST64_M30 {
    IA64_INST inst;
    struct { unsigned long qp:6, :7, imm:7, ar3:7,x4:4,x2:2,x3:3,s:1,major:4;};
} INST64_M30;

typedef union U_INST64_M31 {
    IA64_INST inst;
    struct { unsigned long qp:6, r1:7, :7, ar3:7, x6:6, x3:3, :1, major:4;};
} INST64_M31;

typedef union U_INST64_M32 {
    IA64_INST inst;
    struct { unsigned long qp:6, :7, r2:7, cr3:7, x6:6, x3:3, :1, major:4;};
} INST64_M32;

typedef union U_INST64_M33 {
    IA64_INST inst;
    struct { unsigned long qp:6, r1:7, :7, cr3:7, x6:6, x3:3, :1, major:4; };
} INST64_M33;

typedef union U_INST64_M35 {
    IA64_INST inst;
    struct { unsigned long qp:6, :7, r2:7, :7, x6:6, x3:3, :1, major:4; };
   
} INST64_M35;

typedef union U_INST64_M36 {
    IA64_INST inst;
    struct { unsigned long qp:6, r1:7, :14, x6:6, x3:3, :1, major:4; }; 
} INST64_M36;

typedef union U_INST64_M37 {
    IA64_INST inst;
    struct { unsigned long qp:6, imm20a:20,:1, x4:4,x2:2,x3:3, i:1, major:4; };
} INST64_M37;

typedef union U_INST64_M41 {
    IA64_INST inst;
    struct { unsigned long qp:6, :7, r2:7, :7, x6:6, x3:3, :1, major:4; }; 
} INST64_M41;

typedef union U_INST64_M42 {
    IA64_INST inst;
    struct { unsigned long qp:6, :7, r2:7, r3:7, x6:6, x3:3, :1, major:4; };
} INST64_M42;

typedef union U_INST64_M43 {
    IA64_INST inst;
    struct { unsigned long qp:6, r1:7, :7, r3:7, x6:6, x3:3, :1, major:4; };
} INST64_M43;

typedef union U_INST64_M44 {
    IA64_INST inst;
    struct { unsigned long qp:6, imm:21, x4:4, i2:2, x3:3, i:1, major:4; };
} INST64_M44;

typedef union U_INST64_M45 {
    IA64_INST inst;
    struct { unsigned long qp:6, :7, r2:7, r3:7, x6:6, x3:3, :1, major:4; };
} INST64_M45;

typedef union U_INST64_M46 {
    IA64_INST inst;
    struct { unsigned long qp:6, r1:7, un7:7, r3:7, x6:6, x3:3, un1:1, major:4; };
} INST64_M46;

typedef union U_INST64_M47 {
    IA64_INST inst;
    struct { unsigned long qp:6, un14:14, r3:7, x6:6, x3:3, un1:1, major:4; };
} INST64_M47;

typedef union U_INST64_M1{
    IA64_INST inst;
    struct { unsigned long qp:6, r1:7, un7:7, r3:7, x:1, hint:2, x6:6, m:1, major:4; };
} INST64_M1;

typedef union U_INST64_M2{
    IA64_INST inst;
    struct { unsigned long qp:6, r1:7, r2:7, r3:7, x:1, hint:2, x6:6, m:1, major:4; };
} INST64_M2;

typedef union U_INST64_M3{
    IA64_INST inst;
    struct { unsigned long qp:6, r1:7, imm7:7, r3:7, i:1, hint:2, x6:6, s:1, major:4; };
} INST64_M3;

typedef union U_INST64_M4 {
    IA64_INST inst;
    struct { unsigned long qp:6, un7:7, r2:7, r3:7, x:1, hint:2, x6:6, m:1, major:4; };
} INST64_M4;

typedef union U_INST64_M5 {
    IA64_INST inst;
    struct { unsigned long qp:6, imm7:7, r2:7, r3:7, i:1, hint:2, x6:6, s:1, major:4; };
} INST64_M5;

typedef union U_INST64_M6 {
    IA64_INST inst;
    struct { unsigned long qp:6, f1:7, un7:7, r3:7, x:1, hint:2, x6:6, m:1, major:4; };
} INST64_M6;

typedef union U_INST64_M9 {
    IA64_INST inst;
    struct { unsigned long qp:6, :7, f2:7, r3:7, x:1, hint:2, x6:6, m:1, major:4; };
} INST64_M9;

typedef union U_INST64_M10 {
    IA64_INST inst;
    struct { unsigned long qp:6, imm7:7, f2:7, r3:7, i:1, hint:2, x6:6, s:1, major:4; };
} INST64_M10;

typedef union U_INST64_M12 {
    IA64_INST inst;
    struct { unsigned long qp:6, f1:7, f2:7, r3:7, x:1, hint:2, x6:6, m:1, major:4; };
} INST64_M12;
			 
typedef union U_INST64_M15 {
    IA64_INST inst;
    struct { unsigned long qp:6, :7, imm7:7, r3:7, i:1, hint:2, x6:6, s:1, major:4; };
} INST64_M15;

typedef union U_INST64 {
    IA64_INST inst;
    struct { unsigned long :37, major:4; } generic;
    INST64_A5 A5;	// used in build_hypercall_bundle only
    INST64_B4 B4;	// used in build_hypercall_bundle only
    INST64_B8 B8;	// rfi, bsw.[01]
    INST64_B9 B9;	// break.b
    INST64_I18 I18;	// nop.i used in build_fpswa_hypercall_bundle only
    INST64_I19 I19;	// used in build_hypercall_bundle only
    INST64_I26 I26;	// mov register to ar (I unit)
    INST64_I27 I27;	// mov immediate to ar (I unit)
    INST64_I28 I28;	// mov from ar (I unit)
    INST64_M1  M1;	// ld integer
    INST64_M2  M2;
    INST64_M3  M3;
    INST64_M4  M4;	// st integer
    INST64_M5  M5;
    INST64_M6  M6;	// ldfd floating pointer
    INST64_M9  M9;	// stfd floating pointer
    INST64_M10 M10;	// stfd floating pointer
    INST64_M12 M12;    // ldfd pair floating pointer
    INST64_M15 M15;	// lfetch + imm update
    INST64_M28 M28;	// purge translation cache entry
    INST64_M29 M29;	// mov register to ar (M unit)
    INST64_M30 M30;	// mov immediate to ar (M unit)
    INST64_M31 M31;	// mov from ar (M unit)
    INST64_M32 M32;	// mov reg to cr
    INST64_M33 M33;	// mov from cr
    INST64_M35 M35;	// mov to psr
    INST64_M36 M36;	// mov from psr
    INST64_M37 M37;	// break.m
    INST64_M41 M41;	// translation cache insert
    INST64_M42 M42;	// mov to indirect reg/translation reg insert
    INST64_M43 M43;	// mov from indirect reg
    INST64_M44 M44;	// set/reset system mask
    INST64_M45 M45;	// translation purge
    INST64_M46 M46;	// translation access (tpa,tak)
    INST64_M47 M47;	// purge translation entry
} INST64;

#ifdef __XEN__
extern unsigned long __vmx_get_domain_bundle(unsigned long iip, IA64_BUNDLE *pbundle);
extern IA64_BUNDLE __get_domain_bundle(unsigned long iip);
#endif

#define MASK_41 ((unsigned long)0x1ffffffffff)

#endif /* _XEN_IA64_BUNDLE_H */
