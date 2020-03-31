type
  DTContext* = pointer
type
  duk_int_t* = cint
  duk_uint_t* = cuint
  duk_uint8_t* = uint8
  duk_int8_t* = int8
  duk_uint16_t* = uint16
  duk_int16_t* = int16
  duk_uint32_t* = uint32
  duk_int32_t* = int32
  duk_uint64_t* = uint64
  duk_int64_t* = int64
  duk_small_int_t* = cint
  duk_small_uint_t* = cuint
  duk_bool_t* = cint
  duk_idx_t* = duk_int_t
  duk_uidx_t* = duk_uint_t
  duk_uarridx_t* = duk_uint_t
  duk_errcode_t* = duk_int_t
  duk_codepoint_t* = duk_int_t
  duk_ucodepoint_t* = duk_uint_t
  duk_float_t* = cfloat
  duk_double_t* = cdouble
  duk_size_t* = cint
  duk_ret_t* = cint

import strutils
const sourcePath = currentSourcePath().split({'\\', '/'})[0..^2].join("/")
{.passC: "-I\"" & sourcePath & "/../vendor/duktape\"".}
const headerduktape = sourcePath & "/../vendor/duktape/duktape.h"
const headerconsole = sourcePath & "/../vendor/duktape/extras/console/duk_console.h"
const headerprintalert = sourcePath & "/../vendor/duktape/extras/print-alert/duk_print_alert.h"
{.compile: "../vendor/duktape/duktape.c".}
{.compile: "../vendor/duktape/extras/console/duk_console.c".}
{.compile: "../vendor/duktape/extras/print-alert/duk_print_alert.c".}
const
  DUK_VERSION* = 20201
  DUK_DEBUG_PROTOCOL_VERSION* = 2
  DUK_API_ENTRY_STACK* = 64
  DUK_TYPE_MIN* = 0
  DUK_TYPE_NONE* = 0
  DUK_TYPE_UNDEFINED* = 1
  DUK_TYPE_NULL* = 2
  DUK_TYPE_BOOLEAN* = 3
  DUK_TYPE_NUMBER* = 4
  DUK_TYPE_STRING* = 5
  DUK_TYPE_OBJECT* = 6
  DUK_TYPE_BUFFER* = 7
  DUK_TYPE_POINTER* = 8
  DUK_TYPE_LIGHTFUNC* = 9
  DUK_TYPE_MAX* = 9
  DUK_HINT_NONE* = 0
  DUK_HINT_STRING* = 1
  DUK_HINT_NUMBER* = 2
  DUK_ERR_NONE* = 0
  DUK_ERR_ERROR* = 1
  DUK_ERR_EVAL_ERROR* = 2
  DUK_ERR_RANGE_ERROR* = 3
  DUK_ERR_REFERENCE_ERROR* = 4
  DUK_ERR_SYNTAX_ERROR* = 5
  DUK_ERR_TYPE_ERROR* = 6
  DUK_ERR_URI_ERROR* = 7
  DUK_EXEC_SUCCESS* = 0
  DUK_EXEC_ERROR* = 1
  DUK_LEVEL_DEBUG* = 0
  DUK_LEVEL_DDEBUG* = 1
  DUK_LEVEL_DDDEBUG* = 2
  DUK_BUFOBJ_ARRAYBUFFER* = 0
  DUK_BUFOBJ_NODEJS_BUFFER* = 1
  DUK_BUFOBJ_DATAVIEW* = 2
  DUK_BUFOBJ_INT8ARRAY* = 3
  DUK_BUFOBJ_UINT8ARRAY* = 4
  DUK_BUFOBJ_UINT8CLAMPEDARRAY* = 5
  DUK_BUFOBJ_INT16ARRAY* = 6
  DUK_BUFOBJ_UINT16ARRAY* = 7
  DUK_BUFOBJ_INT32ARRAY* = 8
  DUK_BUFOBJ_UINT32ARRAY* = 9
  DUK_BUFOBJ_FLOAT32ARRAY* = 10
  DUK_BUFOBJ_FLOAT64ARRAY* = 11
  DUK_BUF_MODE_FIXED* = 0
  DUK_BUF_MODE_DYNAMIC* = 1
  DUK_BUF_MODE_DONTCARE* = 2
  DUK_DATE_MSEC_SECOND* = 1000
  DUK_DATE_MAX_ECMA_YEAR* = 275760
  DUK_DATE_IDX_YEAR* = 0
  DUK_DATE_IDX_MONTH* = 1
  DUK_DATE_IDX_DAY* = 2
  DUK_DATE_IDX_HOUR* = 3
  DUK_DATE_IDX_MINUTE* = 4
  DUK_DATE_IDX_SECOND* = 5
  DUK_DATE_IDX_MILLISECOND* = 6
  DUK_DATE_IDX_WEEKDAY* = 7
  DUK_DATE_IDX_NUM_PARTS* = 8
  DUK_DATE_FLAG_VALUE_SHIFT* = 12

type
  duk_thread_state* {.importc: "duk_thread_state", header: headerduktape, bycopy.} = object

  duk_memory_functions* {.importc: "duk_memory_functions", header: headerduktape,
                         bycopy.} = object

  duk_function_list_entry* {.importc: "duk_function_list_entry",
                            header: headerduktape, bycopy.} = object

  duk_number_list_entry* {.importc: "duk_number_list_entry", header: headerduktape,
                          bycopy.} = object

  duk_time_components* {.importc: "duk_time_components", header: headerduktape,
                        bycopy.} = object

  duk_c_function* = proc (ctx: DTContext): duk_ret_t {.stdcall.}
  duk_alloc_function* = proc (udata: pointer; size: duk_size_t): pointer {.stdcall.}
  duk_realloc_function* = proc (udata: pointer; `ptr`: pointer; size: duk_size_t): pointer {.
      stdcall.}
  duk_free_function* = proc (udata: pointer; `ptr`: pointer) {.stdcall.}
  duk_fatal_function* = proc (udata: pointer; msg: cstring) {.stdcall.}
  duk_decode_char_function* = proc (udata: pointer; codepoint: duk_codepoint_t) {.
      stdcall.}
  duk_map_char_function* = proc (udata: pointer; codepoint: duk_codepoint_t): duk_codepoint_t {.
      stdcall.}
  duk_safe_call_function* = proc (ctx: DTContext; udata: pointer): duk_ret_t {.
      stdcall.}
  duk_debug_read_function* = proc (udata: pointer; buffer: cstring; length: duk_size_t): duk_size_t {.
      stdcall.}
  duk_debug_write_function* = proc (udata: pointer; buffer: cstring; length: duk_size_t): duk_size_t {.
      stdcall.}
  duk_debug_peek_function* = proc (udata: pointer): duk_size_t {.stdcall.}
  duk_debug_read_flush_function* = proc (udata: pointer) {.stdcall.}
  duk_debug_write_flush_function* = proc (udata: pointer) {.stdcall.}
  duk_debug_request_function* = proc (ctx: DTContext; udata: pointer;
                                   nvalues: duk_idx_t): duk_idx_t {.stdcall.}
  duk_debug_detached_function* = proc (ctx: DTContext; udata: pointer) {.stdcall.}

