/*
 * This file is part of ocamljs, OCaml to Javascript compiler
 * Copyright (C) 2007-9 Skydeck, Inc
 * Copyright (C) 2010 Jake Donham
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the Free
 * Software Foundation, Inc., 59 Temple Place - Suite 330, Boston,
 * MA 02111-1307, USA
 */

var caml_blit_string = function (s1, o1, s2, o2, n) {
  for (var i = 0; i < n; i++)
    oc$$ssetu(s2, o2 + i, oc$$srefu(s1, o1 + i));
}
var caml_callback = function (f, a) { return _(f, [a]); }
var caml_callback2 = function (f, a1, a2) { return _(f, [a1, a2]); }
var caml_callback3 = function (f, a1, a2, a3) { return _(f, [a1, a2, a3]); }
var caml_callback4 = function (f, a1, a2, a3, a4) { return _(f, [a1, a2, a3, a4]); }
var caml_callback5 = function (f, a1, a2, a3, a4, a5) { return _(f, [a1, a2, a3, a4, a5]); }
var caml_callbackN = function (f, n, args) { return _(f, args); }
// XXX caml_callback_exn ?
var compare_val = function (v1, v2, total) {
  var LESS = -1;
  var GREATER = 1;
  var EQUAL = 0;
  var UNORDERED = -2; // XXX ok?

  // XXX needs some work

  if (v1 == v2 && total) return EQUAL;

  var t1 = typeof v1;
  var t2 = typeof v2;
  if (t1 == t2) {
    switch (t1) {
    case "boolean":
      if (v1 < v2) return LESS;
      if (v1 > v2) return GREATER;
      return EQUAL;
    case "number":
      if (v1 < v2) return LESS;
      if (v1 > v2) return GREATER;
      if (v1 != v2) {
	if (!total) return UNORDERED;
	if (v1 == v1) return GREATER;
	if (v2 == v2) return LESS;
	return EQUAL;
      }
      return EQUAL;
    case "string":
      if (v1 < v2) return LESS;
      if (v1 > v2) return GREATER;
      return EQUAL;
    case "function":
      caml_invalid_argument("equal: functional value");
    case "object":
      // like NaN
      if (v1 == null) {
	if (v2 == null) return EQUAL;
	return LESS;
      }
      if (v2 == null) return GREATER;

      // XXX is there a way to get the class of an object as a value?
      // XXX is it worth special casing various JS objects?
      if (v1 instanceof Date) {
	var t1 = v1.getTime();
	var t2 = v2.getTime();
	if (t1 < t2) return LESS;
	if (t1 > t2) return GREATER;
	return EQUAL;
      }
      if (v1 instanceof Array) {
	// we should always either have both tags or neither
	// so it is OK to fall through here
	if (v1.t < v2.t) return LESS;
	if (v1.t > v2.t) return GREATER;
	var sz1 = v1.length;
	var sz2 = v2.length;
	if (sz1 < sz2) return LESS;
	if (sz1 > sz2) return GREATER;
	if (sz1 == 0) return EQUAL;
	for (var i=0; i < sz1; i++)
	  {
	    var c = compare_val(v1[i], v2[i], total);
	    if (c != EQUAL) return c;
	  }
	return EQUAL;
      }
      if (v1 instanceof oc$$ms) {
	var s1 = v1.toString();
	var s2 = v2.toString();
	if (s1 < s2) return LESS;
	if (s1 > s2) return GREATER;
	return EQUAL;
      }
      if (v1._m != null && v2._m != null) { // i.e. an OCaml object XXX better test
        var oid1 = v1[1];
        var oid2 = v2[1];
        if (oid1 < oid2) return LESS;
        if (oid1 > oid2) return GREATER;
        return EQUAL;
      }
      return UNORDERED; // XXX
    default:
      return UNORDERED;
    }
  }

  // like NaN
  if (v1 == null) {
    if (v2 == null) return EQUAL;
    return LESS;
  }
  if (v2 == null) return GREATER;

  // one boolean and one int
  if (t1 == "boolean" || t2 == "boolean")
  {
    if (v1 < v2) return LESS;
    if (v1 > v2) return GREATER;
    return EQUAL;
  }
  // one mutable and one immutable string
  if (t1 == "string" || t2 == "string")
  {
    var s1 = v1.toString();
    var s2 = v2.toString();
    if (s1 < s2) return LESS;
    if (s1 > s2) return GREATER;
    return EQUAL;
  }
  // one constructor without data (number) and one with (object Array)
  if (t1 == "number") return LESS;
  if (t2 == "number") return GREATER;
  return UNORDERED;
}
var caml_compare = function (v1, v2) {
  var res = compare_val(v1, v2, 1);
  return res < 0 ? -1 : res > 0 ? 1 : 0;
}
var caml_equal = function (v1, v2) { return compare_val(v1, v2, 0) == 0; }
var caml_failwith = function (s) { throw $(Failure$19g, s); }
var caml_fill_string = function(s, o, l, c) {
  for (var i = 0; i < l; i++)
    oc$$ssetu(s, o + i, c);
}
var caml_float_compare = function (v1, v2) {
  if (v1 === v2) return 0;
  if (v1 < v2) return -1;
  if (v1 > v2) return 1;
  if (v1 === v1) return 1;
  if (v2 === v2) return -1;
  return 0;
}
var caml_float_of_string = function (s) {
  var f = parseFloat(s);
  return isNaN(f) ? caml_failwith("float_of_string") : f;
}
var caml_classify_float = function (f) {
  if (isNaN(f)) return 4; // FP_nan
  else if (!isFinite(f)) return 3; // FP_infinite
  else if (f === 0) return 2; // FP_zero
  // can't determine subnormal from js afaik
  else return 0; // FP_normal
}

