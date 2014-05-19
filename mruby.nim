#
#* mruby - An embeddable Ruby implementation
#*
#* Copyright (c) mruby developers 2010-2014
#*
#* Permission is hereby granted, free of charge, to any person obtaining
#* a copy of this software and associated documentation files (the
#* "Software"), to deal in the Software without restriction, including
#* without limitation the rights to use, copy, modify, merge, publish,
#* distribute, sublicense, and/or sell copies of the Software, and to
#* permit persons to whom the Software is furnished to do so, subject to
#* the following conditions:
#*
#* The above copyright notice and this permission notice shall be
#* included in all copies or substantial portions of the Software.
#*
#* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
#* EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
#* MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
#* IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
#* CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
#* TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
#* SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#*
#* [ MIT license: http://www.opensource.org/licenses/mit-license.php ]
#

import math
{.passC: "-lmruby".}
{.passL: "-lmruby".}
{.pragma: h, header: "<mruby.h>".}
{.pragma: hc, header:"<mruby/compile.h>".}
{.pragma: hirep, header:"<mruby/irep.h>".}


#
#* mruby/value.h - mrb_value definition
#*
#* See Copyright Notice in mruby.h
#

when defined(MRB_USE_FLOAT): 
  type 
    Tfloat* = cfloat
  template float_to_str*(buf, i: expr): expr = 
    sprintf(buf, "%.7e", i)

  template str_to_mrb_float*(buf: expr): expr = 
    strtof(buf, nil)

else: 
  type 
    Tfloat* = cdouble
  template float_to_str*(buf, i: expr): expr = 
    sprintf(buf, "%.16e", i)

  template str_to_mrb_float*(buf: expr): expr = 
    strtod(buf, nil)

when defined(MRB_INT16) and defined(MRB_INT64): 
  {.error: "You can't define MRB_INT16 and MRB_INT64 at the same time.".}

when defined(MRB_INT64): 
  when defined(MRB_NAN_BOXING):
    {.error: "Cannot use NaN boxing when mrb_int is 64bit".}
  else:
    type 
      Tint* = int64
    const 
      MRB_INT_MIN* = INT64.low
      MRB_INT_MAX* = INT64.high
      PRIdMRB_INT* = PRId64
      PRIiMRB_INT* = PRIi64
      PRIoMRB_INT* = PRIo64
      PRIxMRB_INT* = PRIx64
      PRIXMRB_INT* = PRIX64
elif defined(MRB_INT16): 
  type 
    Tint* = int16_t
  const 
    MRB_INT_MIN* = INT16.low
    MRB_INT_MAX* = INT16.high
else: 
  type 
    Tint* = int32
  const 
    MRB_INT_MIN* = INT32.low
    MRB_INT_MAX* = INT32.high
  discard """ PRIdMRB_INT* = PRId32
    PRIiMRB_INT* = PRIi32
    PRIoMRB_INT* = PRIo32
    PRIxMRB_INT* = PRIx32
    PRIXMRB_INT* = PRIX32 """
type 
  Tsym* = cshort
discard """ when defined(_MSC_VER): 
  when not(defined(__cplusplus)): 
    const 
      inline* = __inline
  const 
    snprintf* = _snprintf
  when _MSC_VER < 1800: 
    const 
      isnan* = _isnan
    template isinf*(n: expr): expr = 
      (not _finite(n) and not _isnan(n))

    const 
      strtoll* = _strtoi64
      strtof* = cast[cfloat](strtod)
      PRId32* = "I32d"
      PRIi32* = "I32i"
      PRIo32* = "I32o"
      PRIx32* = "I32x"
      PRIX32* = "I32X"
      PRId64* = "I64d"
      PRIi64* = "I64i"
      PRIo64* = "I64o"
      PRIx64* = "I64x"
      PRIX64* = "I64X"
  else: 
else:  """
discard """ type 
  Tbool* = uint8_t """


type value* {.importc:"mrb_value",h.} = object
  # acts like a union
  f*: tfloat
  p*{.importc:"value.p".}: pointer
  ttt{.importc:"value.ttt".}: uint32
  tt {.importc.}: cint
  i* {.importc:"value.i".}: Tint
  sym*{.importc:"value.sym".}: Tsym
  

