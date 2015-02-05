ffi = require("ffi")
local dispatch = {}

ffi.cdef[[
// base.h
typedef union {
    struct dispatch_object_s *_do;
    struct dispatch_continuation_s *_dc;
    struct dispatch_queue_s *_dq;
    struct dispatch_queue_attr_s *_dqa;
    struct dispatch_group_s *_dg;
    struct dispatch_source_s *_ds;
    struct dispatch_source_attr_s *_dsa;
    struct dispatch_semaphore_s *_dsema;
    struct dispatch_data_s *_ddata;
    struct dispatch_io_s *_dchannel;
    struct dispatch_operation_s *_doperation;
    struct dispatch_disk_s *_ddisk;
} dispatch_object_t __attribute__((transparent_union));
typedef void (*dispatch_function_t)(void *);

// object.h
void dispatch_debug(dispatch_object_t object, const char *message, ...);
void dispatch_debugv(dispatch_object_t object, const char *message, va_list ap);
void dispatch_retain(dispatch_object_t object);
void dispatch_release(dispatch_object_t object);
void *dispatch_get_context(dispatch_object_t object);
void dispatch_set_context(dispatch_object_t object, void *context);
void dispatch_set_finalizer_f(dispatch_object_t object, dispatch_function_t finalizer);
void dispatch_suspend(dispatch_object_t object);
void dispatch_resume(dispatch_object_t object);

// time.h
typedef uint64_t dispatch_time_t;
dispatch_time_t dispatch_time(dispatch_time_t when, int64_t delta);
dispatch_time_t dispatch_walltime(const struct timespec *when, int64_t delta);

// queue.h
typedef struct dispatch_queue_s *dispatch_queue_t;
typedef struct dispatch_queue_attr_s *dispatch_queue_attr_t;
typedef long dispatch_queue_priority_t;

struct dispatch_queue_s _dispatch_main_q;
struct dispatch_queue_attr_s _dispatch_queue_attr_concurrent;

void dispatch_async_f(dispatch_queue_t queue, void *context, dispatch_function_t work);
void dispatch_sync_f(dispatch_queue_t queue, void *context, dispatch_function_t work);
void dispatch_apply_f(size_t iterations, dispatch_queue_t queue, void *context, void (*work)(void *, size_t));
dispatch_queue_t dispatch_get_current_queue(void);
dispatch_queue_t dispatch_get_global_queue(dispatch_queue_priority_t priority, unsigned long flags);
dispatch_queue_t dispatch_queue_create(const char *label, dispatch_queue_attr_t attr);
const char *dispatch_queue_get_label(dispatch_queue_t queue);
void dispatch_set_target_queue(dispatch_object_t object, dispatch_queue_t queue);
void dispatch_main(void);
void dispatch_after_f(dispatch_time_t when, dispatch_queue_t queue, void *context, dispatch_function_t work);
void dispatch_barrier_async_f(dispatch_queue_t queue, void *context, dispatch_function_t work);
void dispatch_barrier_sync_f(dispatch_queue_t queue, void *context, dispatch_function_t work);
void dispatch_queue_set_specific(dispatch_queue_t queue, const void *key, void *context, dispatch_function_t destructor);
void *dispatch_queue_get_specific(dispatch_queue_t queue, const void *key);
void *dispatch_get_specific(const void *key);

// source.h
typedef struct dispatch_source_s *dispatch_source_t;
typedef const struct dispatch_source_type_s *dispatch_source_type_t;
typedef unsigned long dispatch_source_mach_send_flags_t;
typedef unsigned long dispatch_source_proc_flags_t;
typedef unsigned long dispatch_source_vnode_flags_t;

const struct dispatch_source_type_s _dispatch_source_type_data_add;
const struct dispatch_source_type_s _dispatch_source_type_data_or;
const struct dispatch_source_type_s _dispatch_source_type_mach_send;
const struct dispatch_source_type_s _dispatch_source_type_mach_recv;
const struct dispatch_source_type_s _dispatch_source_type_proc;
const struct dispatch_source_type_s _dispatch_source_type_read;
const struct dispatch_source_type_s _dispatch_source_type_signal;
const struct dispatch_source_type_s _dispatch_source_type_timer;
const struct dispatch_source_type_s _dispatch_source_type_vnode;
const struct dispatch_source_type_s _dispatch_source_type_write;

dispatch_source_t dispatch_source_create(dispatch_source_type_t type, uintptr_t handle, unsigned long mask, dispatch_queue_t queue);
void dispatch_source_set_event_handler_f(dispatch_source_t source, dispatch_function_t handler);
void dispatch_source_set_cancel_handler_f(dispatch_source_t source, dispatch_function_t cancel_handler);
void dispatch_source_cancel(dispatch_source_t source);
long dispatch_source_testcancel(dispatch_source_t source);
uintptr_t dispatch_source_get_handle(dispatch_source_t source);
unsigned long dispatch_source_get_mask(dispatch_source_t source);
unsigned long dispatch_source_get_data(dispatch_source_t source);
void dispatch_source_merge_data(dispatch_source_t source, unsigned long value);
void
dispatch_source_set_timer(dispatch_source_t source, dispatch_time_t start, uint64_t interval, uint64_t leeway);
void dispatch_source_set_registration_handler_f(dispatch_source_t source, dispatch_function_t registration_handler);

// group.h
typedef struct dispatch_group_s *dispatch_group_t;

dispatch_group_t dispatch_group_create(void);
void dispatch_group_async_f(dispatch_group_t group, dispatch_queue_t queue, void *context, dispatch_function_t work);
long dispatch_group_wait(dispatch_group_t group, dispatch_time_t timeout);
void dispatch_group_notify_f(dispatch_group_t group, dispatch_queue_t queue, void *context, dispatch_function_t work);
void dispatch_group_enter(dispatch_group_t group);
void dispatch_group_leave(dispatch_group_t group);

// semaphore.h
typedef struct dispatch_semaphore_s *dispatch_semaphore_t;

dispatch_semaphore_t dispatch_semaphore_create(long value);
long dispatch_semaphore_wait(dispatch_semaphore_t dsema, dispatch_time_t timeout);
long dispatch_semaphore_signal(dispatch_semaphore_t dsema);

// once.h
typedef long dispatch_once_t;

void dispatch_once_f(dispatch_once_t *predicate, void *context, dispatch_function_t function);

// data.h (Requires blocks for all of it's functionality, see http://github.com/aptiva/tlc if you need it)
typedef struct dispatch_data_s *dispatch_data_t;

struct dispatch_data_s _dispatch_data_empty;

// io.h (Requires blocks for all of it's functionality, see http://github.com/aptiva/tlc if you need it)
typedef int dispatch_fd_t;
]]