var caml_greaterthan = function (v1, v2) { return compare_val(v1, v2, 0) > 0; }
var caml_greaterequal = function (v1, v2) { return compare_val(v1, v2, 0) >= 0; }
var caml_hash_univ_param = function (count, limit, obj) {
  // globals
  hash_univ_limit = limit;
  hash_univ_count = count;
  hash_accu = 0;

  // XXX needs work
  function hash_aux(obj) {
    hash_univ_limit--;
    if (hash_univ_count < 0 || hash_univ_limit < 0) return;

    function combine(n) { hash_accu = hash_accu * 65599 + n; }
    function combine_small(n) { hash_accu = hash_accu * 19 + n; }

    switch (typeof obj) {
    case "number":
      // XXX for floats C impl examines bit rep
      // XXX for constructors without data C impl uses combine_small
      hash_univ_count--;
      combine(obj);
      break;
    case "string":
      hash_univ_count--;
      for (var i = obj.length; i > 0; i--)
        combine_small(obj.charCodeAt(i));
      break;
    case "boolean":
      hash_univ_count--;
      combine_small(obj ? 1 : 0);
      break;
    case "object":
      if (obj instanceof oc$$ms)
        hash_aux(obj.toString());
      else if (obj instanceof Array) { // possibly a block
        if (obj.t) {
          hash_univ_count--;
          combine_small(obj.t);
          for (var i = obj.length; i > 0; i--)
            hash_aux(obj[i]);
        }
      }
      else if (obj._m != null) { // OCaml object, use oid
        hash_univ_count--;
        combine(obj[1]);
      }
      break;
    default:
      break;
    }
  }

  hash_aux(obj);
  return hash_accu & 0x3FFFFFFF;
}
var caml_input_value = function () { throw "caml_input_value"; }
var caml_input_value_from_string = function () { throw "caml_input_value_from_string"; }
var caml_install_signal_handler = function () { throw "caml_install_signal_handler"; }
var caml_int_compare = function (i1, i2) { return (i1 > i2) - (i1 < i2); }
var caml_int32_compare = function (i1, i2) { return (i1 > i2) - (i1 < i2); }
var caml_int64_compare = function (i1, i2) { throw "caml_int64_compare"; }
var caml_int64_float_of_bits = function (s) {
  // see pervasives.ml; int64s are represented by strings
  switch (s) {
  case "9218868437227405312": return Number.POSITIVE_INFINITY;
  case "-4503599627370496": return Number.NEGATIVE_INFINITY;
  case "9218868437227405313": return Number.NaN;
  case "9218868437227405311" : return Number.MAX_VALUE;
  case "4503599627370496": return Number.MIN_VALUE;
  case "4372995238176751616": return 0; // XXX how to get epsilon in js?
  default: return 0;
  }
}
var caml_int_of_string = function (s) {
  var i = parseInt(s, 10);
  return isNaN(i) ? caml_failwith("int_of_string") : i;
}
var caml_int32_of_string = caml_int_of_string;
var caml_int64_of_string = caml_int_of_string;
var caml_nativeint_of_string = caml_int_of_string;
var caml_invalid_argument = function (s) { throw $(Invalid_argument$18g, s); }
var caml_is_printable = function (c) { return c > 31 && c < 127; } // XXX get this right
var caml_lessthan = function (v1, v2) { return compare_val(v1, v2, 0) -1 < -1; }
var caml_lessequal = function (v1, v2) { return compare_val(v1, v2, 0) -1 <= -1; }
var caml_make_vect = function (l, i) {
  var a = new Array(l);
  for (var j = 0; j < l; j++)
    a[j] = i;
  return a;
}
var caml_marshal_data_size = function () { throw "caml_marshal_data_size"; }
var caml_md5_chan = function () { throw "caml_md5_chan"; }
var caml_md5_string = function () { throw "caml_md5_string"; }
var caml_ml_channel_size = function () { throw "caml_ml_channel_size"; }
var caml_ml_channel_size_64 = function () { throw "caml_ml_channel_size_64"; }
var caml_ml_close_channel = function () { throw "caml_ml_close_channel"; }