type 

  RClass* {.importc:"RClass",h.} = object

  TRBasic* {.importc: "RBasic", header: "<mruby.h>".} = object 
  iv_tbl* {.importc,h.} = object
  TRObject* {.importc: "RObject", header: "<mruby.h>".} = object 
    iv* {.importc: "iv".}: ptr iv_tbl #  MRB_OBJECT_HEADER;
    
    
  Tcallinfo* {.importc: "mrb_callinfo", header: "<mruby.h>".} = object 
    mid* {.importc: "mid".}: Tsym
    `proc`* {.importc: "proc".}: ptr TRProc # rename field?
    stackent* {.importc: "stackent".}: ptr value
    nregs* {.importc: "nregs".}: cint
    argc* {.importc: "argc".}: cint
    pc* {.importc: "pc".}: ptr Tcode # return address 
    err* {.importc: "err".}: ptr Tcode # error position 
    acc* {.importc: "acc".}: cint
    target_class* {.importc: "target_class".}: ptr RClass
    ridx* {.importc: "ridx".}: cint
    eidx* {.importc: "eidx".}: cint
    env* {.importc: "env".}: ptr TREnv
  PCallinfo* = ptr Tcallinfo
  
  Tfiber_state* = enum 
    MRB_FIBER_CREATED = 0, MRB_FIBER_RUNNING, MRB_FIBER_RESUMED, 
    MRB_FIBER_TERMINATED
  Tcontext* {.importc: "mrb_context", header: "<mruby.h>".} = object 
    prev* {.importc: "prev".}: ptr Tcontext
    stack* {.importc: "stack".}: ptr value # stack of virtual machine 
    stbase* {.importc: "stbase".}: ptr value
    stend* {.importc: "stend".}: ptr value
    ci* {.importc: "ci".}: ptr Tcallinfo
    cibase* {.importc: "cibase".}: Pcallinfo
    ciend* {.importc: "ciend".}: ptr Tcallinfo
    rescue* {.importc: "rescue".}: ptr ptr Tcode # exception handler stack 
    rsize* {.importc: "rsize".}: cint
    ensure* {.importc: "ensure".}: ptr ptr TRProc # ensure handler stack 
    esize* {.importc: "esize".}: cint
    status* {.importc: "status".}: Tfiber_state
    fib* {.importc: "fib".}: ptr TRFiber
    
  TRFiber* {.importc: "RFiber", header: "<mruby.h>".} = object 
    cxt* {.importc: "cxt".}: ptr Tcontext #  MRB_OBJECT_HEADER;
  
  Tcode* {.importc:"mrb_code",h.}= uint32
  Taspec*{.importc:"mrb_aspec",h.} = uint32
 
  Tirep* {.importc: "mrb_irep", header: "<mruby.h>".} = object 
  
  TREnv* {.importc: "REnv", header: "<mruby.h>".} = object 
    stack* {.importc: "stack".}: ptr value #  MRB_OBJECT_HEADER;
    mid* {.importc: "mid".}: Tsym
    cioff* {.importc: "cioff".}: cint

  PState* = ptr TState
  Tallocf* = proc (mrb: ptr Tstate; a3: pointer; a4: csize; ud: pointer): pointer {.
      cdecl.}
  Tstate* {.importc: "mrb_state", header: "<mruby.h>".} = object 
    jmp* {.importc: "jmp".}: pointer
    allocf* {.importc: "allocf".}: Tallocf # memory allocation function 
    c* {.importc: "c".}: ptr Tcontext
    root_c* {.importc: "root_c".}: ptr Tcontext
    exc* {.importc: "exc".}: ptr TRObject # exception 
    globals* {.importc: "globals".}: ptr iv_tbl # global variable table 
    top_self* {.importc: "top_self".}: ptr TRObject
    object_class* {.importc: "object_class".}: ptr RClass # Object class 
    class_class* {.importc: "class_class".}: ptr RClass
    module_class* {.importc: "module_class".}: ptr RClass
    proc_class* {.importc: "proc_class".}: ptr RClass
    string_class* {.importc: "string_class".}: ptr RClass
    array_class* {.importc: "array_class".}: ptr RClass
    hash_class* {.importc: "hash_class".}: ptr RClass
    float_class* {.importc: "float_class".}: ptr RClass
    fixnum_class* {.importc: "fixnum_class".}: ptr RClass
    true_class* {.importc: "true_class".}: ptr RClass
    false_class* {.importc: "false_class".}: ptr RClass
    nil_class* {.importc: "nil_class".}: ptr RClass
    symbol_class* {.importc: "symbol_class".}: ptr RClass
    kernel_module* {.importc: "kernel_module".}: ptr RClass
    heaps* {.importc: "heaps".}: ptr heap_page # heaps for GC 
    sweeps* {.importc: "sweeps".}: ptr heap_page
    free_heaps* {.importc: "free_heaps".}: ptr heap_page
    live* {.importc: "live".}: csize # count of live objects 
                                      ##ifdef MRB_GC_FIXED_ARENA
    arena* {.importc: "arena".}: array[MRB_GC_ARENA_SIZE, ptr RBasic] # GC 
                                                                      # protection array 
                                                                      ##else
    arena* {.importc: "arena".}: ptr ptr RBasic # GC protection array 
    arena_capa* {.importc: "arena_capa".}: cint ##endif
    arena_idx* {.importc: "arena_idx".}: cint
    Tgc_state* {.importc: "gc_state".}: Tgc_state # state of gc 
    current_white_part* {.importc: "current_white_part".}: cint # make white object by white_part 
    gray_list* {.importc: "gray_list".}: ptr RBasic # list of gray objects to be traversed incrementally 
    atomic_gray_list* {.importc: "atomic_gray_list".}: ptr RBasic # list of objects to be traversed atomically 
    gc_live_after_mark* {.importc: "gc_live_after_mark".}: csize
    gc_threshold* {.importc: "gc_threshold".}: csize
    gc_interval_ratio* {.importc: "gc_interval_ratio".}: cint
    gc_step_ratio* {.importc: "gc_step_ratio".}: cint
    gc_disabled* {.importc: "gc_disabled".}: bool #:1;
    gc_full* {.importc: "gc_full".}: bool #:1;
    is_generational_gc_mode* {.importc: "is_generational_gc_mode".}: bool #:1;
    out_of_memory* {.importc: "out_of_memory".}: bool #:1;
    majorgc_old_threshold* {.importc: "majorgc_old_threshold".}: csize
    mems* {.importc: "mems".}: ptr alloca_header
    symidx* {.importc: "symidx".}: sym
    name2sym* {.importc: "name2sym".}: ptr kh_n2s # symbol table 
                                                  ##ifdef ENABLE_DEBUG
    code_fetch_hook* {.importc: "code_fetch_hook".}: proc (mrb: ptr Tstate; 
        irep: ptr Tirep; pc: ptr Tcode; regs: ptr value) {.cdecl.}
    debug_op_hook* {.importc: "debug_op_hook".}: proc (mrb: ptr Tstate; 
        irep: ptr Tirep; pc: ptr Tcode; regs: ptr value) {.cdecl.} ##endif
    eException_class* {.importc: "eException_class".}: ptr RClass
    eStandardError_class* {.importc: "eStandardError_class".}: ptr RClass
    ud* {.importc: "ud".}: pointer # auxiliary data 
  Tfunc_t* = proc (mrb: PState; a3: value): value {.cdecl.}
  TRProc* {.importc: "RProc", header: "<mruby.h>".} = object 
    irep* {.importc: "irep".}: ptr Tirep #  MRB_OBJECT_HEADER;
                                        #  union {
    func* {.importc: "func".}: Tfunc_t #  } body;
    target_class* {.importc: "target_class".}: ptr RClass
    env* {.importc: "env".}: ptr TREnv
  

 


  