local lib = ffi.C --load("dispatch")


-- Types
dispatch.object_t                        = ffi.typeof("dispatch_object_t")
dispatch.function_t                      = ffi.typeof("dispatch_function_t")
dispatch.time_t                          = ffi.typeof("dispatch_time_t")
dispatch.queue_t                         = ffi.typeof("dispatch_queue_t")
dispatch.queue_attr_t                    = ffi.typeof("dispatch_queue_attr_t")
dispatch.queue_priority_t                = ffi.typeof("dispatch_queue_priority_t")
dispatch.source_t                        = ffi.typeof("dispatch_source_t")
dispatch.source_type_t                   = ffi.typeof("dispatch_source_type_t")
dispatch.source_mach_send_flags_t        = ffi.typeof("dispatch_source_mach_send_flags_t")
dispatch.source_proc_flags_t             = ffi.typeof("dispatch_source_proc_flags_t")
dispatch.source_vnode_flags_t            = ffi.typeof("dispatch_source_vnode_flags_t")
dispatch.group_t                         = ffi.typeof("dispatch_group_t")
dispatch.semaphore_t                     = ffi.typeof("dispatch_semaphore_t")
dispatch.once_                           = ffi.typeof("dispatch_once_t")
dispatch.data_t                          = ffi.typeof("dispatch_data_t")
dispatch.fd_t                            = ffi.typeof("dispatch_fd_t")


-- Contants
dispatch.emptyData                       = ffi.cast(dispatch.data_t, lib._dispatch_data_empty)
dispatch.defaultDataDestructor           = nil

dispatch.nsecPerSec                      = 1000000000ull
dispatch.nsecPerMsec                     = 1000000ull
dispatch.usecPerSec                      = 1000000ull
dispatch.nsecPerUsec                     = 1000ull

dispatch.timeNow                         = 0
dispatch.timeForever                     = bit.bnot(0)

dispatch.highPriority                    = ffi.cast(dispatch.queue_priority_t, 2)
dispatch.defaultPriority                 = ffi.cast(dispatch.queue_priority_t, 0)
dispatch.lowPriority                     = ffi.cast(dispatch.queue_priority_t, -2)
dispatch.backgroundPriority              = ffi.cast(dispatch.queue_priority_t, -32768) -- INT16_MIN

dispatch.mainQueue                       = lib._dispatch_main_q
dispatch.serialQueueAttr                 = nil
dispatch.concurrentQueueAttr             = lib._dispatch_queue_attr_concurrent
dispatch.defaultTargetQueue              = nil

dispatch.machSendDead                    = ffi.cast(dispatch.source_proc_flags_t, 0x1)
dispatch.procExit                        = ffi.cast(dispatch.source_proc_flags_t, 0x80000000)
dispatch.procFork                        = ffi.cast(dispatch.source_proc_flags_t, 0x40000000)
dispatch.procExec                        = ffi.cast(dispatch.source_proc_flags_t, 0x20000000)
dispatch.procSignal                      = ffi.cast(dispatch.source_proc_flags_t, 0x08000000)