var caml_ml_flush = function (c) { }

var caml_ml_input = function () { throw "caml_ml_input"; }
var caml_ml_input_char = function () { throw "caml_ml_input_char"; }
var caml_ml_input_int = function () { throw "caml_ml_input_int"; }
var caml_ml_input_scan_line = function () { throw "caml_ml_input_scan_line"; }
var caml_ml_open_descriptor_in = function () { return 0; } // XXX
var caml_ml_open_descriptor_out = function () { return 0; } // XXX
var caml_ml_out_channels_list = function () { return 0; }

var caml_ml_output = function (c, b, s, l) { print_verbatim(b); }
var caml_ml_output_char = function (c, ch) {  }

var caml_ml_output_int = function () { throw "caml_ml_output_int"; }
var caml_ml_pos_in = function () { throw "caml_ml_pos_in"; }
var caml_ml_pos_in_64 = function () { throw "caml_ml_pos_in_64"; }
var caml_ml_pos_out = function () { throw "caml_ml_pos_out"; }
var caml_ml_pos_out_64 = function () { throw "caml_ml_pos_out_64"; }
var caml_ml_seek_in = function () { throw "caml_ml_seek_in"; }
var caml_ml_seek_in_64 = function () { throw "caml_ml_seek_in_64"; }
var caml_ml_seek_out = function () { throw "caml_ml_seek_out"; }
var caml_ml_seek_out_64 = function () { throw "caml_ml_seek_out_64"; }
var caml_ml_set_binary_mode = function () { throw "caml_ml_set_binary_mode"; }
var caml_named_value = function (n) { return oc$$nv[n]; }
var caml_nativeint_compare = function (i1, i2) { return (i1 > i2) - (i1 < i2); }
var caml_notequal = function (v1, v2) { return compare_val(v1, v2, 0) != 0; }
var caml_obj_dup = function (a) {
  var l = a.length;
  var d = new Array(l);
  for (var i=0; i < l; i++)
    d[i] = a[i];
  d.t = a.t;
  return d;
}
var caml_obj_is_block = function (o) { return !(typeof o == 'number') }
var caml_obj_tag = function(o) { return o.t || 0; }
var caml_obj_set_tag = function(o, t) { o.t = t; }
var caml_obj_block = function(t, s) { if (s == 0) return t; else { var a = new Array(s); a.t = t; return a; } }
var caml_obj_truncate = function(o, s) { o.length = s; }
var caml_output_value = function () { throw "caml_output_value"; }
var caml_output_value_to_string = function () { throw "caml_output_value_to_string"; }
var caml_output_value_to_buffer = function () { throw "caml_output_value_to_buffer"; }
var caml_record_backtrace = function () { throw "caml_record_backtrace"; }
var caml_backtrace_status = function () { throw "caml_backtrace_status"; }
var caml_get_exception_backtrace = function () { throw "caml_get_exception_backtrace"; }
var caml_register_named_value = function (n, v) { oc$$nv[n] = v; }
var caml_string_compare = function (s1, s2) {
  if (oc$$slt(s1, s2)) return -1;
  else if (oc$$sgt(s1, s2)) return 1;
  else return 0;
}
var caml_sys_exit = function () { throw "caml_sys_exit"; }
  var init_time = (new Date()).getTime() / 1000;
