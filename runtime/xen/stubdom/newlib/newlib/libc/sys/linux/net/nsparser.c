#ifndef lint
static char yysccsid[] = "@(#)yaccpar	1.9 (Berkeley) 02/21/93";
#endif
#define YYBYACC 1
#define YYMAJOR 1
#define YYMINOR 9
#define yyclearin (yychar=(-1))
#define yyerrok (yyerrflag=0)
#define YYRECOVERING (yyerrflag!=0)
#define yyparse _nsyyparse
#define yylex _nsyylex
#define yyerror _nsyyerror
#define yychar _nsyychar
#define yyval _nsyyval
#define yylval _nsyylval
#define yydebug _nsyydebug
#define yynerrs _nsyynerrs
#define yyerrflag _nsyyerrflag
#define yyss _nsyyss
#define yyssp _nsyyssp
#define yyvs _nsyyvs
#define yyvsp _nsyyvsp
#define yylhs _nsyylhs
#define yylen _nsyylen
#define yydefred _nsyydefred
#define yydgoto _nsyydgoto
#define yysindex _nsyysindex
#define yyrindex _nsyyrindex
#define yygindex _nsyygindex
#define yytable _nsyytable
#define yycheck _nsyycheck
#define yyname _nsyyname
#define yyrule _nsyyrule
#define YYPREFIX "_nsyy"
#line 2 "nsparser.y"
/*	$NetBSD: nsparser.y,v 1.3 1999/01/25 00:16:18 lukem Exp $	*/

/*-
 * Copyright (c) 1997, 1998, 1999 The NetBSD Foundation, Inc.
 * All rights reserved.
 *
 * This code is derived from software contributed to The NetBSD Foundation
 * by Luke Mewburn.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. All advertising materials mentioning features or use of this software
 *    must display the following acknowledgement:
 *        This product includes software developed by the NetBSD
 *        Foundation, Inc. and its contributors.
 * 4. Neither the name of The NetBSD Foundation nor the names of its
 *    contributors may be used to endorse or promote products derived
 *    from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE NETBSD FOUNDATION, INC. AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
 * TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE FOUNDATION OR CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

#include <sys/cdefs.h>
#if defined(LIBC_SCCS) && !defined(lint)
static char *rcsid =
  "$FreeBSD: src/lib/libc/net/nsparser.y,v 1.3 2002/03/21 22:47:17 obrien Exp $";
#endif /* LIBC_SCCS and not lint */

#define _NS_PRIVATE
#include <nsswitch.h>
#include <stdio.h>
#include <string.h>


static	void	_nsaddsrctomap(const char *);