proc duk_create_heap*(alloc_func: duk_alloc_function;
                     realloc_func: duk_realloc_function;
                     free_func: duk_free_function; heap_udata: pointer;
                     fatal_handler: duk_fatal_function): DTContext {.stdcall,
    importc: "duk_create_heap", header: headerduktape.}
proc duk_destroy_heap*(ctx: DTContext) {.stdcall, importc: "duk_destroy_heap",
    header: headerduktape.}
proc duk_suspend*(ctx: DTContext; state: ptr duk_thread_state) {.stdcall,
    importc: "duk_suspend", header: headerduktape.}
proc duk_resume*(ctx: DTContext; state: ptr duk_thread_state) {.stdcall,
    importc: "duk_resume", header: headerduktape.}
proc duk_alloc_raw*(ctx: DTContext; size: duk_size_t): pointer {.stdcall,
    importc: "duk_alloc_raw", header: headerduktape.}
proc duk_free_raw*(ctx: DTContext; `ptr`: pointer) {.stdcall,
    importc: "duk_free_raw", header: headerduktape.}
proc duk_realloc_raw*(ctx: DTContext; `ptr`: pointer; size: duk_size_t): pointer {.
    stdcall, importc: "duk_realloc_raw", header: headerduktape.}
proc duk_alloc*(ctx: DTContext; size: duk_size_t): pointer {.stdcall,
    importc: "duk_alloc", header: headerduktape.}
proc duk_free*(ctx: DTContext; `ptr`: pointer) {.stdcall, importc: "duk_free",
    header: headerduktape.}
proc duk_realloc*(ctx: DTContext; `ptr`: pointer; size: duk_size_t): pointer {.
    stdcall, importc: "duk_realloc", header: headerduktape.}
proc duk_get_memory_functions*(ctx: DTContext;
                              out_funcs: ptr duk_memory_functions) {.stdcall,
    importc: "duk_get_memory_functions", header: headerduktape.}
proc duk_gc*(ctx: DTContext; flags: duk_uint_t) {.stdcall, importc: "duk_gc",
    header: headerduktape.}
proc duk_throw_raw*(ctx: DTContext) {.stdcall, importc: "duk_throw_raw",
                                        header: headerduktape.}
proc duk_fatal_raw*(ctx: DTContext; err_msg: cstring) {.stdcall,
    importc: "duk_fatal_raw", header: headerduktape.}
proc duk_error_raw*(ctx: DTContext; err_code: duk_errcode_t; filename: cstring;
                   line: duk_int_t; fmt: cstring) {.varargs, stdcall,
    importc: "duk_error_raw", header: headerduktape.}
proc duk_is_strict_call*(ctx: DTContext): duk_bool_t {.stdcall,
    importc: "duk_is_strict_call", header: headerduktape.}
proc duk_is_constructor_call*(ctx: DTContext): duk_bool_t {.stdcall,
    importc: "duk_is_constructor_call", header: headerduktape.}
proc duk_normalize_index*(ctx: DTContext; idx: duk_idx_t): duk_idx_t {.stdcall,
    importc: "duk_normalize_index", header: headerduktape.}
proc duk_require_normalize_index*(ctx: DTContext; idx: duk_idx_t): duk_idx_t {.
    stdcall, importc: "duk_require_normalize_index", header: headerduktape.}
proc duk_is_valid_index*(ctx: DTContext; idx: duk_idx_t): duk_bool_t {.stdcall,
    importc: "duk_is_valid_index", header: headerduktape.}
proc duk_require_valid_index*(ctx: DTContext; idx: duk_idx_t) {.stdcall,
    importc: "duk_require_valid_index", header: headerduktape.}
proc duk_get_top*(ctx: DTContext): duk_idx_t {.stdcall, importc: "duk_get_top",
    header: headerduktape.}
proc duk_set_top*(ctx: DTContext; idx: duk_idx_t) {.stdcall,
    importc: "duk_set_top", header: headerduktape.}
proc duk_get_top_index*(ctx: DTContext): duk_idx_t {.stdcall,
    importc: "duk_get_top_index", header: headerduktape.}
proc duk_require_top_index*(ctx: DTContext): duk_idx_t {.stdcall,
    importc: "duk_require_top_index", header: headerduktape.}
proc duk_check_stack*(ctx: DTContext; extra: duk_idx_t): duk_bool_t {.stdcall,
    importc: "duk_check_stack", header: headerduktape.}
proc duk_require_stack*(ctx: DTContext; extra: duk_idx_t) {.stdcall,
    importc: "duk_require_stack", header: headerduktape.}
proc duk_check_stack_top*(ctx: DTContext; top: duk_idx_t): duk_bool_t {.stdcall,
    importc: "duk_check_stack_top", header: headerduktape.}
proc duk_require_stack_top*(ctx: DTContext; top: duk_idx_t) {.stdcall,
    importc: "duk_require_stack_top", header: headerduktape.}
proc duk_swap*(ctx: DTContext; idx1: duk_idx_t; idx2: duk_idx_t) {.stdcall,
    importc: "duk_swap", header: headerduktape.}
proc duk_swap_top*(ctx: DTContext; idx: duk_idx_t) {.stdcall,
    importc: "duk_swap_top", header: headerduktape.}
proc duk_dup*(ctx: DTContext; from_idx: duk_idx_t) {.stdcall, importc: "duk_dup",
    header: headerduktape.}
proc duk_dup_top*(ctx: DTContext) {.stdcall, importc: "duk_dup_top",
                                      header: headerduktape.}
proc duk_insert*(ctx: DTContext; to_idx: duk_idx_t) {.stdcall,
    importc: "duk_insert", header: headerduktape.}
proc duk_replace*(ctx: DTContext; to_idx: duk_idx_t) {.stdcall,
    importc: "duk_replace", header: headerduktape.}
proc duk_copy*(ctx: DTContext; from_idx: duk_idx_t; to_idx: duk_idx_t) {.stdcall,
    importc: "duk_copy", header: headerduktape.}
proc duk_remove*(ctx: DTContext; idx: duk_idx_t) {.stdcall,
    importc: "duk_remove", header: headerduktape.}
proc duk_xcopymove_raw*(to_ctx: DTContext; from_ctx: DTContext;
                       count: duk_idx_t; is_copy: duk_bool_t) {.stdcall,
    importc: "duk_xcopymove_raw", header: headerduktape.}
proc duk_push_undefined*(ctx: DTContext) {.stdcall,
    importc: "duk_push_undefined", header: headerduktape.}