var caml_sys_time = function () { return (new Date()).getTime() / 1000 - init_time; }
var caml_sys_get_argv = function () { return $("", $()); } // XXX put something here?
var caml_sys_get_config = function () { return $("js", 32); } // XXX browser name?
var caml_sys_open = function () { throw "caml_sys_open"; }
var caml_sys_random_seed = function() { throw "caml_sys_random_seed"; }

// lexing.c

function Short(tbl, n) {
  var s = tbl.charCodeAt(n * 2) + (tbl.charCodeAt(n * 2 + 1) << 8);
  return s & 32768 ? s + -65536 : s;
}

var caml_lex_engine = function (tbl, start_state, lexbuf)
{
  var state, base, backtrk, c;

  state = start_state;
  if (state >= 0) {
    /* First entry */
    lexbuf[6] = lexbuf[4] = lexbuf[5];
    lexbuf[7] = -1;
  } else {
    /* Reentry after refill */
    state = -state - 1;
  }
  while(1) {
    /* Lookup base address or action number for current state */
    base = Short(tbl[0], state);
    if (base < 0) return -base-1;
    /* See if it's a backtrack point */
    backtrk = Short(tbl[1], state);
    if (backtrk >= 0) {
      lexbuf[6] = lexbuf[5];
      lexbuf[7] = backtrk;
    }
    /* See if we need a refill */
    if (lexbuf[5] >= lexbuf[2]){
      if (lexbuf[8] === false){
        return -state - 1;
      }else{
        c = 256;
      }
    }else{
      /* Read next input char */
      c = lexbuf[1].charCodeAt(lexbuf[5]);
      lexbuf[5] += 1;
    }
    /* Determine next state */
    if (Short(tbl[4], base + c) == state)
      state = Short(tbl[3], base + c);
    else
      state = Short(tbl[2], state);
    /* If no transition on this char, return to last backtrack point */
    if (state < 0) {
      lexbuf[5] = lexbuf[6];
      if (lexbuf[7] == -1) {
        caml_failwith("lexing: empty token");
      } else {
        return lexbuf[7];
      }
    }else{
      /* Erase the EOF condition only if the EOF pseudo-character was
         consumed by the automaton (i.e. there was no backtrack above)
       */
      if (c == 256) lexbuf[8] = false;
    }
  }
}

/***********************************************/
/* New lexer engine, with memory of positions  */
/***********************************************/

function run_mem(p, pc, mem, curr_pos) {
  for (;;) {
    var dst, src ;

    dst = p.charCodeAt(pc++) ;
    if (dst == 0xff)
      return ;
    src = p.charCodeAt(pc++) ;
    if (src == 0xff) {
      /*      fprintf(stderr,"[%hhu] <- %d\n",dst,Int_val(curr_pos)) ;*/
      mem[dst] = curr_pos ;
    } else {
      /*      fprintf(stderr,"[%hhu] <- [%hhu]\n",dst,src) ; */
      mem[dst] = mem[src] ;
    }
  }
}

function run_tag(p, pc, mem) {
  for (;;) {
    var dst, src ;

    dst = p.charCodeAt(pc++) ;
    if (dst == 0xff)
      return ;
    src = p.charCodeAt(pc++) ;
    if (src == 0xff) {
      /*      fprintf(stderr,"[%hhu] <- -1\n",dst) ; */
      mem[dst] = -1 ;
    } else {
      /*      fprintf(stderr,"[%hhu] <- [%hhu]\n",dst,src) ; */
      mem[dst] = mem[src] ;
    }
  }
}

