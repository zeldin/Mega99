#include "global.h"
#include "fatfs.h"
#include "strerr.h"
#include "zipfile.h"

#include "mz.h"
#include "mz_zip.h"
#include "mz_strm.h"
#include "mz_strm_buf.h"

typedef struct fatfs_stream_s {
  mz_stream stream;
  fatfs_filehandle_t fh;
  bool is_open;
  int32_t error;
} fatfs_stream;

static mz_stream_vtbl fatfs_stream_vtbl;

void fatfs_stream_delete(void **stream) {
  fatfs_stream *fatfs = NULL;
  if (!stream)
    return;
  fatfs = (fatfs_stream *)*stream;
  if (fatfs)
    free(fatfs);
  *stream = NULL;
}

void *fatfs_stream_create(void) {
  fatfs_stream *fatfs = (fatfs_stream *)calloc(1, sizeof(fatfs_stream));
  if (fatfs)
    fatfs->stream.vtbl = &fatfs_stream_vtbl;
  return fatfs;
}

int32_t fatfs_stream_open(void *stream, const char *path, int32_t mode) {
  fatfs_stream *fatfs = (fatfs_stream *)stream;

  if (!path)
    return MZ_PARAM_ERROR;

  fatfs->error = 0;

  if ((mode & MZ_OPEN_MODE_READWRITE) != MZ_OPEN_MODE_READ)
    return MZ_OPEN_ERROR;

  int r;
  if ((mode & MZ_OPEN_MODE_EXISTING))
    fatfs->fh = *(const fatfs_filehandle_t *)path;
  else if ((r = fatfs_open(path, &fatfs->fh)) < 0) {
    fatfs->error = -r;
    fatfs->is_open = false;
    return MZ_OPEN_ERROR;
  }
  fatfs->is_open = true;
  return MZ_OK;
}

int32_t fatfs_stream_close(void *stream) {
  fatfs_stream *fatfs = (fatfs_stream *)stream;
  fatfs->is_open = false;
  return MZ_OK;
}

int32_t fatfs_stream_error(void *stream) {
  fatfs_stream *fatfs = (fatfs_stream *)stream;
  return fatfs->error;
}

int32_t fatfs_stream_is_open(void *stream) {
  fatfs_stream *fatfs = (fatfs_stream *)stream;
  return fatfs->is_open? MZ_OK : MZ_OPEN_ERROR;
}

int32_t fatfs_stream_read(void *stream, void *buf, int32_t size) {
  fatfs_stream *fatfs = (fatfs_stream *)stream;
  int r = fatfs_read(&fatfs->fh, buf, size);
  if (r < 0) {
    fatfs->error = -r;
    return MZ_READ_ERROR;
  }
  return r;
}

int64_t fatfs_stream_tell(void *stream) {
  fatfs_stream *fatfs = (fatfs_stream *)stream;
  return fatfs->fh.filepos;
}

int32_t fatfs_stream_seek(void *stream, int64_t offset, int32_t origin) {
  fatfs_stream *fatfs = (fatfs_stream *)stream;

  switch (origin) {
  case MZ_SEEK_CUR:
    offset += fatfs->fh.filepos;
    break;
  case MZ_SEEK_END:
    offset += fatfs->fh.size;
    break;
  case MZ_SEEK_SET:
    break;
  default:
    return MZ_PARAM_ERROR;
  }

  if (offset < 0)
    return MZ_PARAM_ERROR;

  int r = fatfs_setpos(&fatfs->fh, offset);
  if (r < 0) {
    fatfs->error = -r;
    return MZ_SEEK_ERROR;
  }

  return MZ_OK;
}

static mz_stream_vtbl fatfs_stream_vtbl = {
    fatfs_stream_open,
    fatfs_stream_is_open,
    fatfs_stream_read,
    NULL,
    fatfs_stream_tell,
    fatfs_stream_seek,
    fatfs_stream_close,
    fatfs_stream_error,
    fatfs_stream_create,
    fatfs_stream_delete,
    NULL,
    NULL
};

/* Workaround for mz_crypt.c not compiling: */

uint32_t mz_crypt_crc32_update(uint32_t value, const uint8_t *buf, int32_t size) {
  extern uint32_t zng_crc32(uint32_t crc, const uint8_t *buf, uint32_t len);
  return zng_crc32(value, buf, size);
}

static void *zipfile_handle, *stream_handle;

void zipfile_init()
{
  zipfile_handle = mz_zip_create();
  stream_handle = mz_stream_buffered_create();
  mz_stream_set_base(stream_handle, fatfs_stream_create());
}

int zipfile_open_int(const char *path, int32_t mode)
{
  int r;
  zipfile_close();
  if ((r = mz_stream_open(stream_handle, path, mode|MZ_OPEN_MODE_READ)))
    return r;
  if ((r = mz_zip_open(zipfile_handle, stream_handle, MZ_OPEN_MODE_READ)))
    return r;
  return 0;
}

int zipfile_open(const char *path)
{
  return zipfile_open_int(path, 0);
}

int zipfile_open_fh(fatfs_filehandle_t *fh)
{
  return zipfile_open_int((const char *)fh, MZ_OPEN_MODE_EXISTING);
}

int zipfile_open_entry(const char *path)
{
  int r;
  if ((r = mz_zip_locate_entry(zipfile_handle, path, 1)))
    return r;
  if ((r = mz_zip_entry_read_open(zipfile_handle, 0, NULL)))
    return r;
  return 0;
}

int zipfile_read(void *p, uint32_t bytes)
{
  return mz_zip_entry_read(zipfile_handle, p, bytes);
}

void zipfile_close(void)
{
  mz_zip_close(zipfile_handle);
  mz_stream_close(stream_handle);
}

static const char * const zipfile_zlib_errstr[] = {
  "Version error (zlib)",
  "Buffer error (zlib)",
  "Memory allocation error (zlib)",
  "Data error (zlib)",
  NULL,
  "Stream error (zlib)"
};

static const char * const zipfile_mz_errstr[] = {
  "Symbolic link error",
  "Signing error",
  "Stream write error",
  "Stream read error",
  "Stream tell error",
  "Stream seek error",
  "Stream close error",
  "Stream open error",
  "Hash error",
  "Missing library support",
  "Password protected",
  "Does not exist",
  "Cryptography error",
  "CRC error",
  "Internal error",
  "File format error",
  "Invalid parameter",
  "End of stream",
  "End of list",
};

const char *zipfile_strerror(int n)
{
  if (n > -100)
    return generic_strerror(n, "ZErr", STRERR_ARRAY(zipfile_zlib_errstr, MZ_VERSION_ERROR));
  if (n == MZ_OPEN_ERROR || n == MZ_SEEK_ERROR || n == MZ_READ_ERROR) {
    int e;
    if (mz_stream_is_open(stream_handle) == MZ_OK &&
	(e = mz_stream_error(stream_handle)))
      return fatfs_strerror(e);
  }
  return generic_strerror(n, "ZErr", STRERR_ARRAY(zipfile_mz_errstr, MZ_SYMLINK_ERROR));
}
