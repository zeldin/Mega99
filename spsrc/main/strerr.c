#include "global.h"
#include "fatfs.h"
#include "yxml.h"
#include "strerr.h"

static const char * const fatfs_errstr[] = {
  "No card",
  "Card removed",
  "Invalid card",
  "No file system",
  "File not found",
  "Read-only file system",
  "I/O error",
  "Truncated file"
};

static const char * const yxml_errstr[] = {
  "Unexpected EOF",
  "Invalid reference",
  "Unmatched close tag",
  "Stack overflow",
  "Unexpected byte"
};

const char *generic_strerror(int n, const char *prefix,
			     const char * const * messages, int base, int cnt)
{
  if (!messages || n < base || (n - base) >= cnt || !messages[n - base]) {
    static char buf[32];
    snprintf(buf, sizeof(buf), "%s %d", prefix, n);
    return buf;
  }
  return messages[n - base];
}

const char *fatfs_strerror(int n)
{
  return generic_strerror(n, "Err", STRERR_ARRAY(fatfs_errstr, ENOCARD));
}

const char *yxml_strerror(int n)
{
  return generic_strerror(n, "XErr", STRERR_ARRAY(yxml_errstr, YXML_EEOF));
}