var caml_new_lex_engine = function (tbl, start_state, lexbuf)
{
  var state, base, backtrk, c, pstate ;
  state = start_state;
  if (state >= 0) {
    /* First entry */
    lexbuf[6] = lexbuf[4] = lexbuf[5];
    lexbuf[7] = -1;
  } else {
    /* Reentry after refill */
    state = -state - 1;
  }
  while(1) {
    /* Lookup base address or action number for current state */
    base = Short(tbl[0], state);
    if (base < 0) {
      var pc_off = Short(tbl[5], state) ;
      run_tag(tbl[10], pc_off, lexbuf[9]);
      /*      fprintf(stderr,"Perform: %d\n",-base-1) ; */
      return -base-1;
    }
    /* See if it's a backtrack point */
    backtrk = Short(tbl[1], state);
    if (backtrk >= 0) {
      var pc_off =  Short(tbl[6], state);
      run_tag(tbl[10], pc_off, lexbuf[9]);
      lexbuf[6] = lexbuf[5];
      lexbuf[7] = backtrk;

    }
    /* See if we need a refill */
    if (lexbuf[5] >= lexbuf[2]){
      if (lexbuf[8] === false){
        return -state - 1;
      }else{
        c = 256;
      }
    }else{
      /* Read next input char */
      c = lexbuf[1].charCodeAt(lexbuf[5]);
      lexbuf[5] += 1;
    }
    /* Determine next state */
    pstate=state ;
    if (Short(tbl[4], base + c) == state)
      state = Short(tbl[3], base + c);
    else
      state = Short(tbl[2], state);
    /* If no transition on this char, return to last backtrack point */
    if (state < 0) {
      lexbuf[5] = lexbuf[6];
      if (lexbuf[7] == -1) {
        caml_failwith("lexing: empty token");
      } else {
        return lexbuf[7];
      }
    }else{
      /* If some transition, get and perform memory moves */
      var base_code = Short(tbl[5], pstate) ;
      var pc_off ;
      if (Short(tbl[9], base_code + c) == pstate)
        pc_off = Short(tbl[8], base_code + c) ;
      else
        pc_off = Short(tbl[7], pstate) ;
      if (pc_off > 0) 
        run_mem(tbl[10], pc_off, lexbuf[9], lexbuf[5]) ;
      /* Erase the EOF condition only if the EOF pseudo-character was
         consumed by the automaton (i.e. there was no backtrack above)
       */
      if (c == 256) lexbuf[8] = false;
    }
  }
}

// parsing.c

var caml_parser_trace = false

/* Auxiliary for printing token just read */

function token_name(names, number)
{
  var n = 0;
  for (/*nothing*/; number > 0; number--) {
    var i = names.indexOf("\x00", n);
    if (i == -1) return "<unknown token>";
    n = i + 1;
  }
  return names.substr(n, names.indexOf("\x00", n) - n);
}

function print_token(tables, state, tok)
{
  if (typeof tok == 'number') {
    print("State " + state + ": read token " + token_name(tables[14], tok));
  } else {
    print("State " + state + ": read token " + token_name(tables[15], tok.t) + "(" + tok[0] + ")");
  }      
}      

/* The pushdown automata */