when defined(MRB_NAN_BOXING): 
  when defined(MRB_USE_FLOAT): 
    {.error: "---->> MRB_NAN_BOXING and MRB_USE_FLOAT conflict <<----".}
  when defined(MRB_INT64): 
    {.error: "---->> MRB_NAN_BOXING and MRB_INT64 conflict <<----".}
  
  type 
    Tvtype* = enum 
      MRB_TT_FALSE = 1,     #   1 
      MRB_TT_FREE,          #   2 
      MRB_TT_TRUE,          #   3 
      MRB_TT_FIXNUM,        #   4 
      MRB_TT_SYMBOL,        #   5 
      MRB_TT_UNDEF,         #   6 
      MRB_TT_FLOAT,         #   7 
      MRB_TT_CPTR,          #   8 
      MRB_TT_OBJECT,        #   9 
      MRB_TT_CLASS,         #  10 
      MRB_TT_MODULE,        #  11 
      MRB_TT_ICLASS,        #  12 
      MRB_TT_SCLASS,        #  13 
      MRB_TT_PROC,          #  14 
      MRB_TT_ARRAY,         #  15 
      MRB_TT_HASH,          #  16 
      MRB_TT_STRING,        #  17 
      MRB_TT_RANGE,         #  18 
      MRB_TT_EXCEPTION,     #  19 
      MRB_TT_FILE,          #  20 
      MRB_TT_ENV,           #  21 
      MRB_TT_DATA,          #  22 
      MRB_TT_FIBER,         #  23 
      MRB_TT_MAXDEFINE      #  24 
  const 
    MRB_TT_HAS_BASIC* = MRB_TT_OBJECT
  ##ifdef MRB_ENDIAN_BIG
  ##define MRB_ENDIAN_LOHI(a,b) a b
  ##else
  ##define MRB_ENDIAN_LOHI(a,b) b a
  ##endif
  #
  #typedef struct mrb_value {
  #  union {
  #    mrb_float f;
  #    union {
  #      void *p;
  #      struct {
  # MRB_ENDIAN_LOHI(
  #    uint32_t ttt;
  #          ,union {
  #     mrb_int i;
  #     mrb_sym sym;
  #   };
  #        )
  #      };
  #    } value;
  #  };
  #} mrb_value;
  #
  #/* value representation by nan-boxing:
  #    float : FFFFFFFFFFFFFFFF FFFFFFFFFFFFFFFF FFFFFFFFFFFFFFFF FFFFFFFFFFFFFFFF
  #    object: 111111111111TTTT TTPPPPPPPPPPPPPP PPPPPPPPPPPPPPPP PPPPPPPPPPPPPPPP
  #    int   : 1111111111110001 0000000000000000 IIIIIIIIIIIIIIII IIIIIIIIIIIIIIII
  #    sym   : 1111111111110001 0100000000000000 SSSSSSSSSSSSSSSS SSSSSSSSSSSSSSSS
  #  In order to get enough bit size to save TT, all pointers are shifted 2 bits
  #  in the right direction.
  # 
  ##define mrb_tt(o)       (((o).value.ttt & 0xfc000)>>14)
  ##define mrb_mktt(tt)    (0xfff00000|((tt)<<14))
  ##define mrb_type(o)     ((uint32_t)0xfff00000 < (o).value.ttt ? mrb_tt(o) : MRB_TT_FLOAT)
  ##define mrb_ptr(o)      ((void*)((((uintptr_t)0x3fffffffffff)&((uintptr_t)((o).value.p)))<<2))
  ##define mrb_float(o)    (o).f
  ##define MRB_SET_VALUE(o, tt, attr, v) do {\
  #  (o).value.ttt = mrb_mktt(tt);\
  #  switch (tt) {\
  #  case MRB_TT_FALSE:\
  #  case MRB_TT_TRUE:\
  #  case MRB_TT_UNDEF:\
  #  case MRB_TT_FIXNUM:\
  #  case MRB_TT_SYMBOL: (o).attr = (v); break;\
  #  default: (o).value.i = 0; (o).value.p = (void*)((uintptr_t)(o).value.p | (((uintptr_t)(v))>>2)); break;\
  #  }\
  #} while (0)
  #
  proc float_value*(mrb: ptr Tstate; f: Tfloat): value {.inline, cdecl.} = 
    var v: value
    if f != f: 
      v.value.ttt = 0x7FF80000
      v.value.i = 0
    else: 
      v.f = f
    return v

  template float_pool*(mrb, f: expr): expr = 
    float_value(mrb, f)

else: 
  type 
    Tvtype* = enum 
      MRB_TT_FALSE = 0,     #   0 
      MRB_TT_FREE,          #   1 
      MRB_TT_TRUE,          #   2 
      MRB_TT_FIXNUM,        #   3 
      MRB_TT_SYMBOL,        #   4 
      MRB_TT_UNDEF,         #   5 
      MRB_TT_FLOAT,         #   6 
      MRB_TT_CPTR,          #   7 
      MRB_TT_OBJECT,        #   8 
      MRB_TT_CLASS,         #   9 
      MRB_TT_MODULE,        #  10 
      MRB_TT_ICLASS,        #  11 
      MRB_TT_SCLASS,        #  12 
      MRB_TT_PROC,          #  13 
      MRB_TT_ARRAY,         #  14 
      MRB_TT_HASH,          #  15 
      MRB_TT_STRING,        #  16 
      MRB_TT_RANGE,         #  17 
      MRB_TT_EXCEPTION,     #  18 
      MRB_TT_FILE,          #  19 
      MRB_TT_ENV,           #  20 
      MRB_TT_DATA,          #  21 
      MRB_TT_FIBER,         #  22 
      MRB_TT_MAXDEFINE      #  23 
  when defined(MRB_WORD_BOXING): 
    const 
      MRB_TT_HAS_BASIC* = MRB_TT_FLOAT
    type 
      Tspecial_consts* = enum 
        MRB_Qnil = 0, MRB_Qfalse = 2, MRB_Qtrue = 4, MRB_Qundef = 6
    const 
      MRB_FIXNUM_FLAG* = 0x00000001
      MRB_FIXNUM_SHIFT* = 1
      MRB_SYMBOL_FLAG* = 0x0000000E
      MRB_SPECIAL_SHIFT* = 8
    #
    #typedef union mrb_value {
    #  union {
    #    void *p;
    #    struct {
    #      unsigned int i_flag : MRB_FIXNUM_SHIFT;
    #      mrb_int i : (sizeof(mrb_int) * CHAR_BIT - MRB_FIXNUM_SHIFT);
    #    };
    #    struct {
    #      unsigned int sym_flag : MRB_SPECIAL_SHIFT;
    #      int sym : (sizeof(mrb_sym) * CHAR_BIT);
    #    };
    #    struct RBasic *bp;
    #    struct RFloat *fp;
    #    struct RCptr *vp;
    #  } value;
    #  unsigned long w;
    #} mrb_value;
    #
    ##define mrb_ptr(o)      (o).value.p
    ##define mrb_float(o)    (o).value.fp->f
    #
    ##define MRB_SET_VALUE(o, ttt, attr, v) do {\
    #  (o).w = 0;\
    #  (o).attr = (v);\
    #  switch (ttt) {\
    #  case MRB_TT_FALSE:  (o).w = (v) ? MRB_Qfalse : MRB_Qnil; break;\
    #  case MRB_TT_TRUE:   (o).w = MRB_Qtrue; break;\
    #  case MRB_TT_UNDEF:  (o).w = MRB_Qundef; break;\
    #  case MRB_TT_FIXNUM: (o).value.i_flag = MRB_FIXNUM_FLAG; break;\
    #  case MRB_TT_SYMBOL: (o).value.sym_flag = MRB_SYMBOL_FLAG; break;\
    #  default:            if ((o).value.bp) (o).value.bp->tt = ttt; break;\
    #  }\
    #} while (0)
    #
    proc float_value*(mrb: ptr Tstate; f: Tfloat): value {.cdecl, 
        importc: "mrb_float_value", header: "<mruby.h>".}
    proc float_pool*(mrb: ptr Tstate; f: Tfloat): value {.cdecl, 
        importc: "mrb_float_pool", header: "<mruby.h>".}
  else: 
    const 
      MRB_TT_HAS_BASIC* = MRB_TT_OBJECT
    #
    
        
    #typedef struct mrb_value {
    #  union {
    #    mrb_float f;
    #    void *p;
    #    mrb_int i;
    #    mrb_sym sym;
    #  } value;
    #  enum mrb_vtype tt;
    #} mrb_value;
    #
    ##define mrb_type(o)     (o).tt
    ##define mrb_ptr(o)      (o).value.p
    ##define mrb_float(o)    (o).value.f
    #
    template MRB_SET_VALUE (o,ttt,attr,v): stmt =
      o.tt = ttt
      o.attr = v
      
    ##define MRB_SET_VALUE(o, ttt, attr, v) do {\
    #  (o).tt = ttt;\
    #  (o).attr = v;\
    #} while (0)
    #
    proc float_value*(mrb: ptr Tstate; f: Tfloat): value {.inline, cdecl.} = 
      var v: value
      #cast[void](mrb) # wat
      MRB_SET_VALUE(v, MRB_TT_FLOAT, f, f)
      return v

    template float_pool*(mrb, f: expr): expr = 
      float_value(mrb, f)

