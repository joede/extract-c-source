/* -*- Mode: C -*-
 *
 * this file is generated from the documentation source by extract-c-source.awk!
 */


#ifndef __APCOMMANDS_H__
#define __APCOMMANDS_H__ 1

#include <stdint.h>


/* DEFINES
 */

#define TEST 123
#define FOO  "123"
#define MAX_PACKET_DATA 10


#ifdef __GNUC__
#define ___PACKED __attribute__((__packed__))
#else
#define ___PACKED
#endif

/* STRUCT DECLARATIONS
 */

typedef struct ___PACKED tagFOOTYPE { uint8_t cmd; } T_FOOTYPE;
typedef struct ___PACKED tagPKT_FOO { uint8_t cmd; uint16_t parm; } T_PKT_FOO;


/* UNION OF ALL 1 PAKETDATA TYPES
 */
typedef union ___PACKED tagPACKET_DATA {
    T_PKT_FOO foo;
    uint8 bytes[MAX_PACKET_DATA];
} T_PACKET_DATA;

#endif
/* =====[end of generated file]===== */