proc duk_push_null*(ctx: DTContext) {.stdcall, importc: "duk_push_null",
                                        header: headerduktape.}
proc duk_push_boolean*(ctx: DTContext; val: duk_bool_t) {.stdcall,
    importc: "duk_push_boolean", header: headerduktape.}
proc duk_push_true*(ctx: DTContext) {.stdcall, importc: "duk_push_true",
                                        header: headerduktape.}
proc duk_push_false*(ctx: DTContext) {.stdcall, importc: "duk_push_false",
    header: headerduktape.}
proc duk_push_number*(ctx: DTContext; val: duk_double_t) {.stdcall,
    importc: "duk_push_number", header: headerduktape.}
proc duk_push_nan*(ctx: DTContext) {.stdcall, importc: "duk_push_nan",
                                       header: headerduktape.}
proc duk_push_int*(ctx: DTContext; val: duk_int_t) {.stdcall,
    importc: "duk_push_int", header: headerduktape.}
proc duk_push_uint*(ctx: DTContext; val: duk_uint_t) {.stdcall,
    importc: "duk_push_uint", header: headerduktape.}
proc duk_push_string*(ctx: DTContext; str: cstring): cstring {.stdcall,
    importc: "duk_push_string", header: headerduktape.}
proc duk_push_lstring*(ctx: DTContext; str: cstring; len: duk_size_t): cstring {.
    stdcall, importc: "duk_push_lstring", header: headerduktape.}
proc duk_push_pointer*(ctx: DTContext; p: pointer) {.stdcall,
    importc: "duk_push_pointer", header: headerduktape.}
proc duk_push_sprintf*(ctx: DTContext; fmt: cstring): cstring {.varargs, stdcall,
    importc: "duk_push_sprintf", header: headerduktape.}
proc duk_push_this*(ctx: DTContext) {.stdcall, importc: "duk_push_this",
                                        header: headerduktape.}
proc duk_push_current_function*(ctx: DTContext) {.stdcall,
    importc: "duk_push_current_function", header: headerduktape.}
proc duk_push_current_thread*(ctx: DTContext) {.stdcall,
    importc: "duk_push_current_thread", header: headerduktape.}
proc duk_push_global_object*(ctx: DTContext) {.stdcall,
    importc: "duk_push_global_object", header: headerduktape.}
proc duk_push_heap_stash*(ctx: DTContext) {.stdcall,
    importc: "duk_push_heap_stash", header: headerduktape.}
proc duk_push_global_stash*(ctx: DTContext) {.stdcall,
    importc: "duk_push_global_stash", header: headerduktape.}
proc duk_push_thread_stash*(ctx: DTContext; target_ctx: DTContext) {.
    stdcall, importc: "duk_push_thread_stash", header: headerduktape.}
proc duk_push_object*(ctx: DTContext): duk_idx_t {.stdcall,
    importc: "duk_push_object", header: headerduktape.}
proc duk_push_bare_object*(ctx: DTContext): duk_idx_t {.stdcall,
    importc: "duk_push_bare_object", header: headerduktape.}
proc duk_push_array*(ctx: DTContext): duk_idx_t {.stdcall,
    importc: "duk_push_array", header: headerduktape.}
proc duk_push_c_function*(ctx: DTContext; `func`: duk_c_function;
                         nargs: duk_idx_t): duk_idx_t {.stdcall,
    importc: "duk_push_c_function", header: headerduktape.}
proc duk_push_c_lightfunc*(ctx: DTContext; `func`: duk_c_function;
                          nargs: duk_idx_t; length: duk_idx_t; magic: duk_int_t): duk_idx_t {.
    stdcall, importc: "duk_push_c_lightfunc", header: headerduktape.}
proc duk_push_thread_raw*(ctx: DTContext; flags: duk_uint_t): duk_idx_t {.
    stdcall, importc: "duk_push_thread_raw", header: headerduktape.}
proc duk_push_proxy*(ctx: DTContext; proxy_flags: duk_uint_t): duk_idx_t {.
    stdcall, importc: "duk_push_proxy", header: headerduktape.}
proc duk_push_error_object_raw*(ctx: DTContext; err_code: duk_errcode_t;
                               filename: cstring; line: duk_int_t; fmt: cstring): duk_idx_t {.
    varargs, stdcall, importc: "duk_push_error_object_raw", header: headerduktape.}
proc duk_push_buffer_raw*(ctx: DTContext; size: duk_size_t;
                         flags: duk_small_uint_t): pointer {.stdcall,
    importc: "duk_push_buffer_raw", header: headerduktape.}
proc duk_push_buffer_object*(ctx: DTContext; idx_buffer: duk_idx_t;
                            byte_offset: duk_size_t; byte_length: duk_size_t;
                            flags: duk_uint_t) {.stdcall,
    importc: "duk_push_buffer_object", header: headerduktape.}
proc duk_push_heapptr*(ctx: DTContext; `ptr`: pointer): duk_idx_t {.stdcall,
    importc: "duk_push_heapptr", header: headerduktape.}
proc duk_pop*(ctx: DTContext) {.stdcall, importc: "duk_pop",
                                  header: headerduktape.}
proc duk_pop_n*(ctx: DTContext; count: duk_idx_t) {.stdcall,
    importc: "duk_pop_n", header: headerduktape.}
proc duk_pop_2*(ctx: DTContext) {.stdcall, importc: "duk_pop_2",
                                    header: headerduktape.}
proc duk_pop_3*(ctx: DTContext) {.stdcall, importc: "duk_pop_3",
                                    header: headerduktape.}
proc duk_get_type*(ctx: DTContext; idx: duk_idx_t): duk_int_t {.stdcall,
    importc: "duk_get_type", header: headerduktape.}
proc duk_check_type*(ctx: DTContext; idx: duk_idx_t; `type`: duk_int_t): duk_bool_t {.
    stdcall, importc: "duk_check_type", header: headerduktape.}
proc duk_get_type_mask*(ctx: DTContext; idx: duk_idx_t): duk_uint_t {.stdcall,
    importc: "duk_get_type_mask", header: headerduktape.}
proc duk_check_type_mask*(ctx: DTContext; idx: duk_idx_t; mask: duk_uint_t): duk_bool_t {.
    stdcall, importc: "duk_check_type_mask", header: headerduktape.}
proc duk_is_undefined*(ctx: DTContext; idx: duk_idx_t): duk_bool_t {.stdcall,
    importc: "duk_is_undefined", header: headerduktape.}
proc duk_is_null*(ctx: DTContext; idx: duk_idx_t): duk_bool_t {.stdcall,
    importc: "duk_is_null", header: headerduktape.}
proc duk_is_boolean*(ctx: DTContext; idx: duk_idx_t): duk_bool_t {.stdcall,
    importc: "duk_is_boolean", header: headerduktape.}
proc duk_is_number*(ctx: DTContext; idx: duk_idx_t): duk_bool_t {.stdcall,
    importc: "duk_is_number", header: headerduktape.}
