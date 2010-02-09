#include <endian.h>

#
#  My gcc tries to align some of the strings if written the code in C. This costs a lot of bytes.
#

#ifdef __DYN_LIB
.section	.data
#else
.section	.rodata
#endif

.align 4
.global sys_errlist
#ifdef __arm__
.type	sys_errlist,object
.type	sys_nerr,object
#else
.type	sys_errlist,@object
.type	sys_nerr,@object
#endif

#if (__WORDSIZE == 64)
#define deflong .quad
#else
#define deflong .long
#endif

sys_errlist:
	deflong .LC000
	deflong .LC001
	deflong .LC002
	deflong .LC003
	deflong .LC004
	deflong .LC005
	deflong .LC006
	deflong .LC007
	deflong .LC008
	deflong .LC009
	deflong .LC010
	deflong .LC011
	deflong .LC012
	deflong .LC013
	deflong .LC014
	deflong .LC015
	deflong .LC016
	deflong .LC017
	deflong .LC018
	deflong .LC019
	deflong .LC020
	deflong .LC021
	deflong .LC022
	deflong .LC023
	deflong .LC024
	deflong .LC025
	deflong .LC026
	deflong .LC027
	deflong .LC028
	deflong .LC029
	deflong .LC030
	deflong .LC031
	deflong .LC032
	deflong .LC033
	deflong .LC034
	deflong .LC035
	deflong .LC036
	deflong .LC037
	deflong .LC038
	deflong .LC039
	deflong .LC040
	deflong .LC041
	deflong .LC042
	deflong .LC043
	deflong .LC044
	deflong .LC045
	deflong .LC046
	deflong .LC047
	deflong .LC048
	deflong .LC049
	deflong .LC050
	deflong .LC051
	deflong .LC052
	deflong .LC053
	deflong .LC054
	deflong .LC055
	deflong .LC056
	deflong .LC057
	deflong .LC058
	deflong .LC059
	deflong .LC060
	deflong .LC061
	deflong .LC062
	deflong .LC063
	deflong .LC064
	deflong .LC065
	deflong .LC066
	deflong .LC067
	deflong .LC068
	deflong .LC069
	deflong .LC070
	deflong .LC071
	deflong .LC072
	deflong .LC073
	deflong .LC074
	deflong .LC075
	deflong .LC076
	deflong .LC077
	deflong .LC078
	deflong .LC079
	deflong .LC080
	deflong .LC081
	deflong .LC082
	deflong .LC083
	deflong .LC084
	deflong .LC085
	deflong .LC086
	deflong .LC087
	deflong .LC088
	deflong .LC089
	deflong .LC090
	deflong .LC091
	deflong .LC092
	deflong .LC093
	deflong .LC094
	deflong .LC095
	deflong .LC096
	deflong .LC097
	deflong .LC098
	deflong .LC099
	deflong .LC100
	deflong .LC101
	deflong .LC102
	deflong .LC103
	deflong .LC104
	deflong .LC105
	deflong .LC106
	deflong .LC107
	deflong .LC108
	deflong .LC109
	deflong .LC110
	deflong .LC111
	deflong .LC112
	deflong .LC113
	deflong .LC114
	deflong .LC115
	deflong .LC116
	deflong .LC117
	deflong .LC118
	deflong .LC119
	deflong .LC120
	deflong .LC121
	deflong .LC122
	deflong .LC123
	deflong .LC124
	deflong .LC125
	deflong .LC126
	deflong .LC127
	deflong .LC128
	deflong .LC129
	deflong 0
.size	sys_errlist,.-sys_errlist

.align 4
.global sys_nerr
sys_nerr:
	.long 125
.size	sys_nerr,4


#ifdef __DYN_LIB
.section	.rodata
#endif

