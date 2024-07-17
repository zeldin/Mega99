#include "global.h"
#include "mem.h"
#include "fatfs.h"
#include "zipfile.h"
#include "rpk.h"
#include "yxml.h"
#include "strerr.h"

#define EXPECT_ROM_ID       1
#define EXPECT_ROM_FILE     2
#define EXPECT_SOCKET_ID    4
#define EXPECT_SOCKET_USES  8
#define EXPECT_PCB_TYPE    16

#define MAX_RESOURCES         8
#define MAX_ID_LENGTH        15
#define MAX_FILE_LENGTH      15
#define MAX_SOCKET_ID_LENGTH 15
#define MAX_PCB_TYPE_LENGTH  15

#define GROM_SOCKET 0
#define ROM_SOCKET  1
#define ROM2_SOCKET 2

static uint8_t xmlbuf[1024];
static char resource_id[MAX_RESOURCES][MAX_ID_LENGTH+1];
static char resource_file[MAX_RESOURCES][MAX_FILE_LENGTH+1];

static int parse_layout(int *socket_resource, unsigned *cart_mode)
{
  unsigned num_resources = 0;
  unsigned expect = 0;
  char pcb_type[MAX_PCB_TYPE_LENGTH+1];
  char socket_id[MAX_SOCKET_ID_LENGTH+1];
  char uses[MAX_ID_LENGTH+1];
  char *attrbuf = NULL;
  unsigned attrspace;

  yxml_t yxml;
  yxml_init(&yxml, xmlbuf, sizeof(xmlbuf));
  yxml_ret_t r;

  char buf[512];
  char *p;
  int left = 0;

  do {
    if (!left && !(left = zipfile_read(p = buf, sizeof(buf))))
      r = yxml_eof(&yxml);
    else if (left < 0) {
      fprintf(stderr, "%s\n", zipfile_strerror(left));
      return -1;
    } else
      r = yxml_parse(&yxml, *p++);
    if (r < 0) {
      fprintf(stderr, "%s\n", yxml_strerror(r));
      return -1;
    }
    switch(r) {
    case YXML_ATTRSTART:
      if (!strcmp(yxml.attr, "id") && (expect & EXPECT_ROM_ID)) {
	expect &= ~EXPECT_ROM_ID;
	attrbuf = resource_id[num_resources];
	attrspace = MAX_ID_LENGTH;
      } else if (!strcmp(yxml.attr, "file") && (expect & EXPECT_ROM_FILE)) {
	expect &= ~EXPECT_ROM_FILE;
	attrbuf = resource_file[num_resources];
	attrspace = MAX_FILE_LENGTH;
      } else if (!strcmp(yxml.attr, "id") && (expect & EXPECT_SOCKET_ID)) {
	expect &= ~EXPECT_SOCKET_ID;
	attrbuf = socket_id;
	attrspace = MAX_SOCKET_ID_LENGTH;
      } else if (!strcmp(yxml.attr, "uses") && (expect & EXPECT_SOCKET_USES)) {
	expect &= ~EXPECT_SOCKET_USES;
	attrbuf = uses;
	attrspace = MAX_ID_LENGTH;
      } else if (!strcmp(yxml.attr, "type") && (expect & EXPECT_PCB_TYPE)) {
	expect &= ~EXPECT_PCB_TYPE;
	attrbuf = pcb_type;
	attrspace = MAX_PCB_TYPE_LENGTH;
      }
      break;
    case YXML_ATTRVAL:
      if (attrbuf && attrspace) {
	int l = strlen(yxml.data);
	if (l > attrspace)
	  l = attrspace;
	memcpy(attrbuf, yxml.data, l);
	attrbuf += l;
	attrspace -= l;
      }
      break;
    case YXML_ATTREND:
      if (attrbuf) {
	*attrbuf = 0;
	if (!expect) {
	  if (!strcmp(yxml.elem, "rom"))
	    num_resources++;
	  else if (!strcmp(yxml.elem, "pcb")) {
	    if (!strcmp(pcb_type, "standard"))
	      *cart_mode = 0u;
	    else if (!strcmp(pcb_type, "paged"))
	      *cart_mode = 1u;
	    else if (!strcmp(pcb_type, "minimem"))
	      *cart_mode = 2u;
	    else {
	      fprintf(stderr, "%s pcb unsupported\n", pcb_type);
	      return -1;
	    }
	  } else if (!strcmp(yxml.elem, "socket") &&
		     strcmp(socket_id, "ram_socket")) {
	    int socket_no = -1;
	    if (!strcmp(socket_id, "grom_socket"))
	      socket_no = GROM_SOCKET;
	    else if (!strcmp(socket_id, "rom_socket"))
	      socket_no = ROM_SOCKET;
	    else if (!strcmp(socket_id, "rom2_socket"))
	      socket_no = ROM2_SOCKET;
	    int resource_no = -1;
	    for (unsigned i = 0; i < num_resources; i++)
	      if (!strcmp(uses, resource_id[i])) {
		resource_no = i;
		break;
	      }
	    if (socket_no < 0)
	      fprintf(stderr, "unknown socket %s\n", socket_id);
	    else if (resource_no < 0)
	      fprintf(stderr, "undefined rom %s\n", uses);
	    else {
	      socket_resource[socket_no] = resource_no;
	      break;
	    }
	    return -1;
	  }
	}
      }
      attrbuf = NULL;
      break;
    case YXML_ELEMSTART:
      if (!strcmp(yxml.elem, "rom") && num_resources < MAX_RESOURCES)
	expect = EXPECT_ROM_ID | EXPECT_ROM_FILE;
      else if (!strcmp(yxml.elem, "socket"))
	expect = EXPECT_SOCKET_ID | EXPECT_SOCKET_USES;
      else if (!strcmp(yxml.elem, "pcb"))
	expect = EXPECT_PCB_TYPE;
      else
	expect = 0;
      break;
    case YXML_ELEMEND:
      expect = 0;
      break;
    }
  } while (left--);
  return 0;
}