proc duk_is_nan*(ctx: DTContext; idx: duk_idx_t): duk_bool_t {.stdcall,
    importc: "duk_is_nan", header: headerduktape.}
proc duk_is_string*(ctx: DTContext; idx: duk_idx_t): duk_bool_t {.stdcall,
    importc: "duk_is_string", header: headerduktape.}
proc duk_is_object*(ctx: DTContext; idx: duk_idx_t): duk_bool_t {.stdcall,
    importc: "duk_is_object", header: headerduktape.}
proc duk_is_buffer*(ctx: DTContext; idx: duk_idx_t): duk_bool_t {.stdcall,
    importc: "duk_is_buffer", header: headerduktape.}
proc duk_is_buffer_data*(ctx: DTContext; idx: duk_idx_t): duk_bool_t {.stdcall,
    importc: "duk_is_buffer_data", header: headerduktape.}
proc duk_is_pointer*(ctx: DTContext; idx: duk_idx_t): duk_bool_t {.stdcall,
    importc: "duk_is_pointer", header: headerduktape.}
proc duk_is_lightfunc*(ctx: DTContext; idx: duk_idx_t): duk_bool_t {.stdcall,
    importc: "duk_is_lightfunc", header: headerduktape.}
proc duk_is_symbol*(ctx: DTContext; idx: duk_idx_t): duk_bool_t {.stdcall,
    importc: "duk_is_symbol", header: headerduktape.}
proc duk_is_array*(ctx: DTContext; idx: duk_idx_t): duk_bool_t {.stdcall,
    importc: "duk_is_array", header: headerduktape.}
proc duk_is_function*(ctx: DTContext; idx: duk_idx_t): duk_bool_t {.stdcall,
    importc: "duk_is_function", header: headerduktape.}
proc duk_is_c_function*(ctx: DTContext; idx: duk_idx_t): duk_bool_t {.stdcall,
    importc: "duk_is_c_function", header: headerduktape.}
proc duk_is_ecmascript_function*(ctx: DTContext; idx: duk_idx_t): duk_bool_t {.
    stdcall, importc: "duk_is_ecmascript_function", header: headerduktape.}
proc duk_is_bound_function*(ctx: DTContext; idx: duk_idx_t): duk_bool_t {.
    stdcall, importc: "duk_is_bound_function", header: headerduktape.}
proc duk_is_thread*(ctx: DTContext; idx: duk_idx_t): duk_bool_t {.stdcall,
    importc: "duk_is_thread", header: headerduktape.}
proc duk_is_constructable*(ctx: DTContext; idx: duk_idx_t): duk_bool_t {.stdcall,
    importc: "duk_is_constructable", header: headerduktape.}
proc duk_is_dynamic_buffer*(ctx: DTContext; idx: duk_idx_t): duk_bool_t {.
    stdcall, importc: "duk_is_dynamic_buffer", header: headerduktape.}
proc duk_is_fixed_buffer*(ctx: DTContext; idx: duk_idx_t): duk_bool_t {.stdcall,
    importc: "duk_is_fixed_buffer", header: headerduktape.}
proc duk_is_external_buffer*(ctx: DTContext; idx: duk_idx_t): duk_bool_t {.
    stdcall, importc: "duk_is_external_buffer", header: headerduktape.}
proc duk_get_error_code*(ctx: DTContext; idx: duk_idx_t): duk_errcode_t {.
    stdcall, importc: "duk_get_error_code", header: headerduktape.}
proc duk_get_boolean*(ctx: DTContext; idx: duk_idx_t): duk_bool_t {.stdcall,
    importc: "duk_get_boolean", header: headerduktape.}
proc duk_get_number*(ctx: DTContext; idx: duk_idx_t): duk_double_t {.stdcall,
    importc: "duk_get_number", header: headerduktape.}
proc duk_get_int*(ctx: DTContext; idx: duk_idx_t): duk_int_t {.stdcall,
    importc: "duk_get_int", header: headerduktape.}
proc duk_get_uint*(ctx: DTContext; idx: duk_idx_t): duk_uint_t {.stdcall,
    importc: "duk_get_uint", header: headerduktape.}
proc duk_get_string*(ctx: DTContext; idx: duk_idx_t): cstring {.stdcall,
    importc: "duk_get_string", header: headerduktape.}
proc duk_get_lstring*(ctx: DTContext; idx: duk_idx_t; out_len: ptr duk_size_t): cstring {.
    stdcall, importc: "duk_get_lstring", header: headerduktape.}
proc duk_get_buffer*(ctx: DTContext; idx: duk_idx_t; out_size: ptr duk_size_t): pointer {.
    stdcall, importc: "duk_get_buffer", header: headerduktape.}
proc duk_get_buffer_data*(ctx: DTContext; idx: duk_idx_t;
                         out_size: ptr duk_size_t): pointer {.stdcall,
    importc: "duk_get_buffer_data", header: headerduktape.}
proc duk_get_pointer*(ctx: DTContext; idx: duk_idx_t): pointer {.stdcall,
    importc: "duk_get_pointer", header: headerduktape.}
proc duk_get_c_function*(ctx: DTContext; idx: duk_idx_t): duk_c_function {.
    stdcall, importc: "duk_get_c_function", header: headerduktape.}
proc duk_get_context*(ctx: DTContext; idx: duk_idx_t): DTContext {.stdcall,
    importc: "duk_get_context", header: headerduktape.}
proc duk_get_heapptr*(ctx: DTContext; idx: duk_idx_t): pointer {.stdcall,
    importc: "duk_get_heapptr", header: headerduktape.}
proc duk_get_boolean_default*(ctx: DTContext; idx: duk_idx_t;
                             def_value: duk_bool_t): duk_bool_t {.stdcall,
    importc: "duk_get_boolean_default", header: headerduktape.}
proc duk_get_number_default*(ctx: DTContext; idx: duk_idx_t;
                            def_value: duk_double_t): duk_double_t {.stdcall,
    importc: "duk_get_number_default", header: headerduktape.}
proc duk_get_int_default*(ctx: DTContext; idx: duk_idx_t; def_value: duk_int_t): duk_int_t {.
    stdcall, importc: "duk_get_int_default", header: headerduktape.}
proc duk_get_uint_default*(ctx: DTContext; idx: duk_idx_t; def_value: duk_uint_t): duk_uint_t {.
    stdcall, importc: "duk_get_uint_default", header: headerduktape.}
proc duk_get_string_default*(ctx: DTContext; idx: duk_idx_t; def_value: cstring): cstring {.
    stdcall, importc: "duk_get_string_default", header: headerduktape.}
proc duk_get_lstring_default*(ctx: DTContext; idx: duk_idx_t;
                             out_len: ptr duk_size_t; def_ptr: cstring;
                             def_len: duk_size_t): cstring {.stdcall,
    importc: "duk_get_lstring_default", header: headerduktape.}
