#define ENOCARD       1
#define ECARDCHANGED  2
#define EBADCARD      3
#define ENOFS         4
#define EFILENOTFOUND 5
#define EREADONLYFS   6
#define EIO           7
#define ETRUNC        8
#define ENOSPC        9
#define ENOTDIR       10
#define EISDIR        11

typedef struct {
  uint32_t card_id;
  uint32_t start_cluster;
  uint32_t size;
  uint32_t current_cluster;
  uint32_t filepos;
} fatfs_filehandle_t;

extern int fatfs_openat(const char *filename, fatfs_filehandle_t *fh, fatfs_filehandle_t *dirfh);
extern int fatfs_open(const char *filename, fatfs_filehandle_t *fh);
extern int fatfs_read(fatfs_filehandle_t *fh, void *p, uint32_t bytes);
extern int fatfs_open_rootdir(fatfs_filehandle_t *fh);
extern int fatfs_open_dir(const char *dirname, fatfs_filehandle_t *dirfh);
#ifndef BOOTCODE
extern int fatfs_open_or_create(const char *filename, fatfs_filehandle_t *fh,
				fatfs_filehandle_t *dirent_fh);
extern int fatfs_write(fatfs_filehandle_t *fh, const void *p, uint32_t bytes);
extern int fatfs_setpos(fatfs_filehandle_t *fh, uint32_t newpos);
extern int fatfs_read_directory(fatfs_filehandle_t *fh, fatfs_filehandle_t *entry,
				char *namebuf, uint32_t namebuf_len);
extern bool fatfs_is_readonly(fatfs_filehandle_t *fh);
extern int fatfs_setsize(fatfs_filehandle_t *fh, fatfs_filehandle_t *dirent_fh,
			 uint32_t newsize);
#endif
