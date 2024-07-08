#include "global.h"
#include "sdcard.h"
#include "fatfs.h"

#include "display.h"

#define DEBUG_PRINT(...) do { } while(0)
#define DEBUG_PUTC(c) do { } while(0)
// #define DEBUG_PRINT(...) do { display_printf(__VA_ARGS__); } while(0)
// #define DEBUG_PUTC(c) do { display_putc(c); } while(0)


#define FAT_EOC   0x80000000
#define FAT_ERROR 0x40000000

typedef enum {
  OP_INIT,
  OP_READ,
  OP_WRITE
} fatfs_op_t;

static sdcard_type_t current_card_type = SDCARD_REMOVED;
static uint32_t current_card_id = 0;
static uint32_t fatfs_fat_start, fatfs_data_start, fatfs_root_dir_start;
static uint8_t fatfs_cluster_shift, fatfs_blocks_per_cluster;
static uint16_t fatfs_root_dir_entries;
static bool fatfs_fat32;

static bool fatfs_filename_compare(const char *entry, const char *fn)
{
  unsigned i;
  for (i=0; i<8; i++)
    if (*fn == '.' || !*fn) {
      if (entry[i] != ' ')
	return false;
    } else if (*fn++ != entry[i])
      return false;
  if (*fn == '.')
    fn ++;
  for (i=0; i<3; i++)
    if (!*fn) {
      if (entry[8+i] != ' ')
	return false;
    } else if (*fn++ != entry[8+i])
      return false;
  return !*fn;
}

static bool fatfs_filename_long_compare(const char *entry, const char *fn)
{
  unsigned i = 1;
  while (i < 32) {
    if (entry[i] != *fn++ || entry[i+1] != 0)
      return false;
    if (!entry[i])
      return true;
    if ((i += 2) == 0x1a)
      i += 2;
    else if (i == 0x0b)
      i += 3;
  }
  return true;
}

static uint8_t fatfs_filename_checksum(const uint8_t *entry)
{
  uint8_t r = 0;
  for (unsigned i = 0; i < 11; i++)
    r = ((r >> 1) | (r << 7)) + *entry++;
  return r;
}

static inline uint16_t fatfs_get16(const uint8_t *p)
{
  return p[0] | (p[1] << 8);
}

static inline uint32_t fatfs_get32(const uint8_t *p)
{
  return fatfs_get16(p) | (fatfs_get16(p+2) << 16);
}

static int fatfs_check_fs(uint32_t card_id);

static int fatfs_check_card(uint32_t card_id, fatfs_op_t op)
{
  uint32_t status = sdcard_status();
  if ((status & (SDCARD_STATUS_CHANGED | SDCARD_STATUS_PRESENT)) !=
      SDCARD_STATUS_PRESENT)
    current_card_type = SDCARD_REMOVED;
  if (op != OP_INIT) {
    if (current_card_type == SDCARD_REMOVED || current_card_id != card_id)
      return -ECARDCHANGED;
    if (op == OP_WRITE && (status & SDCARD_STATUS_WRITEPROT))
      return -EREADONLYFS;
    return 0;
  }
  if (!(status & SDCARD_STATUS_PRESENT))
    return -ENOCARD;
  if (current_card_type == SDCARD_REMOVED) {
    /* New card */
    if ((current_card_type = sdcard_activate()) > SDCARD_INVALID) {
      int r = fatfs_check_fs(++current_card_id);
      if (r < 0) {
	current_card_type = SDCARD_REMOVED;
	--current_card_id;
	return r;
      }
    }
  }
  if (current_card_type == SDCARD_REMOVED)
    return -ENOCARD;
  else if (current_card_type == SDCARD_INVALID)
    return -EBADCARD;
  else
    return 0;
}

static uint32_t fatfs_cluster_block_id(uint32_t cluster, uint32_t sub)
{
  return fatfs_data_start + (cluster << fatfs_cluster_shift) + sub;
}