proc duk_get_buffer_default*(ctx: DTContext; idx: duk_idx_t;
                            out_size: ptr duk_size_t; def_ptr: pointer;
                            def_len: duk_size_t): pointer {.stdcall,
    importc: "duk_get_buffer_default", header: headerduktape.}
proc duk_get_buffer_data_default*(ctx: DTContext; idx: duk_idx_t;
                                 out_size: ptr duk_size_t; def_ptr: pointer;
                                 def_len: duk_size_t): pointer {.stdcall,
    importc: "duk_get_buffer_data_default", header: headerduktape.}
proc duk_get_pointer_default*(ctx: DTContext; idx: duk_idx_t; def_value: pointer): pointer {.
    stdcall, importc: "duk_get_pointer_default", header: headerduktape.}
proc duk_get_c_function_default*(ctx: DTContext; idx: duk_idx_t;
                                def_value: duk_c_function): duk_c_function {.
    stdcall, importc: "duk_get_c_function_default", header: headerduktape.}
proc duk_get_context_default*(ctx: DTContext; idx: duk_idx_t;
                             def_value: DTContext): DTContext {.stdcall,
    importc: "duk_get_context_default", header: headerduktape.}
proc duk_get_heapptr_default*(ctx: DTContext; idx: duk_idx_t; def_value: pointer): pointer {.
    stdcall, importc: "duk_get_heapptr_default", header: headerduktape.}
proc duk_opt_boolean*(ctx: DTContext; idx: duk_idx_t; def_value: duk_bool_t): duk_bool_t {.
    stdcall, importc: "duk_opt_boolean", header: headerduktape.}
proc duk_opt_number*(ctx: DTContext; idx: duk_idx_t; def_value: duk_double_t): duk_double_t {.
    stdcall, importc: "duk_opt_number", header: headerduktape.}
proc duk_opt_int*(ctx: DTContext; idx: duk_idx_t; def_value: duk_int_t): duk_int_t {.
    stdcall, importc: "duk_opt_int", header: headerduktape.}
proc duk_opt_uint*(ctx: DTContext; idx: duk_idx_t; def_value: duk_uint_t): duk_uint_t {.
    stdcall, importc: "duk_opt_uint", header: headerduktape.}
proc duk_opt_string*(ctx: DTContext; idx: duk_idx_t; def_ptr: cstring): cstring {.
    stdcall, importc: "duk_opt_string", header: headerduktape.}
proc duk_opt_lstring*(ctx: DTContext; idx: duk_idx_t; out_len: ptr duk_size_t;
                     def_ptr: cstring; def_len: duk_size_t): cstring {.stdcall,
    importc: "duk_opt_lstring", header: headerduktape.}
proc duk_opt_buffer*(ctx: DTContext; idx: duk_idx_t; out_size: ptr duk_size_t;
                    def_ptr: pointer; def_size: duk_size_t): pointer {.stdcall,
    importc: "duk_opt_buffer", header: headerduktape.}
proc duk_opt_buffer_data*(ctx: DTContext; idx: duk_idx_t;
                         out_size: ptr duk_size_t; def_ptr: pointer;
                         def_size: duk_size_t): pointer {.stdcall,
    importc: "duk_opt_buffer_data", header: headerduktape.}
proc duk_opt_pointer*(ctx: DTContext; idx: duk_idx_t; def_value: pointer): pointer {.
    stdcall, importc: "duk_opt_pointer", header: headerduktape.}
proc duk_opt_c_function*(ctx: DTContext; idx: duk_idx_t;
                        def_value: duk_c_function): duk_c_function {.stdcall,
    importc: "duk_opt_c_function", header: headerduktape.}
proc duk_opt_context*(ctx: DTContext; idx: duk_idx_t; def_value: DTContext): DTContext {.
    stdcall, importc: "duk_opt_context", header: headerduktape.}
proc duk_opt_heapptr*(ctx: DTContext; idx: duk_idx_t; def_value: pointer): pointer {.
    stdcall, importc: "duk_opt_heapptr", header: headerduktape.}
proc duk_require_undefined*(ctx: DTContext; idx: duk_idx_t) {.stdcall,
    importc: "duk_require_undefined", header: headerduktape.}
proc duk_require_null*(ctx: DTContext; idx: duk_idx_t) {.stdcall,
    importc: "duk_require_null", header: headerduktape.}
proc duk_require_boolean*(ctx: DTContext; idx: duk_idx_t): duk_bool_t {.stdcall,
    importc: "duk_require_boolean", header: headerduktape.}
proc duk_require_number*(ctx: DTContext; idx: duk_idx_t): duk_double_t {.stdcall,
    importc: "duk_require_number", header: headerduktape.}
proc duk_require_int*(ctx: DTContext; idx: duk_idx_t): duk_int_t {.stdcall,
    importc: "duk_require_int", header: headerduktape.}
proc duk_require_uint*(ctx: DTContext; idx: duk_idx_t): duk_uint_t {.stdcall,
    importc: "duk_require_uint", header: headerduktape.}
proc duk_require_string*(ctx: DTContext; idx: duk_idx_t): cstring {.stdcall,
    importc: "duk_require_string", header: headerduktape.}
proc duk_require_lstring*(ctx: DTContext; idx: duk_idx_t;
                         out_len: ptr duk_size_t): cstring {.stdcall,
    importc: "duk_require_lstring", header: headerduktape.}
proc duk_require_object*(ctx: DTContext; idx: duk_idx_t) {.stdcall,
    importc: "duk_require_object", header: headerduktape.}
proc duk_require_buffer*(ctx: DTContext; idx: duk_idx_t;
                        out_size: ptr duk_size_t): pointer {.stdcall,
    importc: "duk_require_buffer", header: headerduktape.}
proc duk_require_buffer_data*(ctx: DTContext; idx: duk_idx_t;
                             out_size: ptr duk_size_t): pointer {.stdcall,
    importc: "duk_require_buffer_data", header: headerduktape.}
proc duk_require_pointer*(ctx: DTContext; idx: duk_idx_t): pointer {.stdcall,
    importc: "duk_require_pointer", header: headerduktape.}
proc duk_require_c_function*(ctx: DTContext; idx: duk_idx_t): duk_c_function {.
    stdcall, importc: "duk_require_c_function", header: headerduktape.}
proc duk_require_context*(ctx: DTContext; idx: duk_idx_t): DTContext {.
    stdcall, importc: "duk_require_context", header: headerduktape.}
proc duk_require_function*(ctx: DTContext; idx: duk_idx_t) {.stdcall,
    importc: "duk_require_function", header: headerduktape.}
proc duk_require_heapptr*(ctx: DTContext; idx: duk_idx_t): pointer {.stdcall,
    importc: "duk_require_heapptr", header: headerduktape.}