dispatch.sourceTypeDataAdd               = ffi.cast(dispatch.source_type_t, lib._dispatch_source_type_data_add)
dispatch.sourceTypeDataOr                = ffi.cast(dispatch.source_type_t, lib._dispatch_source_type_data_or)
dispatch.sourceTypeMachSend              = ffi.cast(dispatch.source_type_t, lib._dispatch_source_type_mach_send)
dispatch.sourceTypeMachRecv              = ffi.cast(dispatch.source_type_t, lib._dispatch_source_type_mach_recv)
dispatch.sourceTypeProc                  = ffi.cast(dispatch.source_type_t, lib._dispatch_source_type_proc)
dispatch.sourceTypeRead                  = ffi.cast(dispatch.source_type_t, lib._dispatch_source_type_read)
dispatch.sourceTypeSignal                = ffi.cast(dispatch.source_type_t, lib._dispatch_source_type_signal)
dispatch.sourceTypeTimer                 = ffi.cast(dispatch.source_type_t, lib._dispatch_source_type_timer)
dispatch.sourceTypeVnode                 = ffi.cast(dispatch.source_type_t, lib._dispatch_source_type_vnode)
dispatch.sourceTypeWrite                 = ffi.cast(dispatch.source_type_t, lib._dispatch_source_type_write)
dispatch.vNodeDelete                     = ffi.cast(dispatch.source_vnode_flags_t, 0x1)
dispatch.vNodeWrite                      = ffi.cast(dispatch.source_vnode_flags_t, 0x2)
dispatch.vNodeExtend                     = ffi.cast(dispatch.source_vnode_flags_t, 0x4)
dispatch.vNodeAttrib                     = ffi.cast(dispatch.source_vnode_flags_t, 0x8)
dispatch.vNodeLink                       = ffi.cast(dispatch.source_vnode_flags_t, 0x10)
dispatch.vNodeRename                     = ffi.cast(dispatch.source_vnode_flags_t, 0x20)
dispatch.vNodeRevoke                     = ffi.cast(dispatch.source_vnode_flags_t, 0x40)


-- Functions
dispatch.debug                           = lib.dispatch_debug
dispatch.debugv                          = lib.dispatch_debugv
dispatch.retain                          = lib.dispatch_retain
dispatch.release                         = lib.dispatch_release
dispatch.dispatch_get_context            = lib.dispatch_get_context
dispatch.set_context                     = lib.dispatch_set_context
dispatch.set_finalizer                   = lib.dispatch_set_finalizer_f
dispatch.suspend                         = lib.dispatch_suspend
dispatch.resume                          = lib.dispatch_resume

dispatch.time                            = lib.dispatch_time
dispatch.walltime                        = lib.dispatch_walltime

dispatch.async                           = lib.dispatch_async_f
dispatch.sync                            = lib.dispatch_sync_f
dispatch.apply                           = lib.dispatch_apply_f
dispatch.get_current_queue               = lib.dispatch_get_current_queue
dispatch.get_global_queue                = lib.dispatch_get_global_queue
dispatch.queue_create                    = lib.dispatch_queue_create
dispatch.dispatch_queue_get_label        = lib.dispatch_queue_get_label
dispatch.set_target_queue                = lib.dispatch_set_target_queue
dispatch.main                            = lib.dispatch_main
dispatch.after                           = lib.dispatch_after_f
dispatch.barrier_async                   = lib.dispatch_barrier_async_f
dispatch.barrier_sync                    = lib.dispatch_barrier_sync_f
dispatch.queue_set_specific              = lib.dispatch_queue_set_specific
dispatch.dispatch_queue_get_specific     = lib.dispatch_queue_get_specific
dispatch.dispatch_get_specific           = lib.dispatch_get_specific

dispatch.source_create                   = lib.dispatch_source_create
dispatch.source_set_event_handler        = lib.dispatch_source_set_event_handler_f
dispatch.source_set_cancel_handler       = lib.dispatch_source_set_cancel_handler_f
dispatch.source_cancel                   = lib.dispatch_source_cancel
dispatch.source_testcancel               = lib.dispatch_source_testcancel
dispatch.source_get_handle               = lib.dispatch_source_get_handle
dispatch.source_get_mask                 = lib.dispatch_source_get_mask
dispatch.source_get_data                 = lib.dispatch_source_get_data
dispatch.source_merge_data               = lib.dispatch_source_merge_data
dispatch.source_set_timer                = lib.dispatch_source_set_timer
dispatch.source_set_registration_handler = lib.dispatch_source_set_registration_handler_f

dispatch.group_create                    = lib.dispatch_group_create
dispatch.group_async                     = lib.dispatch_group_async_f
dispatch.group_wait                      = lib.dispatch_group_wait
dispatch.group_notify                    = lib.dispatch_group_notify_f
dispatch.group_enter                     = lib.dispatch_group_enter
dispatch.group_leave                     = lib.dispatch_group_leave

dispatch.semaphore_create                = lib.dispatch_semaphore_create
dispatch.semaphore_wait                  = lib.dispatch_semaphore_wait
dispatch.semaphore_signal                = lib.dispatch_semaphore_signal

dispatch.once                            = lib.dispatch_once_f

return dispatch
