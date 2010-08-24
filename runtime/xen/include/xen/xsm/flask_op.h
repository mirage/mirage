/*
 *  This file contains the flask_op hypercall commands and definitions.
 *
 *  Author:  George Coker, <gscoker@alpha.ncsc.mil>
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License version 2,
 *  as published by the Free Software Foundation.
 */

#ifndef __FLASK_OP_H__
#define __FLASK_OP_H__

#define FLASK_LOAD              1
#define FLASK_GETENFORCE        2
#define FLASK_SETENFORCE        3
#define FLASK_CONTEXT_TO_SID    4
#define FLASK_SID_TO_CONTEXT    5
#define FLASK_ACCESS            6
#define FLASK_CREATE            7
#define FLASK_RELABEL           8
#define FLASK_USER              9
#define FLASK_POLICYVERS        10
#define FLASK_GETBOOL           11
#define FLASK_SETBOOL           12
#define FLASK_COMMITBOOLS       13
#define FLASK_MLS               14
#define FLASK_DISABLE           15
#define FLASK_GETAVC_THRESHOLD  16
#define FLASK_SETAVC_THRESHOLD  17
#define FLASK_AVC_HASHSTATS     18
#define FLASK_AVC_CACHESTATS    19
#define FLASK_MEMBER            20
#define FLASK_ADD_OCONTEXT      21
#define FLASK_DEL_OCONTEXT      22

#define FLASK_LAST              FLASK_DEL_OCONTEXT

typedef struct flask_op {
    uint32_t  cmd;
    uint32_t  size;
    char      *buf;
} flask_op_t;

DEFINE_XEN_GUEST_HANDLE(flask_op_t);

#endif