proc duk_to_undefined*(ctx: DTContext; idx: duk_idx_t) {.stdcall,
    importc: "duk_to_undefined", header: headerduktape.}
proc duk_to_null*(ctx: DTContext; idx: duk_idx_t) {.stdcall,
    importc: "duk_to_null", header: headerduktape.}
proc duk_to_boolean*(ctx: DTContext; idx: duk_idx_t): duk_bool_t {.stdcall,
    importc: "duk_to_boolean", header: headerduktape.}
proc duk_to_number*(ctx: DTContext; idx: duk_idx_t): duk_double_t {.stdcall,
    importc: "duk_to_number", header: headerduktape.}
proc duk_to_int*(ctx: DTContext; idx: duk_idx_t): duk_int_t {.stdcall,
    importc: "duk_to_int", header: headerduktape.}
proc duk_to_uint*(ctx: DTContext; idx: duk_idx_t): duk_uint_t {.stdcall,
    importc: "duk_to_uint", header: headerduktape.}
proc duk_to_int32*(ctx: DTContext; idx: duk_idx_t): duk_int32_t {.stdcall,
    importc: "duk_to_int32", header: headerduktape.}
proc duk_to_uint32*(ctx: DTContext; idx: duk_idx_t): duk_uint32_t {.stdcall,
    importc: "duk_to_uint32", header: headerduktape.}
proc duk_to_uint16*(ctx: DTContext; idx: duk_idx_t): duk_uint16_t {.stdcall,
    importc: "duk_to_uint16", header: headerduktape.}
proc duk_to_string*(ctx: DTContext; idx: duk_idx_t): cstring {.stdcall,
    importc: "duk_to_string", header: headerduktape.}
proc duk_to_lstring*(ctx: DTContext; idx: duk_idx_t; out_len: ptr duk_size_t): cstring {.
    stdcall, importc: "duk_to_lstring", header: headerduktape.}
proc duk_to_buffer_raw*(ctx: DTContext; idx: duk_idx_t;
                       out_size: ptr duk_size_t; flags: duk_uint_t): pointer {.
    stdcall, importc: "duk_to_buffer_raw", header: headerduktape.}
proc duk_to_pointer*(ctx: DTContext; idx: duk_idx_t): pointer {.stdcall,
    importc: "duk_to_pointer", header: headerduktape.}
proc duk_to_object*(ctx: DTContext; idx: duk_idx_t) {.stdcall,
    importc: "duk_to_object", header: headerduktape.}
proc duk_to_primitive*(ctx: DTContext; idx: duk_idx_t; hint: duk_int_t) {.stdcall,
    importc: "duk_to_primitive", header: headerduktape.}
proc duk_safe_to_lstring*(ctx: DTContext; idx: duk_idx_t;
                         out_len: ptr duk_size_t): cstring {.stdcall,
    importc: "duk_safe_to_lstring", header: headerduktape.}
proc duk_get_length*(ctx: DTContext; idx: duk_idx_t): duk_size_t {.stdcall,
    importc: "duk_get_length", header: headerduktape.}
proc duk_set_length*(ctx: DTContext; idx: duk_idx_t; len: duk_size_t) {.stdcall,
    importc: "duk_set_length", header: headerduktape.}
proc duk_base64_encode*(ctx: DTContext; idx: duk_idx_t): cstring {.stdcall,
    importc: "duk_base64_encode", header: headerduktape.}
proc duk_base64_decode*(ctx: DTContext; idx: duk_idx_t) {.stdcall,
    importc: "duk_base64_decode", header: headerduktape.}
proc duk_hex_encode*(ctx: DTContext; idx: duk_idx_t): cstring {.stdcall,
    importc: "duk_hex_encode", header: headerduktape.}
proc duk_hex_decode*(ctx: DTContext; idx: duk_idx_t) {.stdcall,
    importc: "duk_hex_decode", header: headerduktape.}
proc duk_json_encode*(ctx: DTContext; idx: duk_idx_t): cstring {.stdcall,
    importc: "duk_json_encode", header: headerduktape.}
proc duk_json_decode*(ctx: DTContext; idx: duk_idx_t) {.stdcall,
    importc: "duk_json_decode", header: headerduktape.}
proc duk_buffer_to_string*(ctx: DTContext; idx: duk_idx_t): cstring {.stdcall,
    importc: "duk_buffer_to_string", header: headerduktape.}
proc duk_resize_buffer*(ctx: DTContext; idx: duk_idx_t; new_size: duk_size_t): pointer {.
    stdcall, importc: "duk_resize_buffer", header: headerduktape.}
proc duk_steal_buffer*(ctx: DTContext; idx: duk_idx_t; out_size: ptr duk_size_t): pointer {.
    stdcall, importc: "duk_steal_buffer", header: headerduktape.}
proc duk_config_buffer*(ctx: DTContext; idx: duk_idx_t; `ptr`: pointer;
                       len: duk_size_t) {.stdcall, importc: "duk_config_buffer",
                                        header: headerduktape.}
proc duk_get_prop*(ctx: DTContext; obj_idx: duk_idx_t): duk_bool_t {.stdcall,
    importc: "duk_get_prop", header: headerduktape.}
proc duk_get_prop_string*(ctx: DTContext; obj_idx: duk_idx_t; key: cstring): duk_bool_t {.
    stdcall, importc: "duk_get_prop_string", header: headerduktape.}
proc duk_get_prop_lstring*(ctx: DTContext; obj_idx: duk_idx_t; key: cstring;
                          key_len: duk_size_t): duk_bool_t {.stdcall,
    importc: "duk_get_prop_lstring", header: headerduktape.}
proc duk_get_prop_index*(ctx: DTContext; obj_idx: duk_idx_t;
                        arr_idx: duk_uarridx_t): duk_bool_t {.stdcall,
    importc: "duk_get_prop_index", header: headerduktape.}
proc duk_get_prop_heapptr*(ctx: DTContext; obj_idx: duk_idx_t; `ptr`: pointer): duk_bool_t {.
    stdcall, importc: "duk_get_prop_heapptr", header: headerduktape.}
proc duk_put_prop*(ctx: DTContext; obj_idx: duk_idx_t): duk_bool_t {.stdcall,
    importc: "duk_put_prop", header: headerduktape.}
proc duk_put_prop_string*(ctx: DTContext; obj_idx: duk_idx_t; key: cstring): duk_bool_t {.
    stdcall, importc: "duk_put_prop_string", header: headerduktape.}
proc duk_put_prop_lstring*(ctx: DTContext; obj_idx: duk_idx_t; key: cstring;
                          key_len: duk_size_t): duk_bool_t {.stdcall,
    importc: "duk_put_prop_lstring", header: headerduktape.}
proc duk_put_prop_index*(ctx: DTContext; obj_idx: duk_idx_t;
                        arr_idx: duk_uarridx_t): duk_bool_t {.stdcall,
    importc: "duk_put_prop_index", header: headerduktape.}