var caml_parse_engine = function (tables, env, cmd, arg)
{
  var state;
  var sp, asp;
  var errflag;
  var n, n1, n2, m, state1;

  loop: while (true) switch (cmd) {

  case 0:
    state = 0;
    sp = env[13];
    errflag = 0;

  case -1:
    n = Short(tables[5], state);
    if (n != 0) { cmd = -7; continue loop; }
    if (env[6] >= 0) { cmd = -2; continue loop; }
    env[13] = sp; env[14] = state; env[15] = errflag;
    return 0;
                                /* The ML code calls the lexer and updates */
                                /* symb_start and symb_end */
  case 1:
    sp = env[13]; state = env[14]; errflag = env[15];
    if (!(typeof arg == 'number')) {
      env[6] = tables[2][arg.t];
      env[7] = arg[0];
    } else {
      env[6] = tables[1][arg];
      env[7] = 0;
    }
    if (caml_parser_trace) print_token(tables, state, arg);
    
  case -2:
    n1 = Short(tables[7], state);
    n2 = n1 + env[6];
    if (n1 != 0 && n2 >= 0 && n2 <= tables[10] &&
        Short(tables[12], n2) == env[6]) { cmd = -4; continue loop; }
    n1 = Short(tables[8], state);
    n2 = n1 + env[6];
    if (n1 != 0 && n2 >= 0 && n2 <= tables[10] &&
        Short(tables[12], n2) == env[6]) {
      n = Short(tables[11], n2);
      cmd = -7; continue loop;
    }
    if (errflag > 0) { cmd = -3; continue; }
    env[13] = sp; env[14] = state; env[15] = errflag;
    return 5;
                                /* The ML code calls the error function */
  case 5:
    sp = env[13]; state = env[14]; errflag = env[15];
  case -3:
    if (errflag < 3) {
      errflag = 3;
      while (1) {
        state1 = env[0][sp];
        n1 = Short(tables[7], state1);
        n2 = n1 + 256;
        if (n1 != 0 && n2 >= 0 && n2 <= tables[10] &&
            Short(tables[12], n2) == 256) {
          if (caml_parser_trace) 
            print("Recovering in state " + state1);
          cmd = -5; continue loop;
        } else {
          if (caml_parser_trace){
            print("Discarding state " + state1);
          }
          if (sp <= env[5]) {
            if (caml_parser_trace){
              print("No more states to discard");
            }
            return 1; /* The ML code raises Parse_error */
          }
          sp--;
        }
      }
    } else {
      if (env[6] == 0)
        return 1; /* The ML code raises Parse_error */
      if (caml_parser_trace) print("Discarding last token read");
      env[6] = -1;
      cmd = -1; continue loop;
    }
    
  case -4:
    env[6] = -1;
    if (errflag > 0) errflag--;
  case -5:
    if (caml_parser_trace)
      print("State " + state + ": shift to state " + Short(tables[11], n2));
    state = Short(tables[11], n2);
    sp++;
    if (sp < env[4]) { cmd = -6; continue loop; }
    env[13] = sp; env[14] = state; env[15] = errflag;
    return 2;
                                 /* The ML code resizes the stacks */
  case 2:
    sp = env[13]; state = env[14]; errflag = env[15];
  case -6:
    env[0][sp] = state;
    env[1][sp] = env[7];
    env[2][sp] = env[8];
    env[3][sp] = env[9];
    cmd = -1; continue loop;

  case -7:
    if (caml_parser_trace)
      print("State " + state + ": reduce by rule " + n);
    m = Short(tables[4], n);
    env[10] = sp;
    env[12] = n;
    env[11] = m;
    sp = sp - m + 1;
    m = Short(tables[3], n);
    state1 = env[0][sp - 1];
    n1 = Short(tables[9], m);
    n2 = n1 + state1;
    if (n1 != 0 && n2 >= 0 && n2 <= tables[10] &&
        Short(tables[12], n2) == state1) {
      state = Short(tables[11], n2);
    } else {
      state = Short(tables[6], m);
    }
    if (sp < env[4]) { cmd = -8; continue loop; }
    env[13] = sp; env[14] = state; env[15] = errflag;
    return 3;
                                /* The ML code resizes the stacks */
  case 3:
    sp = env[13]; state = env[14]; errflag = env[15];
  case -8:
    env[13] = sp; env[14] = state; env[15] = errflag;
    return 4;
                                /* The ML code calls the semantic action */
  case 4:
    sp = env[13]; state = env[14]; errflag = env[15];
    env[0][sp] = state;
    env[1][sp] = arg;
    asp = env[10];
    env[3][sp] = env[3][asp];
    if (sp > asp) {
      /* This is an epsilon production. Take symb_start equal to symb_end. */
      env[2][sp] = env[3][asp];
    }
    cmd = -1; continue loop;
  }
}

var caml_set_parser_trace = function (flag)
{
  var oldflag = caml_parser_trace;
  caml_parser_trace = flag;
  return oldflag;
}

/*
  stuff below taken from js_of_ocaml/lib
  Copyright (C) 2010 Jérôme Vouillon
*/

///////////// Format
//Provides: caml_parse_format
//Requires: caml_invalid_argument
function caml_parse_format (fmt) {
  fmt = fmt.toString ();
  var len = fmt.length;
  if (len > 31) caml_invalid_argument("format_int: format too long");
  var f =
    { justify:'+', signstyle:'-', filler:' ', alternate:false,
      base:0, signedconv:false, width:0, uppercase:false,
      sign:1, prec:6, conv:'f' };
  for (var i = 0; i < len; i++) {
    var c = fmt.charAt(i);
    switch (c) {
    case '-':
      f.justify = '-'; break;
    case '+': case ' ':
      f.signstyle = c; break;
    case '0':
      f.filler = '0'; break;
    case '#':
      f.alternate = true; break;
    case '1': case '2': case '3': case '4': case '5':
    case '6': case '7': case '8': case '9':
      f.width = 0;
      while (c=fmt.charCodeAt(i) - 48, c >= 0 && c <= 9) {
        f.width = f.width * 10 + c; i++
      }
      i--;
     break;
    case '.':
      f.prec = 0;
      i++;
      while (c=fmt.charCodeAt(i) - 48, c >= 0 && c <= 9) {
        f.prec = f.prec * 10 + c; i++
      }
      i--;
    case 'd': case 'i': case 'l': case 'n': case 'L': case 'N':
      f.signedconv = true; /* fallthrough */
    case 'u':
      f.base = 10; break;
    case 'x':
      f.base = 16; break;
    case 'X':
      f.base = 16; f.uppercase = true; break;
    case 'o':
      f.base = 8; break;
    case 'e': case 'f': case 'g':
      f.signedconv = true; f.conv = c; break;
    case 'E': case 'F': case 'G':
      f.signedconv = true; f.uppercase = true;
      f.conv = c.toLowerCase (); break;
    }
  }
  return f;
}