.LC000:	.asciz	"Success"
.LC001:	.asciz	"Operation not permitted"
.LC002:	.asciz	"No such file or directory"
.LC003:	.asciz	"No such process"
.LC004:	.asciz	"Interrupted system call"
.LC005:	.asciz	"I/O error"
.LC006:	.asciz	"No such device or address"
.LC007:	.asciz	"Arg list too long"
.LC008:	.asciz	"Exec format error"
.LC009:	.asciz	"Bad file number"
.LC010:	.asciz	"No child processes"
.LC011:	.asciz	"Try again"
.LC012:	.asciz	"Out of memory"
.LC013:	.asciz	"Permission denied"
.LC014:	.asciz	"Bad address"
.LC015:	.asciz	"Block device required"
.LC016:	.asciz	"Device or resource busy"
.LC017:	.asciz	"File exists"
.LC018:	.asciz	"Cross-device link"
.LC019:	.asciz	"No such device"
.LC020:	.asciz	"Not a directory"
.LC021:	.asciz	"Is a directory"
.LC022:	.asciz	"Invalid argument"
.LC023:	.asciz	"File table overflow"
.LC024:	.asciz	"Too many open files"
.LC025:	.asciz	"Not a typewriter"
.LC026:	.asciz	"Text file busy"
.LC027:	.asciz	"File too large"
.LC028:	.asciz	"No space left on device"
.LC029:	.asciz	"Illegal seek"
.LC030:	.asciz	"Read-only file system"
.LC031:	.asciz	"Too many links"
.LC032:	.asciz	"Broken pipe"
.LC033:	.asciz	"Math argument out of domain of func"
.LC034:	.asciz	"Math result not representable"
.LC035:	.asciz	"Resource deadlock would occur"
.LC036:	.asciz	"File name too long"
.LC037:	.asciz	"No record locks available"
.LC038:	.asciz	"Function not implemented"
.LC039:	.asciz	"Directory not empty"
.LC040:	.asciz	"Too many symbolic links encountered"
.LC041:	.asciz	"Operation would block"
.LC042:	.asciz	"No message of desired type"
.LC043:	.asciz	"Identifier removed"
.LC044:	.asciz	"Channel number out of range"
.LC045:	.asciz	"Level 2 not synchronized"
.LC046:	.asciz	"Level 3 halted"
.LC047:	.asciz	"Level 3 reset"
.LC048:	.asciz	"Link number out of range"
.LC049:	.asciz	"Protocol driver not attached"
.LC050:	.asciz	"No CSI structure available"
.LC051:	.asciz	"Level 2 halted"
.LC052:	.asciz	"Invalid exchange"
.LC053:	.asciz	"Invalid request descriptor"
.LC054:	.asciz	"Exchange full"
.LC055:	.asciz	"No anode"
.LC056:	.asciz	"Invalid request code"
.LC057:	.asciz	"Invalid slot"
.LC058:	.asciz	"File locking deadlock error"
.LC059:	.asciz	"Bad font file format"
.LC060:	.asciz	"Device not a stream"
.LC061:	.asciz	"No data available"
.LC062:	.asciz	"Timer expired"
.LC063:	.asciz	"Out of streams resources"
.LC064:	.asciz	"Machine is not on the network"
.LC065:	.asciz	"Package not installed"
.LC066:	.asciz	"Object is remote"
.LC067:	.asciz	"Link has been severed"
.LC068:	.asciz	"Advertise error"
.LC069:	.asciz	"Srmount error"
.LC070:	.asciz	"Communication error on send"
.LC071:	.asciz	"Protocol error"
.LC072:	.asciz	"Multihop attempted"
.LC073:	.asciz	"RFS specific error"
.LC074:	.asciz	"Not a data message"
.LC075:	.asciz	"Value too large for defined data type"
.LC076:	.asciz	"Name not unique on network"
.LC077:	.asciz	"File descriptor in bad state"
.LC078:	.asciz	"Remote address changed"
.LC079:	.asciz	"Can not access a needed shared library"
.LC080:	.asciz	"Accessing a corrupted shared library"
.LC081:	.asciz	".lib section in a.out corrupted"
.LC082:	.asciz	"Attempting to link in too many shared libraries"
.LC083:	.asciz	"Cannot exec a shared library directly"
.LC084:	.asciz	"Illegal byte sequence"
.LC085:	.asciz	"Interrupted system call should be restarted"
.LC086:	.asciz	"Streams pipe error"
.LC087:	.asciz	"Too many users"
.LC088:	.asciz	"Socket operation on non-socket"
.LC089:	.asciz	"Destination address required"
.LC090:	.asciz	"Message too long"
.LC091:	.asciz	"Protocol wrong type for socket"
.LC092:	.asciz	"Protocol not available"
.LC093:	.asciz	"Protocol not supported"
.LC094:	.asciz	"Socket type not supported"
.LC095:	.asciz	"Operation not supported on transport endpoint"
.LC096:	.asciz	"Protocol family not supported"
.LC097:	.asciz	"Address family not supported by protocol"
.LC098:	.asciz	"Address already in use"
.LC099:	.asciz	"Cannot assign requested address"
.LC100:	.asciz	"Network is down"
.LC101:	.asciz	"Network is unreachable"
.LC102:	.asciz	"Network dropped connection because of reset"
.LC103:	.asciz	"Software caused connection abort"
.LC104:	.asciz	"Connection reset by peer"
.LC105:	.asciz	"No buffer space available"
.LC106:	.asciz	"Transport endpoint is already connected"
.LC107:	.asciz	"Transport endpoint is not connected"
.LC108:	.asciz	"Cannot send after transport endpoint shutdown"
.LC109:	.asciz	"Too many references: cannot splice"
.LC110:	.asciz	"Connection timed out"
.LC111:	.asciz	"Connection refused"
.LC112:	.asciz	"Host is down"
.LC113:	.asciz	"No route to host"
.LC114:	.asciz	"Operation already in progress"
.LC115:	.asciz	"Operation now in progress"
.LC116:	.asciz	"Stale NFS file handle"
.LC117:	.asciz	"Structure needs cleaning"
.LC118:	.asciz	"Not a XENIX named type file"
.LC119:	.asciz	"No XENIX semaphores available"
.LC120:	.asciz	"Is a named type file"
.LC121:	.asciz	"Remote I/O error"
.LC122:	.asciz	"Quota exceeded"
.LC123:	.asciz	"No medium found"
.LC124:	.asciz	"Wrong medium type"
.LC125:	.asciz	"Operation Canceled"
.LC126:	.asciz	"Required key not available"
.LC127:	.asciz	"Key has expired"
.LC128:	.asciz	"Key has been revoked"
.LC129:	.asciz	"Key was rejected by service"