proc duk_put_prop_heapptr*(ctx: DTContext; obj_idx: duk_idx_t; `ptr`: pointer): duk_bool_t {.
    stdcall, importc: "duk_put_prop_heapptr", header: headerduktape.}
proc duk_del_prop*(ctx: DTContext; obj_idx: duk_idx_t): duk_bool_t {.stdcall,
    importc: "duk_del_prop", header: headerduktape.}
proc duk_del_prop_string*(ctx: DTContext; obj_idx: duk_idx_t; key: cstring): duk_bool_t {.
    stdcall, importc: "duk_del_prop_string", header: headerduktape.}
proc duk_del_prop_lstring*(ctx: DTContext; obj_idx: duk_idx_t; key: cstring;
                          key_len: duk_size_t): duk_bool_t {.stdcall,
    importc: "duk_del_prop_lstring", header: headerduktape.}
proc duk_del_prop_index*(ctx: DTContext; obj_idx: duk_idx_t;
                        arr_idx: duk_uarridx_t): duk_bool_t {.stdcall,
    importc: "duk_del_prop_index", header: headerduktape.}
proc duk_del_prop_heapptr*(ctx: DTContext; obj_idx: duk_idx_t; `ptr`: pointer): duk_bool_t {.
    stdcall, importc: "duk_del_prop_heapptr", header: headerduktape.}
proc duk_has_prop*(ctx: DTContext; obj_idx: duk_idx_t): duk_bool_t {.stdcall,
    importc: "duk_has_prop", header: headerduktape.}
proc duk_has_prop_string*(ctx: DTContext; obj_idx: duk_idx_t; key: cstring): duk_bool_t {.
    stdcall, importc: "duk_has_prop_string", header: headerduktape.}
proc duk_has_prop_lstring*(ctx: DTContext; obj_idx: duk_idx_t; key: cstring;
                          key_len: duk_size_t): duk_bool_t {.stdcall,
    importc: "duk_has_prop_lstring", header: headerduktape.}
proc duk_has_prop_index*(ctx: DTContext; obj_idx: duk_idx_t;
                        arr_idx: duk_uarridx_t): duk_bool_t {.stdcall,
    importc: "duk_has_prop_index", header: headerduktape.}
proc duk_has_prop_heapptr*(ctx: DTContext; obj_idx: duk_idx_t; `ptr`: pointer): duk_bool_t {.
    stdcall, importc: "duk_has_prop_heapptr", header: headerduktape.}
proc duk_get_prop_desc*(ctx: DTContext; obj_idx: duk_idx_t; flags: duk_uint_t) {.
    stdcall, importc: "duk_get_prop_desc", header: headerduktape.}
proc duk_def_prop*(ctx: DTContext; obj_idx: duk_idx_t; flags: duk_uint_t) {.
    stdcall, importc: "duk_def_prop", header: headerduktape.}
proc duk_get_global_string*(ctx: DTContext; key: cstring): duk_bool_t {.stdcall,
    importc: "duk_get_global_string", header: headerduktape.}
proc duk_get_global_lstring*(ctx: DTContext; key: cstring; key_len: duk_size_t): duk_bool_t {.
    stdcall, importc: "duk_get_global_lstring", header: headerduktape.}
proc duk_put_global_string*(ctx: DTContext; key: cstring): duk_bool_t {.stdcall,
    importc: "duk_put_global_string", header: headerduktape.}
proc duk_put_global_lstring*(ctx: DTContext; key: cstring; key_len: duk_size_t): duk_bool_t {.
    stdcall, importc: "duk_put_global_lstring", header: headerduktape.}
proc duk_inspect_value*(ctx: DTContext; idx: duk_idx_t) {.stdcall,
    importc: "duk_inspect_value", header: headerduktape.}
proc duk_inspect_callstack_entry*(ctx: DTContext; level: duk_int_t) {.stdcall,
    importc: "duk_inspect_callstack_entry", header: headerduktape.}
proc duk_get_prototype*(ctx: DTContext; idx: duk_idx_t) {.stdcall,
    importc: "duk_get_prototype", header: headerduktape.}
proc duk_set_prototype*(ctx: DTContext; idx: duk_idx_t) {.stdcall,
    importc: "duk_set_prototype", header: headerduktape.}
proc duk_get_finalizer*(ctx: DTContext; idx: duk_idx_t) {.stdcall,
    importc: "duk_get_finalizer", header: headerduktape.}
proc duk_set_finalizer*(ctx: DTContext; idx: duk_idx_t) {.stdcall,
    importc: "duk_set_finalizer", header: headerduktape.}
proc duk_set_global_object*(ctx: DTContext) {.stdcall,
    importc: "duk_set_global_object", header: headerduktape.}
proc duk_get_magic*(ctx: DTContext; idx: duk_idx_t): duk_int_t {.stdcall,
    importc: "duk_get_magic", header: headerduktape.}
proc duk_set_magic*(ctx: DTContext; idx: duk_idx_t; magic: duk_int_t) {.stdcall,
    importc: "duk_set_magic", header: headerduktape.}
proc duk_get_current_magic*(ctx: DTContext): duk_int_t {.stdcall,
    importc: "duk_get_current_magic", header: headerduktape.}
proc duk_put_function_list*(ctx: DTContext; obj_idx: duk_idx_t;
                           funcs: ptr duk_function_list_entry) {.stdcall,
    importc: "duk_put_function_list", header: headerduktape.}
proc duk_put_number_list*(ctx: DTContext; obj_idx: duk_idx_t;
                         numbers: ptr duk_number_list_entry) {.stdcall,
    importc: "duk_put_number_list", header: headerduktape.}
proc duk_compact*(ctx: DTContext; obj_idx: duk_idx_t) {.stdcall,
    importc: "duk_compact", header: headerduktape.}
proc duk_enum*(ctx: DTContext; obj_idx: duk_idx_t; enum_flags: duk_uint_t) {.
    stdcall, importc: "duk_enum", header: headerduktape.}
proc duk_next*(ctx: DTContext; enum_idx: duk_idx_t; get_value: duk_bool_t): duk_bool_t {.
    stdcall, importc: "duk_next", header: headerduktape.}
proc duk_seal*(ctx: DTContext; obj_idx: duk_idx_t) {.stdcall,
    importc: "duk_seal", header: headerduktape.}
proc duk_freeze*(ctx: DTContext; obj_idx: duk_idx_t) {.stdcall,
    importc: "duk_freeze", header: headerduktape.}
proc duk_concat*(ctx: DTContext; count: duk_idx_t) {.stdcall,
    importc: "duk_concat", header: headerduktape.}
proc duk_join*(ctx: DTContext; count: duk_idx_t) {.stdcall, importc: "duk_join",
    header: headerduktape.}