static	ns_dbt		curdbt;
static	ns_src		cursrc;
#line 59 "nsparser.y"
typedef union {
	char *str;
	int   mapval;
} YYSTYPE;
#line 97 "y.tab.c"
#define NL 257
#define SUCCESS 258
#define UNAVAIL 259
#define NOTFOUND 260
#define TRYAGAIN 261
#define RETURN 262
#define CONTINUE 263
#define STRING 264
#define YYERRCODE 256
short _nsyylhs[] = {                                        -1,
    0,    0,    3,    3,    4,    4,    4,    4,    5,    6,
    6,    7,    9,    7,    8,    8,   10,    1,    1,    1,
    1,    2,    2,
};
short _nsyylen[] = {                                         2,
    0,    1,    1,    2,    1,    3,    4,    2,    1,    1,
    2,    1,    0,    5,    1,    2,    3,    1,    1,    1,
    1,    1,    1,
};
short _nsyydefred[] = {                                      0,
    0,    5,    9,    0,    0,    3,    0,    8,    4,    0,
    6,    0,    0,   10,   13,    7,   11,    0,   18,   19,
   20,   21,    0,    0,   15,    0,   14,   16,   22,   23,
   17,
};
short _nsyydgoto[] = {                                       4,
   23,   31,    5,    6,    7,   13,   14,   24,   18,   25,
};
short _nsyysindex[] = {                                   -255,
 -249,    0,    0,    0, -255,    0,  -41,    0,    0, -254,
    0,  -73, -253,    0,    0,    0,    0, -245,    0,    0,
    0,    0,  -42,  -93,    0, -256,    0,    0,    0,    0,
    0,
};
short _nsyyrindex[] = {                                     20,
    0,    0,    0,    0,   21,    0,    0,    0,    0,    0,
    0, -252,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,
};
short _nsyygindex[] = {                                      0,
    0,    0,    0,   17,    0,    0,   10,    0,    0,    1,
};
#define YYTABLESIZE 168
short _nsyytable[] = {                                      27,
    1,    2,   11,   16,   12,   29,   30,    8,    3,   12,
   12,   12,   19,   20,   21,   22,   10,   15,   26,    1,
    2,    9,   17,    0,   28,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,   19,   20,   21,   22,
};
short _nsyycheck[] = {                                      93,
  256,  257,  257,  257,  257,  262,  263,  257,  264,  264,
  264,  264,  258,  259,  260,  261,   58,   91,   61,    0,
    0,    5,   13,   -1,   24,   -1,   -1,   -1,   -1,   -1,
   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,
   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,
   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,
   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,
   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,
   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,
   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,
   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,
   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,
   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,
   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,
   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,
   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,
   -1,   -1,   -1,   -1,  258,  259,  260,  261,
};
#define YYFINAL 4
#ifndef YYDEBUG
#define YYDEBUG 0
#endif
#define YYMAXTOKEN 264
#if YYDEBUG
char *_nsyyname[] = {
"end-of-file",0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,"':'",0,0,"'='",0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,"'['",0,"']'",0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,"NL","SUCCESS",
"UNAVAIL","NOTFOUND","TRYAGAIN","RETURN","CONTINUE","STRING",
};
char *_nsyyrule[] = {
"$accept : File",
"File :",
"File : Lines",
"Lines : Entry",
"Lines : Lines Entry",
"Entry : NL",
"Entry : Database ':' NL",
"Entry : Database ':' Srclist NL",
"Entry : error NL",
"Database : STRING",
"Srclist : Item",
"Srclist : Srclist Item",
"Item : STRING",
"$$1 :",
"Item : STRING '[' $$1 Criteria ']'",
"Criteria : Criterion",
"Criteria : Criteria Criterion",
"Criterion : Status '=' Action",
"Status : SUCCESS",
"Status : UNAVAIL",
"Status : NOTFOUND",
"Status : TRYAGAIN",
"Action : RETURN",
"Action : CONTINUE",
};
#endif
#ifdef YYSTACKSIZE
#undef YYMAXDEPTH
#define YYMAXDEPTH YYSTACKSIZE
#else
#ifdef YYMAXDEPTH
#define YYSTACKSIZE YYMAXDEPTH
#else
#define YYSTACKSIZE 500
#define YYMAXDEPTH 500
#endif
#endif
int yydebug;
int yynerrs;
int yyerrflag;
int yychar;
short *yyssp;
YYSTYPE *yyvsp;
YYSTYPE yyval;
YYSTYPE yylval;
short yyss[YYSTACKSIZE];
YYSTYPE yyvs[YYSTACKSIZE];
#define yystacksize YYSTACKSIZE
#line 150 "nsparser.y"