when defined(MRB_WORD_BOXING): 
  ##define mrb_cptr(o) (o).value.vp->p
  ##define mrb_fixnum_p(o) ((o).value.i_flag == MRB_FIXNUM_FLAG)
  ##define mrb_undef_p(o) ((o).w == MRB_Qundef)
  ##define mrb_nil_p(o)  ((o).w == MRB_Qnil)
  ##define mrb_bool(o)   ((o).w != MRB_Qnil && (o).w != MRB_Qfalse)
else: 
  template cptr*(o: expr): expr = 
    ptr(o)

  template fixnum_p*(o: expr): expr = 
    (type(o) == MRB_TT_FIXNUM)

  template undef_p*(o: expr): expr = 
    (type(o) == MRB_TT_UNDEF)

  template nil_p*(o: expr): expr = 
    (type(o) == MRB_TT_FALSE and not (o).value.i)

  discard """ template Tbool*(o: expr): expr = 
    (type(o) != MRB_TT_FALSE) """

##define mrb_fixnum(o) (o).value.i
##define mrb_symbol(o) (o).value.sym
##define mrb_float_p(o) (mrb_type(o) == MRB_TT_FLOAT)
##define mrb_symbol_p(o) (mrb_type(o) == MRB_TT_SYMBOL)
##define mrb_array_p(o) (mrb_type(o) == MRB_TT_ARRAY)
##define mrb_string_p(o) (mrb_type(o) == MRB_TT_STRING)
##define mrb_hash_p(o) (mrb_type(o) == MRB_TT_HASH)
##define mrb_cptr_p(o) (mrb_type(o) == MRB_TT_CPTR)
##define mrb_test(o)   mrb_bool(o)
#
##define MRB_OBJECT_HEADER \
#  enum mrb_vtype tt:8;\
#  uint32_t color:3;\
#  uint32_t flags:21;\
#  struct RClass *c;\
#  struct RBasic *gcnext
#
# white: 011, black: 100, gray: 000 
const 
  MRB_GC_GRAY* = 0
  MRB_GC_WHITE_A* = 1
  MRB_GC_WHITE_B* = 1 shl 1
  MRB_GC_BLACK* = 1 shl 2
##define MRB_GC_WHITE_B (1 << 1)
##define MRB_GC_BLACK (1 << 2)
const 
  MRB_GC_WHITES* = (MRB_GC_WHITE_A or MRB_GC_WHITE_B)
  MRB_GC_COLOR_MASK* = 7
template paint_gray*(o: expr): expr = 
  ((o).color = MRB_GC_GRAY)

template paint_black*(o: expr): expr = 
  ((o).color = MRB_GC_BLACK)

template paint_white*(o: expr): expr = 
  ((o).color = MRB_GC_WHITES)

##define paint_partial_white(s, o) ((o)->color = (s)->current_white_part)
##define is_gray(o) ((o)->color == MRB_GC_GRAY)
##define is_white(o) ((o)->color & MRB_GC_WHITES)
##define is_black(o) ((o)->color & MRB_GC_BLACK)
##define is_dead(s, o) (((o)->color & other_white_part(s) & MRB_GC_WHITES) || (o)->tt == MRB_TT_FREE)
##define flip_white_part(s) ((s)->current_white_part = other_white_part(s))
##define other_white_part(s) ((s)->current_white_part ^ MRB_GC_WHITES)


#
#* mruby/proc.h - Proc class
#*
#* See Copyright Notice in mruby.h
#

# aspec access 
template MRB_ASPEC_REQ*(a: expr): expr = 
  (((a) shr 18) and 0x0000001F)

template MRB_ASPEC_OPT*(a: expr): expr = 
  (((a) shr 13) and 0x0000001F)

template MRB_ASPEC_REST*(a: expr): expr = 
  ((a) and (1 shl 12))

template MRB_ASPEC_POST*(a: expr): expr = 
  (((a) shr 7) and 0x0000001F)

template MRB_ASPEC_KEY*(a: expr): expr = 
  (((a) shr 2) and 0x0000001F)

template MRB_ASPEC_KDICT*(a: expr): expr = 
  ((a) and (1 shl 1))

template MRB_ASPEC_BLOCK*(a: expr): expr = 
  ((a) and 1)

const 
  MRB_PROC_CFUNC* = 128
##define MRB_PROC_CFUNC_P(p) (((p)->flags & MRB_PROC_CFUNC) != 0)
const 
  MRB_PROC_STRICT* = 256
##define MRB_PROC_STRICT_P(p) (((p)->flags & MRB_PROC_STRICT) != 0)
template proc_ptr*(v: expr): expr = 
  (cast[ptr TRProc]((ptr(v))))

proc proc_new*(a2: ptr state; a3: ptr Tirep): ptr TRProc {.cdecl, 
    importc: "mrb_proc_new", header: "<mruby.h>".}
proc proc_new_cfunc*(a2: ptr state; a3: func_t): ptr TRProc {.cdecl, 
    importc: "mrb_proc_new_cfunc", header: "<mruby.h>".}
proc closure_new*(a2: ptr state; a3: ptr Tirep): ptr TRProc {.cdecl, 
    importc: "mrb_closure_new", header: "<mruby.h>".}
proc closure_new_cfunc*(mrb: ptr state; func: func_t; nlocals: cint): ptr TRProc {.
    cdecl, importc: "mrb_closure_new_cfunc", header: "<mruby.h>".}
proc proc_copy*(a: ptr TRProc; b: ptr TRProc) {.cdecl, 
    importc: "mrb_proc_copy", header: "<mruby.h>".}
discard """ import 
  "mruby/khash"
 """



  
  #  MRB_OBJECT_HEADER;
template basic_ptr*(v: expr): expr = 
  (cast[ptr TRBasic]((ptr(v))))

# obsolete macro mrb_basic; will be removed soon 
template basic*(v: expr): expr = 
  basic_ptr(v)

 
template obj_ptr*(v: expr): expr = 
  (cast[ptr TRObject]((ptr(v))))

# obsolete macro mrb_object; will be removed soon 
discard """ template object*(o: expr): expr = 
  obj_ptr(o) """

template immediate_p*(x: expr): expr = 
  (type(x) <= MRB_TT_CPTR)

template special_const_p*(x: expr): expr = 
  immediate_p(x)

when defined(MRB_WORD_BOXING): 
  type 
    TRFloat* {.importc: "RFloat", header: "<mruby.h>".} = object 
      f* {.importc: "f".}: Tfloat #  MRB_OBJECT_HEADER;
    
  type 
    TRCptr* {.importc: "RCptr", header: "<mruby.h>".} = object 
      p* {.importc: "p".}: pointer #  MRB_OBJECT_HEADER;
    
  proc vtype*(o: value): Tvtype {.inline, cdecl.} = 
    case o.w
    of MRB_Qfalse, MRB_Qnil: 
      return MRB_TT_FALSE
    of MRB_Qtrue: 
      return MRB_TT_TRUE
    of MRB_Qundef: 
      return MRB_TT_UNDEF
    if o.value.i_flag == MRB_FIXNUM_FLAG: 
      return MRB_TT_FIXNUM
    if o.value.sym_flag == MRB_SYMBOL_FLAG: 
      return MRB_TT_SYMBOL
    return o.value.bp.tt