static int fatfs_block_read(uint32_t blkid, uint8_t *ptr, uint32_t card_id)
{
  if (current_card_type < SDCARD_SDHC)
    blkid <<= 9;
  unsigned retries;
  for (retries = 0; retries < 5; retries ++) {
    int r = fatfs_check_card(card_id, OP_READ);
    if (r < 0)
      return r;
    if (sdcard_read_block(blkid, ptr))
      return 0;
  }
  return -EIO;
}

static int fatfs_cluster_block_read(uint32_t cluster, uint32_t sub,
				    uint8_t *ptr, uint32_t card_id)
{
  if ((cluster & FAT_EOC))
    return ((cluster & FAT_ERROR)? (int16_t)(cluster & 0xffffu) : -ETRUNC);
  return fatfs_block_read(fatfs_cluster_block_id(cluster, sub), ptr, card_id);
}

static uint32_t fatfs_get_fat_entry(uint32_t card_id, uint32_t cluster,
				    uint8_t *buf)
{
  uint8_t n;
  if ((cluster & FAT_EOC))
    return cluster;
  if (fatfs_fat32) {
    n = cluster&0x7f;
    cluster >>= 7;
  } else {
    n = cluster;
    cluster >>= 8;
  }
  int r = fatfs_block_read(fatfs_fat_start + cluster, buf, card_id);
  if (r < 0)
    return FAT_ERROR|FAT_EOC|(uint16_t)r;
  if (fatfs_fat32) {
    cluster = fatfs_get32(buf+(4*n)) & 0x0fffffff;
    if (cluster >= 0x0ffffff8)
      cluster |= FAT_EOC;
  } else {
    cluster = fatfs_get16(buf+(2*n));
    if (cluster >= 0xfff8)
      cluster |= FAT_EOC;
  }
  if (cluster < 2)
    cluster |= FAT_EOC;
  return cluster;
}

static bool fatfs_check_root_block(const uint8_t *blk, uint32_t offs)
{
  DEBUG_PRINT("Checking blk %x for FATFS\n", offs);

  if(blk[0x1fe] != 0x55 || blk[0x1ff] != 0xaa)
    return false;

  /* Check file system type */
  if (blk[82] != 'F' || blk[83] != 'A' || blk[84] != 'T')
    return false;

  /* Check required parameters */
  if (blk[11] != 0 || blk[12] != 2 || /* 512 bytes per sector */
      (blk[14] == 0 && blk[15] == 0) || /* reserved sectors > 0 */
      blk[16] != 2) /* fat count */
    return false;

  uint8_t i = 0, n = 1;
  do {
    if (blk[13] == n)
      break;
    i++;
    n<<=1;
  } while(n);
  if (!n)
    return false;
  fatfs_cluster_shift=i;
  fatfs_blocks_per_cluster = n;

  uint16_t rds = fatfs_get16(blk+17); /* rootDirEntryCount */
  fatfs_root_dir_entries = rds;
  rds = (rds >> 4) + ((((uint8_t)rds)&0xf)? 1:0);
  uint32_t bpf = fatfs_get16(blk+22); /* sectorsPerFat16 */
  if (!bpf)
    bpf = fatfs_get32(blk+36); /* sectorsPerFat32 */
  uint32_t ds = fatfs_get16(blk+14) + offs;
  fatfs_fat_start = ds;
  ds += bpf<<1;
  fatfs_root_dir_start = ds;
  ds += rds;
  fatfs_data_start = ds - (2u<<i);
  uint32_t cc = fatfs_get16(blk+19); /* totalSectors16 */
  if (!cc)
    cc = fatfs_get32(blk+32); /* totalSectors32 */
  cc -= (ds - offs);
  cc >>= i;
  if (cc < 65525) {
    if (cc < 4085) {
      DEBUG_PRINT("Found FAT12 FS\n");
      /* FAT12 not supported */
      return false;
    }
    DEBUG_PRINT("Found FAT16 FS\n");
    fatfs_fat32 = false;
  } else {
    DEBUG_PRINT("Found FAT32 FS\n");
    fatfs_fat32 = true;
    fatfs_root_dir_start = fatfs_get32(blk+44);
  }

  DEBUG_PRINT("FS has %x clusters\n", cc);

  return true;
}

