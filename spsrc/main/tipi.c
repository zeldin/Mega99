#include "global.h"
#include "regs.h"
#include "fatfs.h"
#include "tipi.h"

enum {
  TIPI_EDVNAME = 0x00,
  TIPI_EWPROT = 0x01,
  TIPI_EOPATTR = 0x02,
  TIPI_EILLOP = 0x03,
  TIPI_ENOSPAC = 0x04,
  TIPI_EEOF = 0x05,
  TIPI_EDEVERR = 0x06,
  TIPI_EFILERR = 0x07,

  TIPI_SUCCESS = 0xFF
};

enum {
  TIPI_OPEN = 0,
  TIPI_CLOSE = 1,
  TIPI_READ = 2,
  TIPI_WRITE = 3,
  TIPI_RESTORE = 4,
  TIPI_LOAD = 5,
  TIPI_SAVE = 6,
  TIPI_DELETE = 7,
  TIPI_SCRATCH = 8,
  TIPI_STATUS = 9
};

struct tifiles_header {
  uint8_t id[8];
  uint16_t num_sectors;
  uint8_t flags;
  uint8_t records_per_sector;
  uint8_t eof_offset;
  uint8_t rec_length;
  uint16_t lv3_records;
  uint8_t filename[10];
  uint8_t mxt;
  uint8_t reserved;
  uint16_t ext_header;
  uint16_t creation_hms;
  uint16_t creation_ymd;
  uint16_t update_hms;
  uint16_t update_ymd;
};

struct tifiles_handle {
  fatfs_filehandle_t handle;
  struct tifiles_header header;
};

static const uint8_t reply_msg[] = { 0x00, 0x01, 0x03 };

static uint8_t tipi_packet[0x10000u];
static uint8_t tipi_reply[0x10000u];
static uint16_t tipi_reply_pos = 0, tipi_reply_len = 0;
static uint16_t tipi_packet_pos = 0, tipi_packet_len = 0;
static bool tipi_got_pab = false;
static uint8_t tipi_reply_status;
static enum {
  REPLY_STATE_IDLE,
  REPLY_STATE_BYTE_HLEN,
  REPLY_STATE_BYTE_LLEN,
  REPLY_STATE_BYTE_VALUE,
  REPLY_STATE_PAYLOAD_HLEN,
  REPLY_STATE_PAYLOAD_LLEN,
  REPLY_STATE_PAYLOAD
} reply_state = REPLY_STATE_IDLE;

static struct tifiles_handle load_handle;

static struct {
  uint8_t opcode;
  uint8_t flag_status;
  uint16_t buf_addr;
  uint8_t record_len;
  uint8_t char_cnt;
  uint16_t record_num;
  uint8_t screen_offs;
  uint8_t name_len;
} pab;

static const char *config_records[] = {
  "DSK1_DIR=."
};

static const char *status_records[] = {
  "ERROR=netifaces",
  "VERSION=MEGA99"
};

static struct tipi_special_handler {
  const char *name;
  const char * const *records;
  uint8_t numrec, recno;
} special_handlers[] = {
  { "CONFIG",
    config_records, sizeof(config_records)/sizeof(config_records[0]) },
  { "STATUS",
    status_records, sizeof(status_records)/sizeof(status_records[0]) },
};

static uint8_t tipi_errno_to_status(int r)
{
  if (r >= 0)
    return TIPI_SUCCESS;
  else switch(r) {
    case -EFILENOTFOUND:
      return TIPI_EFILERR;
    case -EREADONLYFS:
      return TIPI_EWPROT;
    case -ENOSPC:
      return TIPI_ENOSPAC;
    default:
      return TIPI_EDEVERR;
    }
}