proc fixnum_value*(i: Tint): value {.inline, cdecl.} = 
  var v: value
  MRB_SET_VALUE(v, MRB_TT_FIXNUM, value.i, i)
  return v

proc symbol_value*(i: Tsym): value {.inline, cdecl.} = 
  var v: value
  MRB_SET_VALUE(v, MRB_TT_SYMBOL, value.sym, i)
  return v

proc obj_value*(p: pointer): value {.inline, cdecl.} = 
  var v: value
  var b: ptr TRBasic = cast[ptr TRBasic](p)
  MRB_SET_VALUE(v, b.tt, value.p, p)
  return v

when defined(MRB_WORD_BOXING): 
  proc cptr_value*(mrb: ptr Tstate; p: pointer): value {.cdecl, 
      importc: "mrb_cptr_value", header: "<mruby.h>".}
else: 
  proc cptr_value*(mrb: ptr Tstate; p: pointer): value {.inline, cdecl.} = 
    var v: value
    cast[nil](mrb)
    MRB_SET_VALUE(v, MRB_TT_CPTR, value.p, p)
    return v

# obsolete macros; will be removed 
const 
  MRB_TT_VOIDP* = MRB_TT_CPTR
template voidp_value*(m, p: expr): expr = 
  cptr_value((m), (p))

template voidp*(o: expr): expr = 
  cptr(o)

template voidp_p*(o: expr): expr = 
  cptr_p(o)

proc false_value*(): value {.inline, cdecl.} = 
  var v: value
  MRB_SET_VALUE(v, MRB_TT_FALSE, value.i, 1)
  return v

proc nil_value*(): value {.inline, cdecl.} = 
  var v: value
  MRB_SET_VALUE(v, MRB_TT_FALSE, value.i, 0)
  return v

proc true_value*(): value {.inline, cdecl.} = 
  var v: value
  MRB_SET_VALUE(v, MRB_TT_TRUE, value.i, 1)
  return v

proc undef_value*(): value {.inline, cdecl.} = 
  var v: value
  MRB_SET_VALUE(v, MRB_TT_UNDEF, value.i, 0)
  return v

proc bool_value*(boolean: Tbool): value {.inline, cdecl.} = 
  var v: value
  MRB_SET_VALUE(v, if boolean: MRB_TT_TRUE else: MRB_TT_FALSE, value.i, 1)
  return v




when not(defined(MRB_GC_ARENA_SIZE)): 
  const 
    MRB_GC_ARENA_SIZE* = 100

discard """ when not(defined(MRUBY_H)): 
  const 
    MRUBY_H* = true
  ##if defined(__cplusplus)
  #extern "C" {
  ##endif
  import 
    "mrbconf", "mruby/value", "mruby/version"
 """




type 
  Tgc_state* = enum 
    GC_STATE_NONE = 0, GC_STATE_MARK, GC_STATE_SWEEP
 
  
proc define_class*(a2: ptr Tstate; a3: cstring; a4: ptr TRClass): ptr TRClass {.
    cdecl, importc: "mrb_define_class", header: "<mruby.h>".}
proc define_module*(a2: ptr Tstate; a3: cstring): ptr TRClass {.cdecl, 
    importc: "mrb_define_module", header: "<mruby.h>".}
proc singleton_class*(a2: ptr Tstate; a3: value): value {.cdecl, 
    importc: "mrb_singleton_class", header: "<mruby.h>".}
proc include_module*(a2: ptr Tstate; a3: ptr TRClass; a4: ptr TRClass) {.
    cdecl, importc: "mrb_include_module", header: "<mruby.h>".}
proc define_method*(a2: ptr Tstate; a3: ptr TRClass; a4: cstring; a5: Tfunc_t; 
                    a6: Taspec) {.cdecl, importc: "mrb_define_method", 
                                  header: "<mruby.h>".}
proc define_class_method*(a2: ptr Tstate; a3: ptr TRClass; a4: cstring; 
                          a5: Tfunc_t; a6: Taspec) {.cdecl, 
    importc: "mrb_define_class_method", header: "<mruby.h>".}
proc define_singleton_method*(a2: ptr Tstate; a3: ptr RObject; a4: cstring; 
                              a5: Tfunc_t; a6: Taspec) {.cdecl, 
    importc: "mrb_define_singleton_method", header: "<mruby.h>".}
proc define_module_function*(a2: ptr Tstate; a3: ptr TRClass; a4: cstring; 
                             a5: Tfunc_t; a6: Taspec) {.cdecl, 
    importc: "mrb_define_module_function", header: "<mruby.h>".}
proc define_const*(a2: ptr Tstate; a3: ptr TRClass; name: cstring; a5: value) {.
    cdecl, importc: "mrb_define_const", header: "<mruby.h>".}
proc undef_method*(a2: ptr Tstate; a3: ptr TRClass; a4: cstring) {.cdecl, 
    importc: "mrb_undef_method", header: "<mruby.h>".}
proc undef_class_method*(a2: ptr Tstate; a3: ptr TRClass; a4: cstring) {.
    cdecl, importc: "mrb_undef_class_method", header: "<mruby.h>".}
proc obj_new*(mrb: ptr Tstate; c: ptr TRClass; argc: cint; argv: ptr value): value {.
    cdecl, importc: "mrb_obj_new", header: "<mruby.h>".}
template class_new_instance*(mrb, argc, argv, c: expr): expr = 
  obj_new(mrb, c, argc, argv)

proc instance_new*(mrb: ptr Tstate; cv: value): value {.cdecl, 
    importc: "mrb_instance_new", header: "<mruby.h>".}
proc class_new*(mrb: ptr Tstate; super: ptr TRClass): ptr TRClass {.cdecl, 
    importc: "mrb_class_new", header: "<mruby.h>".}
proc module_new*(mrb: ptr Tstate): ptr TRClass {.cdecl, 
    importc: "mrb_module_new", header: "<mruby.h>".}
proc class_defined*(mrb: ptr Tstate; name: cstring): bool {.cdecl, 
    importc: "mrb_class_defined", header: "<mruby.h>".}
proc class_get*(mrb: ptr Tstate; name: cstring): ptr TRClass {.cdecl, 
    importc: "mrb_class_get", header: "<mruby.h>".}
proc class_get_under*(mrb: ptr Tstate; outer: ptr TRClass; name: cstring): ptr TRClass {.
    cdecl, importc: "mrb_class_get_under", header: "<mruby.h>".}
proc module_get*(mrb: ptr Tstate; name: cstring): ptr TRClass {.cdecl, 
    importc: "mrb_module_get", header: "<mruby.h>".}