static int fatfs_check_fs(uint32_t card_id)
{
  int r;
  uint8_t blk[512];
  uint32_t part_start = 0;
  for (;;) {
    if ((r = fatfs_block_read(part_start, blk, card_id)) < 0)
      return r;
    if (fatfs_check_root_block(blk, part_start))
      return 0;
    if (part_start != 0)
      break;
    /* Partition table? */
    if (blk[0x1fe] != 0x55 || blk[0x1ff] != 0xaa ||
	(blk[0x1be] & 0x7f) != 0)
      break;
    part_start = fatfs_get32(blk+0x1c6);
    if (!part_start)
      break;
  }
  return -ENOFS;
}

static inline uint8_t fatfs_compute_lfn_key(const char *filename)
{
  unsigned n = 845;
  if (*filename++)
    while (*filename++)
      if (++n == 1099)
	break;
  return n / 13;
}

static int fatfs_search_rootdir(uint32_t card_id, const char *filename,
				fatfs_filehandle_t *fh)
{
  uint32_t blk = fatfs_root_dir_start;
  uint16_t rde = fatfs_root_dir_entries;
  uint8_t entry = 0, cnr = 0;
  uint16_t lfn_match = ~0;
  uint8_t lfn_key = fatfs_compute_lfn_key(filename);
  uint8_t buf[512];
  const uint8_t *p;
  for (;;) {
    if (!fatfs_fat32 && !rde)
      break;
    if (!entry) {
      int r;
      p = buf;
      if (fatfs_fat32)
	r = fatfs_cluster_block_read(blk, cnr++, buf, card_id);
      else
	r = fatfs_block_read(blk++, buf, card_id);
      if (r < 0)
	return r;
    }
    if (!*p)
      break;
    if ((p[11]&0x3f) == 0x0f) {
      DEBUG_PRINT("LFN %x ", p[0] | (p[0xb] << 24) | (p[0xd] << 16));
      unsigned i = 1;
      while (i < 32) {
	if (p[i+1])
	  DEBUG_PUTC('@');
	else
	  DEBUG_PUTC(p[i]);
	if ((i += 2) == 0x1a)
	  i += 2;
	else if (i == 0x0b)
	  i += 3;
      }
      if (*p == lfn_key)
	lfn_match = (p[0xd]<<8)|(lfn_key - 0x40);
      else if (!*p || (*p & 0xc0) || ((p[0xd] << 8)|*p) != lfn_match)
	lfn_match = ~0;
      if (!(lfn_match & 0x80)) {
	--lfn_match;
	if (fatfs_filename_long_compare((const char *)p,
					filename+13*(0xff&lfn_match))) {
	  DEBUG_PRINT(" +\n");
	} else {
	  DEBUG_PRINT(" -\n");
	  lfn_match = ~0;
	}
      } else
	DEBUG_PRINT(" !\n");
    } else if (*p == 0xe5)
      lfn_match = ~0;
    else {
      DEBUG_PRINT("Entry ");
      int i;
      for(i=0; i<11; i++)
	DEBUG_PUTC(p[i]);
      if (!(lfn_match & 0xff))
	DEBUG_PRINT(" CS %x\n", fatfs_filename_checksum(p));
      else
	DEBUG_PUTC('\n');
      if (fatfs_filename_compare((const char *)p, filename) ||
	  lfn_match == (fatfs_filename_checksum(p) << 8)) {
	uint32_t file_start_cluster = fatfs_get16(p+26);
	if (fatfs_fat32)
	  file_start_cluster |= fatfs_get16(p+20) << 16;
	DEBUG_PRINT("Found at cluster %x\n", file_start_cluster);
	fh->card_id = card_id;
	fh->start_cluster = file_start_cluster;
	fh->current_cluster = file_start_cluster;
	fh->size = fatfs_get32(p+28);
	fh->filepos = 0;
	return 0;
      }
      lfn_match = ~0;
    }
    p += 32;
    --rde;
    if (++entry == 16) {
      entry = 0;
      if (fatfs_fat32) {
	if (cnr == fatfs_blocks_per_cluster) {
	  cnr = 0;
	  blk = fatfs_get_fat_entry(card_id, blk, buf);
	  if (blk & FAT_EOC)
	    break;
	}
      }
    }
  }
  return -EFILENOTFOUND;
}

