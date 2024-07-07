#ifdef BOOTCODE
#define memset __builtin_memset
#define memcpy __builtin_memcpy
#undef __INT32_TYPE__
#define __INT32_TYPE__ int
#undef __UINT32_TYPE__
#define __UINT32_TYPE__ unsigned int
#endif
#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdarg.h>
#include <string.h>
#ifndef BOOTCODE
#include <stdio.h>
#include <stdlib.h>
#endif
