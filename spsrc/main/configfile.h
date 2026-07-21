typedef struct {
  const char *prefix;
  void (*parse)(const char *prefix, const char *value);
  void (*format)(const char *prefix, char *value);
} config_entry_t;

extern const config_entry_t settings_config_entries[];
extern const config_entry_t paths_config_entries[];
extern const config_entry_t tipi_config_entries[];

extern void configfile_init(void);
extern void configfile_load(void);
extern void configfile_save(void);
