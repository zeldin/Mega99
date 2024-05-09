#define ENOCARD       1
#define ECARDCHANGED  2
#define EBADCARD      3
#define ENOFS         4
#define EFILENOTFOUND 5
#define EREADONLYFS   6
#define EIO           7
#define ETRUNC        8

typedef struct {
  uint32_t card_id;
  uint32_t start_cluster;
  uint32_t size;
  uint32_t current_cluster;
  uint32_t filepos;
} fatfs_filehandle_t;

extern int fatfs_open(const char *filename, fatfs_filehandle_t *fh);
extern int fatfs_read(fatfs_filehandle_t *fh, void *p, uint32_t bytes);