proc module_get_under*(mrb: ptr Tstate; outer: ptr TRClass; name: cstring): ptr TRClass {.
    cdecl, importc: "mrb_module_get_under", header: "<mruby.h>".}
proc obj_dup*(mrb: ptr Tstate; obj: value): value {.cdecl, 
    importc: "mrb_obj_dup", header: "<mruby.h>".}
proc check_to_integer*(mrb: ptr Tstate; val: value; method: cstring): value {.
    cdecl, importc: "mrb_check_to_integer", header: "<mruby.h>".}
proc obj_respond_to*(mrb: ptr Tstate; c: ptr TRClass; mid: Tsym): bool {.cdecl, 
    importc: "mrb_obj_respond_to", header: "<mruby.h>".}
proc define_class_under*(mrb: ptr Tstate; outer: ptr TRClass; name: cstring; 
                         super: ptr TRClass): ptr TRClass {.cdecl, 
    importc: "mrb_define_class_under", header: "<mruby.h>".}
proc define_module_under*(mrb: ptr Tstate; outer: ptr TRClass; name: cstring): ptr TRClass {.
    cdecl, importc: "mrb_define_module_under", header: "<mruby.h>".}
# required arguments 
##define MRB_ARGS_REQ(n)     ((mrb_aspec)((n)&0x1f) << 18)
# optional arguments 
##define MRB_ARGS_OPT(n)     ((mrb_aspec)((n)&0x1f) << 13)
# mandatory and optinal arguments 
template MRB_ARGS_ARG*(n1, n2: expr): expr = 
  (MRB_ARGS_REQ(n1) or MRB_ARGS_OPT(n2))

# rest argument 
##define MRB_ARGS_REST()     ((mrb_aspec)(1 << 12))
# required arguments after rest 
##define MRB_ARGS_POST(n)    ((mrb_aspec)((n)&0x1f) << 7)
# keyword arguments (n of keys, kdict) 
##define MRB_ARGS_KEY(n1,n2) ((mrb_aspec)((((n1)&0x1f) << 2) | ((n2)?(1<<1):0)))
# block argument 
template MRB_ARGS_BLOCK*(): expr = 
  (cast[Taspec](1))

# accept any number of arguments 
template MRB_ARGS_ANY*(): expr = 
  ARGS_REST()

# accept no arguments 
template MRB_ARGS_NONE*(): expr = 
  (cast[Taspec](0))

# compatibility macros; will be removed 
template ARGS_REQ*(n: expr): expr = 
  MRB_ARGS_REQ(n)

template ARGS_OPT*(n: expr): expr = 
  MRB_ARGS_OPT(n)

template ARGS_REST*(): expr = 
  MRB_ARGS_REST()

template ARGS_POST*(n: expr): expr = 
  MRB_ARGS_POST()

template ARGS_KEY*(n1, n2: expr): expr = 
  MRB_ARGS_KEY(n1, n2)

template ARGS_BLOCK*(): expr = 
  MRB_ARGS_BLOCK()

template ARGS_ANY*(): expr = 
  MRB_ARGS_ANY()

template ARGS_NONE*(): expr = 
  MRB_ARGS_NONE()

proc get_args*(mrb: ptr Tstate; format: cstring): cint {.varargs, cdecl, 
    importc: "mrb_get_args", header: "<mruby.h>".}
proc funcall*(a2: ptr Tstate; a3: value; a4: cstring; a5: cint): value {.
    varargs, cdecl, importc: "mrb_funcall", header: "<mruby.h>".}
proc funcall_argv*(a2: ptr Tstate; a3: value; a4: Tsym; a5: cint; a6: ptr value): value {.
    cdecl, importc: "mrb_funcall_argv", header: "<mruby.h>".}
proc funcall_with_block*(a2: ptr Tstate; a3: value; a4: Tsym; a5: cint; 
                         a6: ptr value; a7: value): value {.cdecl, 
    importc: "mrb_funcall_with_block", header: "<mruby.h>".}
proc intern_cstr*(a2: ptr Tstate; a3: cstring): Tsym {.cdecl, 
    importc: "mrb_intern_cstr", header: "<mruby.h>".}
proc intern*(a2: ptr Tstate; a3: cstring; a4: csize): Tsym {.cdecl, 
    importc: "mrb_intern", header: "<mruby.h>".}
proc intern_static*(a2: ptr Tstate; a3: cstring; a4: csize): Tsym {.cdecl, 
    importc: "mrb_intern_static", header: "<mruby.h>".}
template intern_lit*(mrb, lit: expr): expr = 
  intern_static(mrb, (lit), sizeof((lit)) + 1)

proc intern_str*(a2: ptr Tstate; a3: value): Tsym {.cdecl, 
    importc: "mrb_intern_str", header: "<mruby.h>".}
proc check_intern_cstr*(a2: ptr Tstate; a3: cstring): value {.cdecl, 
    importc: "mrb_check_intern_cstr", header: "<mruby.h>".}
proc check_intern*(a2: ptr Tstate; a3: cstring; a4: csize): value {.cdecl, 
    importc: "mrb_check_intern", header: "<mruby.h>".}
proc check_intern_str*(a2: ptr Tstate; a3: value): value {.cdecl, 
    importc: "mrb_check_intern_str", header: "<mruby.h>".}
proc sym2name*(a2: ptr Tstate; a3: Tsym): cstring {.cdecl, 
    importc: "mrb_sym2name", header: "<mruby.h>".}
proc sym2name_len*(a2: ptr Tstate; a3: Tsym; a4: ptr csize): cstring {.cdecl, 
    importc: "mrb_sym2name_len", header: "<mruby.h>".}
proc sym2str*(a2: ptr Tstate; a3: Tsym): value {.cdecl, importc: "mrb_sym2str", 
    header: "<mruby.h>".}
proc malloc*(a2: ptr Tstate; a3: csize): pointer {.cdecl, 
    importc: "mrb_malloc", header: "<mruby.h>".}
# raise RuntimeError if no mem 
proc calloc*(a2: ptr Tstate; a3: csize; a4: csize): pointer {.cdecl, 
    importc: "mrb_calloc", header: "<mruby.h>".}
# ditto 
proc realloc*(a2: ptr Tstate; a3: pointer; a4: csize): pointer {.cdecl, 
    importc: "mrb_realloc", header: "<mruby.h>".}
# ditto 
proc realloc_simple*(a2: ptr Tstate; a3: pointer; a4: csize): pointer {.
    cdecl, importc: "mrb_realloc_simple", header: "<mruby.h>".}
# return NULL if no memory available 
proc malloc_simple*(a2: ptr Tstate; a3: csize): pointer {.cdecl, 
    importc: "mrb_malloc_simple", header: "<mruby.h>".}
# return NULL if no memory available 
proc obj_alloc*(a2: ptr Tstate; a3: vtype; a4: ptr TRClass): ptr TRBasic {.
    cdecl, importc: "mrb_obj_alloc", header: "<mruby.h>".}