//Provides: caml_finish_formatting
//Requires: MlString
function caml_finish_formatting(f, rawbuffer) {
  if (f.uppercase) rawbuffer = rawbuffer.toUpperCase();
  var len = rawbuffer.length;
  /* Adjust len to reflect additional chars (sign, etc) */
  if (f.signedconv && (f.sign < 0 || f.signstyle != '-')) len++;
  if (f.alternate) {
    if (f.base == 8) len += 1;
    if (f.base == 16) len += 2;
  }
  /* Do the formatting */
  var buffer = "";
  if (f.justify == '+' && f.filler == ' ')
    for (i = len; i < f.width; i++) buffer += ' ';
  if (f.signedconv) {
    if (f.sign < 0) buffer += '-';
    else if (f.signstyle != '-') buffer += f.signstyle;
  }
  if (f.alternate && f.base == 8) buffer += '0';
  if (f.alternate && f.base == 16) buffer += "0x";
  if (f.justify == '+' && f.filler == '0')
    for (i = len; i < f.width; i++) buffer += '0';
  buffer += rawbuffer;
  if (f.justify == '-')
    for (i = len; i < f.width; i++) buffer += ' ';
  return buffer;
}

//Provides: caml_format_int const
//Requires: caml_parse_format, caml_finish_formatting
function caml_format_int(fmt, i) {
  if (fmt.toString() == "%d") return (""+i);
  var f = caml_parse_format(fmt);
  if (i < 0) { if (f.signedconv) { f.sign = -1; i = -i; } else i >>>= 0; }
  var s = i.toString(f.base);
  return caml_finish_formatting(f, s);
}

//Provides: caml_format_float const
//Requires: caml_parse_format, caml_finish_formatting
function caml_format_float (fmt, x) {
  var s, f = caml_parse_format(fmt);
  if (x < 0) { f.sign = -1; x = -x; }
  if (isNaN(x)) { s = "nan"; f.filler = ' '; }
  else if (!isFinite(x)) { s = "inf"; f.filler = ' '; }
  else
    switch (f.conv) {
    case 'e':
      var s = x.toExponential(f.prec);
      // exponent should be at least two digits
      var i = s.length;
      if (s.charAt(i - 3) == 'e')
        s = s.slice (0, i - 1) + '0' + s.slice (i - 1);
      break;
    case 'f':
      s = x.toFixed(f.prec); break;
    case 'g':
      var prec = f.prec?f.prec:1;
      s = x.toExponential(prec - 1);
      var j = s.indexOf('e');
      var exp = +s.slice(j + 1);
      if (exp < -4 || x.toFixed(0).length > prec) {
        // remove trailing zeroes
        var i = j - 1; while (s.charAt(i) == '0') i--;
        if (s.charAt(i) == '.') i--;
        s = s.slice(0, i + 1) + s.slice(j);
        i = s.length;
        if (s.charAt(i - 3) == 'e')
          s = s.slice (0, i - 1) + '0' + s.slice (i - 1);
        break;
      } else {
        var p = prec;
        if (exp < 0) { p -= exp + 1; s = x.toFixed(p); }
        else while (s = x.toFixed(p), s.length > prec + 1) p--;
        if (p) {
          // remove trailing zeroes
          i = s.length - 1; while (s.charAt(i) == '0') i--;
          if (s.charAt(i) == '.') i--;
          s = s.slice(0, i + 1);
        }
      }
      break;
    }
  return caml_finish_formatting(f, s);
}