proc duk_decode_string*(ctx: DTContext; idx: duk_idx_t;
                       callback: duk_decode_char_function; udata: pointer) {.
    stdcall, importc: "duk_decode_string", header: headerduktape.}
proc duk_map_string*(ctx: DTContext; idx: duk_idx_t;
                    callback: duk_map_char_function; udata: pointer) {.stdcall,
    importc: "duk_map_string", header: headerduktape.}
proc duk_substring*(ctx: DTContext; idx: duk_idx_t;
                   start_char_offset: duk_size_t; end_char_offset: duk_size_t) {.
    stdcall, importc: "duk_substring", header: headerduktape.}
proc duk_trim*(ctx: DTContext; idx: duk_idx_t) {.stdcall, importc: "duk_trim",
    header: headerduktape.}
proc duk_char_code_at*(ctx: DTContext; idx: duk_idx_t; char_offset: duk_size_t): duk_codepoint_t {.
    stdcall, importc: "duk_char_code_at", header: headerduktape.}
proc duk_equals*(ctx: DTContext; idx1: duk_idx_t; idx2: duk_idx_t): duk_bool_t {.
    stdcall, importc: "duk_equals", header: headerduktape.}
proc duk_strict_equals*(ctx: DTContext; idx1: duk_idx_t; idx2: duk_idx_t): duk_bool_t {.
    stdcall, importc: "duk_strict_equals", header: headerduktape.}
proc duk_samevalue*(ctx: DTContext; idx1: duk_idx_t; idx2: duk_idx_t): duk_bool_t {.
    stdcall, importc: "duk_samevalue", header: headerduktape.}
proc duk_instanceof*(ctx: DTContext; idx1: duk_idx_t; idx2: duk_idx_t): duk_bool_t {.
    stdcall, importc: "duk_instanceof", header: headerduktape.}
proc duk_call*(ctx: DTContext; nargs: duk_idx_t) {.stdcall, importc: "duk_call",
    header: headerduktape.}
proc duk_call_method*(ctx: DTContext; nargs: duk_idx_t) {.stdcall,
    importc: "duk_call_method", header: headerduktape.}
proc duk_call_prop*(ctx: DTContext; obj_idx: duk_idx_t; nargs: duk_idx_t) {.
    stdcall, importc: "duk_call_prop", header: headerduktape.}
proc duk_pcall*(ctx: DTContext; nargs: duk_idx_t): duk_int_t {.stdcall,
    importc: "duk_pcall", header: headerduktape.}
proc duk_pcall_method*(ctx: DTContext; nargs: duk_idx_t): duk_int_t {.stdcall,
    importc: "duk_pcall_method", header: headerduktape.}
proc duk_pcall_prop*(ctx: DTContext; obj_idx: duk_idx_t; nargs: duk_idx_t): duk_int_t {.
    stdcall, importc: "duk_pcall_prop", header: headerduktape.}
proc duk_new*(ctx: DTContext; nargs: duk_idx_t) {.stdcall, importc: "duk_new",
    header: headerduktape.}
proc duk_pnew*(ctx: DTContext; nargs: duk_idx_t): duk_int_t {.stdcall,
    importc: "duk_pnew", header: headerduktape.}
proc duk_safe_call*(ctx: DTContext; `func`: duk_safe_call_function;
                   udata: pointer; nargs: duk_idx_t; nrets: duk_idx_t): duk_int_t {.
    stdcall, importc: "duk_safe_call", header: headerduktape.}
proc duk_eval_raw*(ctx: DTContext; src_buffer: cstring; src_length: duk_size_t;
                  flags: duk_uint_t): duk_int_t {.stdcall, importc: "duk_eval_raw",
    header: headerduktape.}
proc duk_compile_raw*(ctx: DTContext; src_buffer: cstring;
                     src_length: duk_size_t; flags: duk_uint_t): duk_int_t {.stdcall,
    importc: "duk_compile_raw", header: headerduktape.}
proc duk_dump_function*(ctx: DTContext) {.stdcall,
    importc: "duk_dump_function", header: headerduktape.}
proc duk_load_function*(ctx: DTContext) {.stdcall,
    importc: "duk_load_function", header: headerduktape.}
proc duk_push_context_dump*(ctx: DTContext) {.stdcall,
    importc: "duk_push_context_dump", header: headerduktape.}
proc duk_debugger_attach*(ctx: DTContext; read_cb: duk_debug_read_function;
                         write_cb: duk_debug_write_function;
                         peek_cb: duk_debug_peek_function;
                         read_flush_cb: duk_debug_read_flush_function;
                         write_flush_cb: duk_debug_write_flush_function;
                         request_cb: duk_debug_request_function;
                         detached_cb: duk_debug_detached_function; udata: pointer) {.
    stdcall, importc: "duk_debugger_attach", header: headerduktape.}
proc duk_debugger_detach*(ctx: DTContext) {.stdcall,
    importc: "duk_debugger_detach", header: headerduktape.}
proc duk_debugger_cooperate*(ctx: DTContext) {.stdcall,
    importc: "duk_debugger_cooperate", header: headerduktape.}
proc duk_debugger_notify*(ctx: DTContext; nvalues: duk_idx_t): duk_bool_t {.
    stdcall, importc: "duk_debugger_notify", header: headerduktape.}
proc duk_debugger_pause*(ctx: DTContext) {.stdcall,
    importc: "duk_debugger_pause", header: headerduktape.}
proc duk_get_now*(ctx: DTContext): duk_double_t {.stdcall,
    importc: "duk_get_now", header: headerduktape.}
proc duk_time_to_components*(ctx: DTContext; timeval: duk_double_t;
                            comp: ptr duk_time_components) {.stdcall,
    importc: "duk_time_to_components", header: headerduktape.}
proc duk_components_to_time*(ctx: DTContext; comp: ptr duk_time_components): duk_double_t {.
    stdcall, importc: "duk_components_to_time", header: headerduktape.}
proc duk_create_heap_default*(): DTContext {.header: headerduktape.}
proc duk_eval_string*(ctx: DTContext, s: cstring) {.header: headerduktape.}
proc duk_pcompile_string*(ctx: DTContext, flags: duk_uint_t, s: cstring): duk_int_t {.header: headerduktape.}
proc duk_safe_to_string*(ctx: DTContext, idx: duk_idx_t): cstring {.header: headerduktape.}
# proc duk_to_string*(ctx: DTContext, index: cint): cstring {.header: headerduktape.}

proc duk_peval_string*(ctx: DTContext, s: cstring): duk_int_t {.header: headerduktape.}

## Extras

proc duk_console_init*(ctx: DTContext, flags: duk_uint_t = 0) {.stdcall,
importc: "duk_console_init", header: headerconsole.}
proc duk_print_alert_init*(ctx: DTContext, flags: duk_uint_t = 0) {.stdcall,
importc: "duk_print_alert_init", header: headerprintalert.}

type
  DTCFunction* = duk_c_function