static uint8_t tipi_open_tifile(struct tifiles_handle *h, const char *fname)
{
  int r;
  const char *dot = strchr(fname, '.');
  if (dot)
    fname = dot+1;
  else
    fname = "";
  if ((r = fatfs_open(fname, &h->handle)) < 0)
    return tipi_errno_to_status(r);
  r = fatfs_read(&h->handle, &h->header, sizeof(h->header));
  if (r == sizeof(h->header)) {
    if (memcmp(h->header.id, "\x07TIFILES", 8))
      return TIPI_EFILERR;
    r = fatfs_setpos(&h->handle, 0x80u);
  } else if (r >= 0)
    return TIPI_EFILERR;
  return tipi_errno_to_status(r);
}

static void tipi_reply_n(uint16_t len)
{
  tipi_reply_len = len;
  tipi_reply_pos = 0;
  if (reply_state == REPLY_STATE_IDLE)
    reply_state = REPLY_STATE_PAYLOAD_HLEN;
}

static void tipi_reply_byte(uint8_t b)
{
  tipi_reply_status = b;
  reply_state = REPLY_STATE_BYTE_HLEN;
  tipi_reply_len = 0;
}

static void tipi_handle_special_handler(struct tipi_special_handler *handler)
{
  uint16_t recno = handler->recno;
  if ((pab.flag_status & 1))
    recno = pab.record_num;
  switch(pab.opcode) {
  case TIPI_OPEN:
    if ((pab.flag_status & 0xe) != 0x4 ||
	(pab.record_len && pab.record_len != 80)) {
      tipi_reply_byte(TIPI_EOPATTR);
      break;
    }
    handler->recno = 0;
    tipi_reply_byte(TIPI_SUCCESS);
    break;
  case TIPI_CLOSE:
    tipi_reply_byte(TIPI_SUCCESS);
    break;
  case TIPI_STATUS:
    if ((pab.flag_status & 0xe) != 0x4) {
      tipi_reply_byte(TIPI_EOPATTR);
      break;
    }
    tipi_reply_byte(TIPI_SUCCESS);
    tipi_reply[0] = (recno >= handler->numrec? 0x5 : 0x4);
    tipi_reply_n(1);
    break;
  case TIPI_READ:
    if ((pab.flag_status & 0xe) != 0x4) {
      tipi_reply_byte(TIPI_EOPATTR);
      break;
    }
    if (recno >= handler->numrec) {
      tipi_reply_byte(TIPI_EEOF);
      break;
    }
    tipi_reply_byte(TIPI_SUCCESS);
    {
      const char *rec = handler->records[recno];
      size_t l = strlen(rec);
      handler->recno = ++recno;
      memcpy(tipi_reply, rec, l);
      tipi_reply_n(l);
    }
    break;
  default:
    tipi_reply_byte(TIPI_EILLOP);
    break;
  }
}

static void tipi_handle_special(const char *name)
{
  unsigned i;
  for (i=0; i<sizeof(special_handlers)/sizeof(special_handlers[0]); i++)
    if (!strcmp(name, special_handlers[i].name)) {
      tipi_handle_special_handler(&special_handlers[i]);
      return;
    }
  tipi_reply_byte(TIPI_EDVNAME);
}

static void tipi_handle_pab(void)
{
  uint8_t rc;
  tipi_packet[tipi_packet_pos] = 0;
  printf("PAB operation fn=\"%s\"\n", tipi_packet);
  if (!strncmp(tipi_packet, "PI.", 3))
    tipi_handle_special(tipi_packet+3);
  else if (!strncmp(tipi_packet, "TIPI.", 5) ||
	   !strncmp(tipi_packet, "DSK1.", 5))
  switch(pab.opcode) {
  case TIPI_LOAD:
    printf("Load >%04x bytes to >%04x\n",
	   (unsigned)pab.record_num,
	   (unsigned)pab.buf_addr);
    if ((rc = tipi_open_tifile(&load_handle, tipi_packet)) != TIPI_SUCCESS) {
      printf("Open failed %02x\n", (unsigned)rc);
      tipi_reply_byte(rc);
      break;
    }
    printf("Flags: %02x\n", (unsigned)load_handle.header.flags);
    int r = fatfs_read(&load_handle.handle, tipi_reply, pab.record_num);
    tipi_reply_byte(tipi_errno_to_status(r));
    if (r >= 0)
      tipi_reply_n(r);
    break;
  default:
    tipi_reply_byte(TIPI_EILLOP);
    break;
  }
  else
    tipi_reply_byte(TIPI_EDVNAME);
}