proc free*(a2: ptr Tstate; a3: pointer) {.cdecl, importc: "mrb_free", 
    header: "<mruby.h>".}
proc str_new*(mrb: ptr Tstate; p: cstring; len: csize): value {.cdecl, 
    importc: "mrb_str_new", header: "<mruby.h>".}
proc str_new_cstr*(a2: ptr Tstate; a3: cstring): value {.cdecl, 
    importc: "mrb_str_new_cstr", header: "<mruby.h>".}
proc str_new_static*(mrb: ptr Tstate; p: cstring; len: csize): value {.cdecl, 
    importc: "mrb_str_new_static", header: "<mruby.h>".}
template str_new_lit*(mrb, lit: expr): expr = 
  str_new_static(mrb, (lit), sizeof((lit)) + 1)

proc open*(): ptr Tstate {.cdecl, importc: "mrb_open", header: "<mruby.h>".}
proc open_allocf*(a2: Tallocf; ud: pointer): ptr Tstate {.cdecl, 
    importc: "mrb_open_allocf", header: "<mruby.h>".}
proc close*(a2: ptr Tstate) {.cdecl, importc: "mrb_close", header: "<mruby.h>".}
proc top_self*(a2: ptr Tstate): value {.cdecl, importc: "mrb_top_self", 
    header: "<mruby.h>".}
proc run*(a2: ptr Tstate; a3: ptr TRProc; a4: value): value {.cdecl, 
    importc: "mrb_run", header: "<mruby.h>".}
proc context_run*(a2: ptr Tstate; a3: ptr TRProc; a4: value; a5: cuint): value {.
    cdecl, importc: "mrb_context_run", header: "<mruby.h>".}
proc p*(a2: ptr Tstate; a3: value) {.cdecl, importc: "mrb_p", 
                                     header: "<mruby.h>".}
proc obj_id*(obj: value): int {.cdecl, importc: "mrb_obj_id", 
                                header: "<mruby.h>".}
proc obj_to_sym*(mrb: ptr Tstate; name: value): Tsym {.cdecl, 
    importc: "mrb_obj_to_sym", header: "<mruby.h>".}
proc obj_eq*(a2: ptr Tstate; a3: value; a4: value): bool {.cdecl, 
    importc: "mrb_obj_eq", header: "<mruby.h>".}
proc obj_equal*(a2: ptr Tstate; a3: value; a4: value): bool {.cdecl, 
    importc: "mrb_obj_equal", header: "<mruby.h>".}
proc equal*(mrb: ptr Tstate; obj1: value; obj2: value): bool {.cdecl, 
    importc: "mrb_equal", header: "<mruby.h>".}
proc Integer*(mrb: ptr Tstate; val: value): value {.cdecl, 
    importc: "mrb_Integer", header: "<mruby.h>".}
proc Float*(mrb: ptr Tstate; val: value): value {.cdecl, importc: "mrb_Float", 
    header: "<mruby.h>".}
proc inspect*(mrb: ptr Tstate; obj: value): value {.cdecl, 
    importc: "mrb_inspect", header: "<mruby.h>".}
proc eql*(mrb: ptr Tstate; obj1: value; obj2: value): bool {.cdecl, 
    importc: "mrb_eql", header: "<mruby.h>".}
proc garbage_collect*(a2: ptr Tstate) {.cdecl, importc: "mrb_garbage_collect", 
    header: "<mruby.h>".}
proc full_gc*(a2: ptr Tstate) {.cdecl, importc: "mrb_full_gc", 
                                header: "<mruby.h>".}
proc incremental_gc*(a2: ptr Tstate) {.cdecl, importc: "mrb_incremental_gc", 
    header: "<mruby.h>".}
proc gc_arena_save*(a2: ptr Tstate): cint {.cdecl, 
    importc: "mrb_gc_arena_save", header: "<mruby.h>".}
proc gc_arena_restore*(a2: ptr Tstate; a3: cint) {.cdecl, 
    importc: "mrb_gc_arena_restore", header: "<mruby.h>".}
proc gc_mark*(a2: ptr Tstate; a3: ptr TRBasic) {.cdecl, 
    importc: "mrb_gc_mark", header: "<mruby.h>".}
template gc_mark_value*(mrb, val: expr): stmt = 
while true: 
  if type(val) >= MRB_TT_HAS_BASIC: gc_mark((mrb), basic_ptr(val))
  if not 0: break 

proc field_write_barrier*(a2: ptr Tstate; a3: ptr TRBasic; a4: ptr TRBasic) {.
    cdecl, importc: "mrb_field_write_barrier", header: "<mruby.h>".}
template field_write_barrier_value*(mrb, obj, val: expr): stmt = 
while true: 
  if (val.tt >= MRB_TT_HAS_BASIC): 
    field_write_barrier((mrb), (obj), basic_ptr(val))
  if not 0: break 

proc write_barrier*(a2: ptr Tstate; a3: ptr TRBasic) {.cdecl, 
    importc: "mrb_write_barrier", header: "<mruby.h>".}
proc check_convert_type*(mrb: ptr Tstate; val: value; type: vtype; 
                         tname: cstring; method: cstring): value {.cdecl, 
    importc: "mrb_check_convert_type", header: "<mruby.h>".}
proc any_to_s*(mrb: ptr Tstate; obj: value): value {.cdecl, 
    importc: "mrb_any_to_s", header: "<mruby.h>".}
proc obj_classname*(mrb: ptr Tstate; obj: value): cstring {.cdecl, 
    importc: "mrb_obj_classname", header: "<mruby.h>".}
proc obj_class*(mrb: ptr Tstate; obj: value): ptr TRClass {.cdecl, 
    importc: "mrb_obj_class", header: "<mruby.h>".}
proc class_path*(mrb: ptr Tstate; c: ptr TRClass): value {.cdecl, 
    importc: "mrb_class_path", header: "<mruby.h>".}
proc convert_type*(mrb: ptr Tstate; val: value; type: vtype; tname: cstring; 
                   method: cstring): value {.cdecl, 
    importc: "mrb_convert_type", header: "<mruby.h>".}
proc obj_is_kind_of*(mrb: ptr Tstate; obj: value; c: ptr TRClass): bool {.
    cdecl, importc: "mrb_obj_is_kind_of", header: "<mruby.h>".}
proc obj_inspect*(mrb: ptr Tstate; self: value): value {.cdecl, 
    importc: "mrb_obj_inspect", header: "<mruby.h>".}
proc obj_clone*(mrb: ptr Tstate; self: value): value {.cdecl, 
    importc: "mrb_obj_clone", header: "<mruby.h>".}
