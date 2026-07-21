#include "global.h"
#include "sdcard.h"
#include "fatfs.h"
#include "dirpath.h"
#include "strerr.h"
#include "configfile.h"

#define CFG_FNAME "mega99.cfg"

static dirpath_t config_dirpath, tmp_dirpath;
static char config_buf[4096];

static const struct {
  const char *name;
  const config_entry_t *entries;
} configfile_sections[] = {
  { "Paths", paths_config_entries },
  { "Settings", settings_config_entries },
  { "TIPI", tipi_config_entries },
};

static void configfile_fileerror(int errno)
{
  printf("%s...", CFG_FNAME);
  fflush(stdout);
  fprintf(stderr, fatfs_strerror(-errno));
}

static int configfile_loadfrom(fatfs_filehandle_t *fh)
{
  int r;
  const config_entry_t *section = NULL;
  char *p = config_buf;
  r = fatfs_read(fh, config_buf, sizeof(config_buf)-1);
  if (r < 0)
    return r;
  p[r] = 0;
  while (p) {
    char *nextp = strchr(p, '\n');
    char *endp;
    if (nextp) {
      endp = nextp;
      *nextp++ = 0;
    } else
      endp = p + strlen(p);
    while (endp > p && endp[-1] <= 32)
      *--endp = 0;
    while (*p && *p <= 32)
      ++p;
    if (*p == '[') {
      section = NULL;
      if ((endp = strchr(p, ']'))) {
	*endp = 0;
	p++;
	for (unsigned i=0;
	     i<sizeof(configfile_sections)/sizeof(configfile_sections[0]);
	     i++) {
	  if (!strcmp(p, configfile_sections[i].name)) {
	    section = configfile_sections[i].entries;
	    break;
	  }
	}
      }
    } else if (section && (endp = strchr(p, '='))) {
      unsigned l = endp-p;
      const config_entry_t *entry = section;
      while (entry->prefix) {
	if (!memcmp(p, entry->prefix, l) &&
	    (entry->prefix[l] == '=' || !entry->prefix[l])) {
	  entry->parse(entry->prefix, endp+1);
	  break;
	}
	entry++;
      }
    }
    p = nextp;
  }
  return 0;
}

static int configfile_saveto(fatfs_filehandle_t *fh,
			     fatfs_filehandle_t *dirent_fh)
{
  int r;
  char *p = config_buf;
  for (unsigned i=0;
       i<sizeof(configfile_sections)/sizeof(configfile_sections[0]); i++) {
    const config_entry_t *entries = configfile_sections[i].entries;
    p += sprintf(p, "[%s]\n", configfile_sections[i].name);
    while (entries->prefix) {
      const char *prefix = entries->prefix;
      const char *eq = strchr(prefix, '=');
      unsigned pfxlen = (eq? eq-prefix : strlen(prefix));
      memcpy(p, prefix, pfxlen);
      p += pfxlen;
      *p++ = '=';
      *p = 0;
      entries->format(prefix, p);
      p += strlen(p);
      *p++ = '\n';
      ++entries;
    }
    *p++ = '\n';
  }
  *p = 0;
  unsigned len = p-config_buf;
  if ((r = fatfs_setsize(fh, dirent_fh, len)) >= 0 &&
      (r = fatfs_setpos(fh, 0)) >= 0)
    r = fatfs_write(fh, config_buf, len);
  if (r < 0)
    fatfs_setsize(fh, dirent_fh, 0);
  return r;
}

static bool configfile_finddir(bool need_file)
{
  unsigned i;
  for (i=0; i<20; i+=(need_file? 1:2)) {
    static char path[] = "sd0:mega99";
    int r;
    fatfs_filehandle_t fh;
    if ((i>>1) >= sdcard_num_cards())
      break;
    path[2] = '0'|(i>>1);
    path[4] = ((i&1)? 0 : 'm');
    if ((r = dirpath_chdir(&config_dirpath, path)) >= 0) {
      if (!need_file)
	return true;
      if ((r = dirpath_openat(&config_dirpath, CFG_FNAME, &fh, NULL)) >= 0) {
	if ((r = configfile_loadfrom(&fh)) < 0)
	  configfile_fileerror(r);
	return true;
      }
    }
  }
  return false;
}

void configfile_init(void)
{
  if (!configfile_finddir(true) && !configfile_finddir(false))
    config_dirpath.path[0] = 0;
  sdcard_set_card_number(0);
}

void configfile_load(void)
{
  fatfs_filehandle_t fh;
  int r = 0;
  dirpath_t *dp = NULL;
  if (config_dirpath.path[0]) {
    r = dirpath_restore((dp = &tmp_dirpath), &config_dirpath);
    if (r >= 0)
      config_dirpath = tmp_dirpath;
  }
  if (r >= 0)
    r = dirpath_openat(dp, CFG_FNAME, &fh, NULL);
  if (r >= 0)
    r = configfile_loadfrom(&fh);
  if (r < 0)
    configfile_fileerror(r);
  else
    printf("Configuration loaded\n");
}

void configfile_save(void)
{
  fatfs_filehandle_t fh, dirent_fh;
  int r = 0;
  dirpath_t *dp = NULL;
  if (config_dirpath.path[0]) {
    r = dirpath_restore((dp = &tmp_dirpath), &config_dirpath);
    if (r >= 0)
      config_dirpath = tmp_dirpath;
  }
  if (r >= 0)
    r = dirpath_open_or_createat(dp, CFG_FNAME, &fh, &dirent_fh);
  if (r >= 0)
    r = configfile_saveto(&fh, &dirent_fh);
  if (r < 0)
    configfile_fileerror(r);
  else
    printf("Configuration saved\n");
}
