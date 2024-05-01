#define ENOCARD       1
#define ECARDCHANGED  2
#define EBADCARD      3
#define ENOFS         4
#define EFILENOTFOUND 5
#define EREADONLYFS   6
#define EIO           7

typedef struct {
  uint32_t card_id;
  uint32_t start_cluster;
  uint32_t size;
} fatfs_filehandle_t;

extern int fatfs_open(const char *filename, fatfs_filehandle_t *fh);
