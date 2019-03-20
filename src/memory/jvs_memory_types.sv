`ifndef __JVS_MEMORY_TYPES_SV__
 `define __JVS_MEMORY_TYPES_SV__
typedef enum {ALIGN_BYTE = 0,
	      ALIGN_DBYTE = 1,
	      ALIGN_WORD = 2,
	      ALIGN_DWORD =3,
	      ALIGN_1K = 10,
	      ALIGN_2K = 11,
	      ALIGN_4K = 12,
	      ALIGN_16K = 14,
	      ALIGN_64K = 16
	      } e_alignment;


typedef byte unsigned MEM_BYTE;
typedef int unsigned MEM_INT;
typedef longint unsigned MEM_LONG;
typedef MEM_BYTE MEM_BARRAY [];

`endif