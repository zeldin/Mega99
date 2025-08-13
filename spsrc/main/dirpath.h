
typedef struct dirpath_s {
  fatfs_filehandle_t fh;
  char path[256];
} dirpath_t;

extern void dirpath_subdir(dirpath_t *dp, const fatfs_filehandle_t *subdir,
			   const fatfs_filehandle_t *dirpos);
extern int dirpath_chdir(dirpath_t *dp, const char *path);
extern int dirpath_restore(dirpath_t *dp, const dirpath_t *old);
extern int dirpath_open_rootdir(dirpath_t *dp);
