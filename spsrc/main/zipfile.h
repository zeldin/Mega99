extern void zipfile_init();
extern int zipfile_open_fh(fatfs_filehandle_t *fh);
extern int zipfile_open(const char *path);
extern int zipfile_open_entry(const char *path);
extern int zipfile_read(void *p, uint32_t bytes);
extern void zipfile_close(void);
extern const char *zipfile_strerror(int n);
