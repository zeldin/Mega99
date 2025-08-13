#include "global.h"
#include "sdcard.h"
#include "fatfs.h"
#include "dirpath.h"

void dirpath_subdir(dirpath_t *dp, const fatfs_filehandle_t *subdir,
		    const fatfs_filehandle_t *dirpos)
{
  char *newpath = dp->path + strlen(dp->path);
  dp->fh = *subdir;
  if (newpath != dp->path && newpath[-1] != '/' &&
      newpath[-1] != ':' && newpath < &dp->path[sizeof(dp->path)-1])
    *newpath++ = '/';
  if (newpath < &dp->path[sizeof(dp->path)-1]) {
    fatfs_filehandle_t entry, dirfh = *dirpos;
    int r = fatfs_read_directory(&dirfh, &entry, newpath, 
				 &dp->path[sizeof(dp->path)-1] - newpath);
    if (r >= 0 && (r & 16)) {
      if (newpath[0] == '.' &&
	  (!newpath[1] ||
	   (newpath[1] == '.' && !newpath[2]))) {
	bool parent = (newpath[1] != 0);
	if (newpath != dp->path && newpath[-1] == '/')
	  --newpath;
	if (parent) {
	  while (newpath != dp->path && newpath[-1] != '/' &&
		 newpath[-1] != ':')
	    --newpath;
	  if (newpath != dp->path && newpath[-1] == '/')
	    --newpath;
	}
	*newpath = 0;
      }
      return;
    }
    *newpath++ = '?';
  }
  *newpath = 0;
}

static int dirpath_parse_cardnum(const char *path)
{
  if ((path[0] & ~0x20) == 'S' &&
      (path[1] & ~0x20) == 'D' &&
      (path[2] >= '0' && path[2] <= '9') &&
      path[3] == ':')
    return path[2] - '0';
  else
    return -1;
}

int dirpath_chdir(dirpath_t *dp, const char *path)
{
  int r, cardnum = -1;
  char *newpath = dp->path + strlen(dp->path);
  if ((cardnum = dirpath_parse_cardnum(path)) >= 0) {
    path += 4;
    newpath = dp->path;
  } else
    cardnum = dirpath_parse_cardnum(dp->path);
  if (cardnum >= 0) {
    if (sdcard_num_cards() > cardnum)
      sdcard_set_card_number(cardnum);
    else
      return -ENOCARD;
  } else
    cardnum = sdcard_get_card_number();
  if (*path == '/') {
    newpath = dp->path;
    path++;
  }
  if (newpath == dp->path) {
    *newpath++ = 's';
    *newpath++ = 'd';
    *newpath++ = '0' + cardnum;
    *newpath++ = ':';
    *newpath = 0;
    if ((r = fatfs_open_rootdir(&dp->fh)) < 0)
      return r;
  }
  while (*path)
    if (*path == '/')
      path++;
    else {
      char oc, *p2 = strchr(path, '/');
      if (p2) {
	oc = *p2;
	*p2 = 0;
      }
      fatfs_filehandle_t tmpfh = dp->fh;
      r = fatfs_openat(path, &dp->fh, &tmpfh);
      if (p2)
	*p2 = oc;
      if (r != -EISDIR)
	return r? r : -ENOTDIR;
      if (path[0] == '.' && (path[1] == 0 || path+1 == p2))
	path++;
      else if (path[0] == '.' && path[1] == '.' &&
	       (path[2] == 0 || path+2 == p2)) {
	path += 2;
	while (newpath != dp->path && newpath[-1] != '/' &&
	       newpath[-1] != ':')
	  --newpath;
	if (newpath >= dp->path+2 && newpath[-1] == '/')
	  --newpath;
	*newpath = 0;
      } else {
	if (newpath != dp->path && newpath[-1] != '/' &&
	    newpath[-1] != ':' && newpath < &dp->path[sizeof(dp->path)-1])
	  *newpath++ = '/';
	while (*path && *path != '/') {
	  if (newpath < &dp->path[sizeof(dp->path)-1])
	    *newpath++ = *path;
	  path++;
	}
	*newpath = 0;
      }
    }
  return 0;
}

int dirpath_restore(dirpath_t *dp, const dirpath_t *old)
{
  *dp = *old;
  if (dp->fh.start_cluster && fatfs_read(&dp->fh, NULL, 0) >= 0)
    return 0;
  dp->path[0] = 0;
  return dirpath_chdir(dp, old->path);
}

int dirpath_open_rootdir(dirpath_t *dp)
{
  dp->path[0] = 0;
  return dirpath_chdir(dp, "/");
}