int fatfs_open(const char *filename, fatfs_filehandle_t *fh)
{
  int r;
  if ((r = fatfs_check_card(0, OP_INIT)) < 0)
    return r;
  return fatfs_search_rootdir(current_card_id, filename, fh);
}

int fatfs_read(fatfs_filehandle_t *fh, void *p, uint32_t bytes)
{
  uint8_t buf[512];
  int r;
  uint32_t total = 0;
  uint32_t card_id = fh->card_id;
  if ((r = fatfs_check_card(card_id, OP_READ)) < 0)
    return r;
  uint32_t pos = fh->filepos;
  if (!bytes || pos >= fh->size)
    return 0;
  if (bytes > fh->size - pos)
    bytes = fh->size - pos;
  uint32_t cluster = fh->current_cluster;
  uint32_t sub = (pos >> 9) & (fatfs_blocks_per_cluster-1);
  if ((pos & 0x1ff)) {
    uint32_t fragment = ((~pos)&0x1ff)+1;
    r = fatfs_cluster_block_read(cluster, sub, buf, card_id);
    if (r < 0)
      return r;
    else if (fragment > bytes)
      fragment = bytes;
    else
      ++sub;
    memcpy(p, buf+(pos & 0x1ff), fragment);
    p = ((uint8_t *)p) + fragment;
    total = fragment;
    bytes -= fragment;
    pos += fragment;
    if (sub == fatfs_blocks_per_cluster) {
      cluster = fatfs_get_fat_entry(card_id, cluster, buf);
      sub = 0;
    }
  }
  while (bytes >= 512) {
    r = fatfs_cluster_block_read(cluster, sub, p, card_id);
    if (r < 0)
      return r;
    p = ((uint8_t *)p) + 512;
    total += 512;
    bytes -= 512;
    pos += 512;
    if (++sub == fatfs_blocks_per_cluster) {
      cluster = fatfs_get_fat_entry(card_id, cluster, buf);
      sub = 0;
    }
  }
  if (bytes > 0) {
    r = fatfs_cluster_block_read(cluster, sub, buf, card_id);
    if (r < 0)
      return r;
    memcpy(p, buf, bytes);
    total += bytes;
    pos += bytes;
  }
  fh->current_cluster = cluster;
  fh->filepos = pos;
  return total;
}

#ifndef BOOTCODE

int fatfs_setpos(fatfs_filehandle_t *fh, uint32_t newpos)
{
  uint8_t buf[512];
  int r;
  uint32_t card_id = fh->card_id;
  if ((r = fatfs_check_card(card_id, OP_READ)) < 0)
    return r;
  uint32_t pos = fh->filepos;
  if (newpos >= fh->size ||
      ((pos >> 9) & ~(fatfs_blocks_per_cluster-1)) ==
      ((newpos >> 9) & ~(fatfs_blocks_per_cluster-1))) {
    fh->filepos = newpos;
    return 0;
  }
  uint32_t cluster = fh->start_cluster;
  pos = newpos >> 9;
  while (pos >= fatfs_blocks_per_cluster) {
    pos -= fatfs_blocks_per_cluster;
    cluster = fatfs_get_fat_entry(card_id, cluster, buf);
  }
  if ((cluster & FAT_EOC))
    return ((cluster & FAT_ERROR)? (int16_t)(cluster & 0xffffu) : -ETRUNC);
  fh->current_cluster = cluster;
  fh->filepos = newpos;
  return 0;
}

#endif