static int low_load_rpk(const char *filename, fatfs_filehandle_t *fh)
{
  int socket_resource[] = { -1, -1, -1 };
  unsigned cart_mode = 0;

  printf("layout.xml...[%s]...", filename);
  fflush(stdout);
  int r = (fh? zipfile_open_fh(fh) : zipfile_open(filename));
  if (!r)
    r = zipfile_open_entry("layout.xml");
  if (r) {
    fprintf(stderr, "%s\n", zipfile_strerror(r));
    return -1;
  }
  if (parse_layout(socket_resource, &cart_mode) < 0)
    return -1;
  printf("Loaded\n");
  *CARTROM_CTRL = cart_mode;
  memset(GROM(3), 0x00, 8192*5);
  memset(CARTROM, 0x00, 8192*2);
  for (unsigned i = 0; i < 3; i++)
    if (socket_resource[i] >= 0) {
      const char *fn = resource_file[socket_resource[i]];
      printf("%s...[%s]...", fn, filename);
      fflush(stdout);
      r = zipfile_open_entry(fn);
      if (!r) {
	void *p;
	unsigned size;
	switch(i) {
	case GROM_SOCKET:
	  p = GROM(3);
	  size = 8192*5;
	  break;
	case ROM_SOCKET:
	  p = CARTROM;
	  size = 8192;
	  break;
	case ROM2_SOCKET:
	  p = CARTROM+8192;
	  size = 8192;
	  break;
	}
	r = zipfile_read(p, size);
      }
      if (r < 0) {
	fprintf(stderr, "%s\n", zipfile_strerror(r));
	return -1;
      }
      printf("Loaded\n");
    }
  return 0;
}

int load_rpk_fh(const char *filename, fatfs_filehandle_t *fh)
{
  int r = low_load_rpk(filename, fh);
  zipfile_close();
  return r;
}

int load_rpk(const char *filename)
{
  return load_rpk_fh(filename, NULL);
}
