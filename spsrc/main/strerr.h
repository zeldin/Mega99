extern const char *fatfs_strerror(int n);
extern const char *yxml_strerror(int n);
extern const char *generic_strerror(int n, const char *prefix,
				    const char * const * messages,
				    int base, int cnt);

#define STRERR_ARRAY(arr, base) (arr), (base), (sizeof((arr))/sizeof((arr)[0]))