# need to include <ctype.h> to use these macros 
when not(defined(ISPRINT)): 
  ##define ISASCII(c) isascii((int)(unsigned char)(c))
  template ISASCII*(c: expr): expr = 
    1

  template ISPRINT*(c: expr): expr = 
    (ISASCII(c) and isprint((int)(unsigned, char)(c)))

  template ISSPACE*(c: expr): expr = 
    (ISASCII(c) and isspace((int)(unsigned, char)(c)))

  template ISUPPER*(c: expr): expr = 
    (ISASCII(c) and isupper((int)(unsigned, char)(c)))

  template ISLOWER*(c: expr): expr = 
    (ISASCII(c) and islower((int)(unsigned, char)(c)))

  template ISALNUM*(c: expr): expr = 
    (ISASCII(c) and isalnum((int)(unsigned, char)(c)))

  template ISALPHA*(c: expr): expr = 
    (ISASCII(c) and isalpha((int)(unsigned, char)(c)))

  template ISDIGIT*(c: expr): expr = 
    (ISASCII(c) and isdigit((int)(unsigned, char)(c)))

  template ISXDIGIT*(c: expr): expr = 
    (ISASCII(c) and isxdigit((int)(unsigned, char)(c)))

  template TOUPPER*(c: expr): expr = 
    (if ISASCII(c): toupper((int)(unsigned, char)(c)) else: (c))

  template TOLOWER*(c: expr): expr = 
    (if ISASCII(c): tolower((int)(unsigned, char)(c)) else: (c))

proc exc_new*(mrb: ptr Tstate; c: ptr TRClass; ptr: cstring; len: clong): value {.
    cdecl, importc: "mrb_exc_new", header: "<mruby.h>".}
proc exc_raise*(mrb: ptr Tstate; exc: value) {.cdecl, 
    importc: "mrb_exc_raise", header: "<mruby.h>".}
proc raise*(mrb: ptr Tstate; c: ptr TRClass; msg: cstring) {.cdecl, 
    importc: "mrb_raise", header: "<mruby.h>".}
proc raisef*(mrb: ptr Tstate; c: ptr TRClass; fmt: cstring) {.varargs, cdecl, 
    importc: "mrb_raisef", header: "<mruby.h>".}
proc name_error*(mrb: ptr Tstate; id: Tsym; fmt: cstring) {.varargs, cdecl, 
    importc: "mrb_name_error", header: "<mruby.h>".}
proc warn*(mrb: ptr Tstate; fmt: cstring) {.varargs, cdecl, 
    importc: "mrb_warn", header: "<mruby.h>".}
proc bug*(mrb: ptr Tstate; fmt: cstring) {.varargs, cdecl, importc: "mrb_bug", 
    header: "<mruby.h>".}
proc print_backtrace*(mrb: ptr Tstate) {.cdecl, 
    importc: "mrb_print_backtrace", header: "<mruby.h>".}
proc print_error*(mrb: ptr Tstate) {.cdecl, importc: "mrb_print_error", 
                                     header: "<mruby.h>".}
# macros to get typical exception objects
#   note:
#   + those E_* macros requires mrb_state* variable named mrb.
#   + exception objects obtained from those macros are local to mrb
#
const 
  E_RUNTIME_ERROR* = (class_get(mrb, "RuntimeError"))
  E_TYPE_ERROR* = (class_get(mrb, "TypeError"))
  E_ARGUMENT_ERROR* = (class_get(mrb, "ArgumentError"))
  E_INDEX_ERROR* = (class_get(mrb, "IndexError"))
  E_RANGE_ERROR* = (class_get(mrb, "RangeError"))
  E_NAME_ERROR* = (class_get(mrb, "NameError"))
  E_NOMETHOD_ERROR* = (class_get(mrb, "NoMethodError"))
  E_SCRIPT_ERROR* = (class_get(mrb, "ScriptError"))
  E_SYNTAX_ERROR* = (class_get(mrb, "SyntaxError"))
  E_LOCALJUMP_ERROR* = (class_get(mrb, "LocalJumpError"))
  E_REGEXP_ERROR* = (class_get(mrb, "RegexpError"))
  E_NOTIMP_ERROR* = (class_get(mrb, "NotImplementedError"))
  E_FLOATDOMAIN_ERROR* = (class_get(mrb, "FloatDomainError"))
  E_KEY_ERROR* = (class_get(mrb, "KeyError"))
proc yield*(mrb: ptr Tstate; b: value; arg: value): value {.cdecl, 
    importc: "mrb_yield", header: "<mruby.h>".}
proc yield_argv*(mrb: ptr Tstate; b: value; argc: cint; argv: ptr value): value {.
    cdecl, importc: "mrb_yield_argv", header: "<mruby.h>".}
proc gc_protect*(mrb: ptr Tstate; obj: value) {.cdecl, 
    importc: "mrb_gc_protect", header: "<mruby.h>".}
proc to_int*(mrb: ptr Tstate; val: value): value {.cdecl, 
    importc: "mrb_to_int", header: "<mruby.h>".}
proc check_type*(mrb: ptr Tstate; x: value; t: vtype) {.cdecl, 
    importc: "mrb_check_type", header: "<mruby.h>".}
type 
  Tcall_type* {.size: sizeof(cint).} = enum 
    CALL_PUBLIC, CALL_FCALL, CALL_VCALL, CALL_TYPE_MAX
proc define_alias*(mrb: ptr Tstate; klass: ptr TRClass; name1: cstring; 
                   name2: cstring) {.cdecl, importc: "mrb_define_alias", 
                                     header: "<mruby.h>".}
proc class_name*(mrb: ptr Tstate; klass: ptr TRClass): cstring {.cdecl, 
    importc: "mrb_class_name", header: "<mruby.h>".}
proc define_global_const*(mrb: ptr Tstate; name: cstring; val: value) {.cdecl, 
    importc: "mrb_define_global_const", header: "<mruby.h>".}
proc attr_get*(mrb: ptr Tstate; obj: value; id: Tsym): value {.cdecl, 
    importc: "mrb_attr_get", header: "<mruby.h>".}
proc respond_to*(mrb: ptr Tstate; obj: value; mid: Tsym): bool {.cdecl, 
    importc: "mrb_respond_to", header: "<mruby.h>".}
proc obj_is_instance_of*(mrb: ptr Tstate; obj: value; c: ptr TRClass): bool {.
    cdecl, importc: "mrb_obj_is_instance_of", header: "<mruby.h>".}
# memory pool implementation 
proc pool_open*(a2: ptr Tstate): ptr Tpool {.cdecl, importc: "mrb_pool_open", 
    header: "<mruby.h>".}
proc pool_close*(a2: ptr Tpool) {.cdecl, importc: "mrb_pool_close", 
                                  header: "<mruby.h>".}
proc pool_alloc*(a2: ptr Tpool; a3: csize): pointer {.cdecl, 
    importc: "mrb_pool_alloc", header: "<mruby.h>".}
proc pool_realloc*(a2: ptr Tpool; a3: pointer; oldlen: csize; newlen: csize): pointer {.
    cdecl, importc: "mrb_pool_realloc", header: "<mruby.h>".}
proc pool_can_realloc*(a2: ptr Tpool; a3: pointer; a4: csize): bool {.cdecl, 
    importc: "mrb_pool_can_realloc", header: "<mruby.h>".}
proc alloca*(mrb: ptr Tstate; a3: csize): pointer {.cdecl, 
    importc: "mrb_alloca", header: "<mruby.h>".}

when ismainmodule:
  
  let state = mruby.open()
  