static void tipi_reset(void)
{
  printf("TIPI RESET\n");
  REGS_TIPI.control = 0;
  tipi_packet_pos = 0;
  tipi_packet_len = 0;
  reply_state = REPLY_STATE_IDLE;
  tipi_got_pab = false;
}

static void tipi_handle_byte(uint8_t byt)
{
  if (tipi_packet_pos == tipi_packet_len)
    return;
  if (tipi_packet_pos < tipi_packet_len)
    tipi_packet[tipi_packet_pos++] = byt;
  else switch (tipi_packet_pos) {
    case 0xfffeu:
      tipi_packet[0] = byt;
      tipi_packet_pos = 0xffffu;
    default:
      return;
    case 0xffffu:
      tipi_packet_pos = 0;
      tipi_packet_len = (tipi_packet[0] << 8) | byt;
  }
  if (tipi_packet_pos < tipi_packet_len)
    return;
  printf("Got pkt: <");
  for (unsigned i=0; i<tipi_packet_len; i++)
    printf(" %02x", (unsigned)tipi_packet[i]);
  printf(" >\n");
  reply_state = REPLY_STATE_IDLE;
  if (tipi_got_pab) {
    tipi_got_pab = false;
    tipi_handle_pab();
  } else if (tipi_packet_len == 10 && tipi_packet[0] < 0x10) {
    memcpy(&pab, tipi_packet, sizeof(pab));
    tipi_got_pab = true;
  } else {
    tipi_reply_byte(TIPI_EILLOP);
  }
}

static uint8_t tipi_get_reply(void)
{
  switch(reply_state) {
  default:
    return 0x00;

  case REPLY_STATE_BYTE_HLEN:
    reply_state++;
    return 0x00;
  case REPLY_STATE_BYTE_LLEN:
    reply_state++;
    return 0x01;
  case REPLY_STATE_BYTE_VALUE:
    reply_state++;
    return tipi_reply_status;
  case REPLY_STATE_PAYLOAD_HLEN:
    reply_state++;
    return tipi_reply_len >> 8;
  case REPLY_STATE_PAYLOAD_LLEN:
    reply_state++;
    return tipi_reply_len & 0xffu;
  case REPLY_STATE_PAYLOAD:
    if (tipi_reply_pos < tipi_reply_len)
      return tipi_reply[tipi_reply_pos++];
    else {
      reply_state = REPLY_STATE_IDLE;
      return 0x00;
    }
  }
}

void tipi_task(void)
{
  static uint32_t old_status = ~0;
  uint32_t new_status = REGS_TIPI.status;
  if (new_status != old_status) {
    if ((new_status & UINT32_C(0x40000000))) {
      /* Reset level changed */
      new_status &= ~UINT32_C(0x40000000);
      REGS_TIPI.status = new_status;
      tipi_reset();
    }
    old_status = new_status;
    if (!(new_status & UINT32_C(0x20000000)))
      /* In reset */
      return;
    uint8_t tc = new_status >> 8;
    if (tc != REGS_TIPI.rc) {
      switch(tc & ~1) {
      case 0xf0:
	/* reset_sync */
	tipi_packet_len = 0;
	tipi_packet_pos = 0xfffeu;
	if (reply_state != REPLY_STATE_BYTE_HLEN &&
	    reply_state != REPLY_STATE_PAYLOAD_HLEN)
	  reply_state = REPLY_STATE_IDLE;
	break;
      case 0x02:
	/* write-byte */
	tipi_handle_byte(new_status);
	break;
      case 0x06:
	/* read-byte */
	REGS_TIPI.rd = tipi_get_reply();
	break;
      }
      REGS_TIPI.rc = tc;
    }
    fflush(stdout);
  }
}