static void
_nsaddsrctomap(elem)
	const char *elem;
{
	int		i, lineno;
	extern int	_nsyylineno;
	extern char *	_nsyytext;

	lineno = _nsyylineno - (*_nsyytext == '\n' ? 1 : 0);
	if (curdbt.srclistsize > 0) {
		if ((strcasecmp(elem, NSSRC_COMPAT) == 0) ||
		    (strcasecmp(curdbt.srclist[0].name, NSSRC_COMPAT) == 0)) {
				/* XXX: syslog the following */
			printf("line %d 'compat' used with other sources",
			    lineno);
			return;
		}
	}
	for (i = 0; i < curdbt.srclistsize; i++) {
		if (strcasecmp(curdbt.srclist[i].name, elem) == 0) {
				/* XXX: syslog the following */
			printf("%s line %d: duplicate source '%s'",
			    lineno, elem);
			return;
		}
	}
	cursrc.name = elem;
	_nsdbtaddsrc(&curdbt, &cursrc);
}
#line 276 "y.tab.c"
#define YYABORT goto yyabort
#define YYREJECT goto yyabort
#define YYACCEPT goto yyaccept
#define YYERROR goto yyerrlab
int
yyparse()
{
    register int yym, yyn, yystate;
#if YYDEBUG
    register char *yys;
    extern char *getenv();

    if (yys = getenv("YYDEBUG"))
    {
        yyn = *yys;
        if (yyn >= '0' && yyn <= '9')
            yydebug = yyn - '0';
    }
#endif

    yynerrs = 0;
    yyerrflag = 0;
    yychar = (-1);

    yyssp = yyss;
    yyvsp = yyvs;
    *yyssp = yystate = 0;

yyloop:
    if (yyn = yydefred[yystate]) goto yyreduce;
    if (yychar < 0)
    {
        if ((yychar = yylex()) < 0) yychar = 0;
#if YYDEBUG
        if (yydebug)
        {
            yys = 0;
            if (yychar <= YYMAXTOKEN) yys = yyname[yychar];
            if (!yys) yys = "illegal-symbol";
            printf("%sdebug: state %d, reading %d (%s)\n",
                    YYPREFIX, yystate, yychar, yys);
        }
#endif
    }
    if ((yyn = yysindex[yystate]) && (yyn += yychar) >= 0 &&
            yyn <= YYTABLESIZE && yycheck[yyn] == yychar)
    {
#if YYDEBUG
        if (yydebug)
            printf("%sdebug: state %d, shifting to state %d\n",
                    YYPREFIX, yystate, yytable[yyn]);
#endif
        if (yyssp >= yyss + yystacksize - 1)
        {
            goto yyoverflow;
        }
        *++yyssp = yystate = yytable[yyn];
        *++yyvsp = yylval;
        yychar = (-1);
        if (yyerrflag > 0)  --yyerrflag;
        goto yyloop;
    }
    if ((yyn = yyrindex[yystate]) && (yyn += yychar) >= 0 &&
            yyn <= YYTABLESIZE && yycheck[yyn] == yychar)
    {
        yyn = yytable[yyn];
        goto yyreduce;
    }
    if (yyerrflag) goto yyinrecovery;
#ifdef lint
    goto yynewerror;
#endif
yynewerror:
    yyerror("syntax error");
#ifdef lint
    goto yyerrlab;
#endif
yyerrlab:
    ++yynerrs;
yyinrecovery:
    if (yyerrflag < 3)
    {
        yyerrflag = 3;
        for (;;)
        {
            if ((yyn = yysindex[*yyssp]) && (yyn += YYERRCODE) >= 0 &&
                    yyn <= YYTABLESIZE && yycheck[yyn] == YYERRCODE)
            {
#if YYDEBUG
                if (yydebug)
                    printf("%sdebug: state %d, error recovery shifting\
 to state %d\n", YYPREFIX, *yyssp, yytable[yyn]);
#endif
                if (yyssp >= yyss + yystacksize - 1)
                {
                    goto yyoverflow;
                }
                *++yyssp = yystate = yytable[yyn];
                *++yyvsp = yylval;
                goto yyloop;
            }
            else
            {
#if YYDEBUG
                if (yydebug)
                    printf("%sdebug: error recovery discarding state %d\n",
                            YYPREFIX, *yyssp);
#endif
                if (yyssp <= yyss) goto yyabort;
                --yyssp;
                --yyvsp;
            }
        }
    }
    else
    {
        if (yychar == 0) goto yyabort;
#if YYDEBUG
        if (yydebug)
        {
            yys = 0;
            if (yychar <= YYMAXTOKEN) yys = yyname[yychar];
            if (!yys) yys = "illegal-symbol";
            printf("%sdebug: state %d, error recovery discards token %d (%s)\n",
                    YYPREFIX, yystate, yychar, yys);
        }
#endif
        yychar = (-1);
        goto yyloop;
    }
yyreduce:
#if YYDEBUG
    if (yydebug)
        printf("%sdebug: state %d, reducing by rule %d (%s)\n",
                YYPREFIX, yystate, yyn, yyrule[yyn]);
#endif
    yym = yylen[yyn];
    yyval = yyvsp[1-yym];
    switch (yyn)
    {
case 7:
#line 87 "nsparser.y"
{
			_nsdbtput(&curdbt);
		}
break;
case 8:
#line 91 "nsparser.y"
{
			yyerrok;
		}
break;
case 9:
#line 98 "nsparser.y"
{
			curdbt.name = yylval.str;
			curdbt.srclist = NULL;
			curdbt.srclistsize = 0;
		}
break;
case 12:
#line 112 "nsparser.y"
{
			cursrc.flags = NS_SUCCESS;
			_nsaddsrctomap(yyvsp[0].str);
		}
break;
case 13:
#line 116 "nsparser.y"
{ cursrc.flags = NS_SUCCESS; }
break;
case 14:
#line 117 "nsparser.y"
{
			_nsaddsrctomap(yyvsp[-4].str);
		}
break;
case 17:
#line 129 "nsparser.y"
{
			if (yyvsp[0].mapval)		/* if action == RETURN set RETURN bit */
				cursrc.flags |= yyvsp[-2].mapval;  
			else		/* else unset it */
				cursrc.flags &= ~yyvsp[-2].mapval;
		}
break;
case 18:
#line 138 "nsparser.y"
{ yyval.mapval = NS_SUCCESS; }
break;
case 19:
#line 139 "nsparser.y"
{ yyval.mapval = NS_UNAVAIL; }
break;
case 20:
#line 140 "nsparser.y"
{ yyval.mapval = NS_NOTFOUND; }
break;
case 21:
#line 141 "nsparser.y"
{ yyval.mapval = NS_TRYAGAIN; }
break;
case 22:
#line 145 "nsparser.y"
{ yyval.mapval = 1L; }
break;
case 23:
#line 146 "nsparser.y"
{ yyval.mapval = 0L; }
break;
#line 487 "y.tab.c"
    }
    yyssp -= yym;
    yystate = *yyssp;
    yyvsp -= yym;
    yym = yylhs[yyn];
    if (yystate == 0 && yym == 0)
    {
#if YYDEBUG
        if (yydebug)
            printf("%sdebug: after reduction, shifting from state 0 to\
 state %d\n", YYPREFIX, YYFINAL);
#endif
        yystate = YYFINAL;
        *++yyssp = YYFINAL;
        *++yyvsp = yyval;
        if (yychar < 0)
        {
            if ((yychar = yylex()) < 0) yychar = 0;
#if YYDEBUG
            if (yydebug)
            {
                yys = 0;
                if (yychar <= YYMAXTOKEN) yys = yyname[yychar];
                if (!yys) yys = "illegal-symbol";
                printf("%sdebug: state %d, reading %d (%s)\n",
                        YYPREFIX, YYFINAL, yychar, yys);
            }
#endif
        }
        if (yychar == 0) goto yyaccept;
        goto yyloop;
    }
    if ((yyn = yygindex[yym]) && (yyn += yystate) >= 0 &&
            yyn <= YYTABLESIZE && yycheck[yyn] == yystate)
        yystate = yytable[yyn];
    else
        yystate = yydgoto[yym];
#if YYDEBUG
    if (yydebug)
        printf("%sdebug: after reduction, shifting from state %d \
to state %d\n", YYPREFIX, *yyssp, yystate);
#endif
    if (yyssp >= yyss + yystacksize - 1)
    {
        goto yyoverflow;
    }
    *++yyssp = yystate;
    *++yyvsp = yyval;
    goto yyloop;
yyoverflow:
    yyerror("yacc stack overflow");
yyabort:
    return (1);
yyaccept:
    return (0);
}
