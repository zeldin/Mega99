#include "global.h"
#include "fatfs.h"
#include "strerr.h"
#include "regs.h"
#include "timer.h"

#define FORMAT_8BIT   0u
#define FORMAT_16BIT  2u
#define FORMAT_MONO   0u
#define FORMAT_STEREO 4u
#define FORMAT_TAP    8u

static fatfs_filehandle_t tape_file;
static uint8_t tape_mag_data_seen = 0, tape_mag_stopped = 0, tape_mag_primed = 0;
static uint32_t tape_mag_stop_time;

static uint8_t tape_cs1_buf[65536], tape_cs2_buf[65536];
static unsigned tape_cs1_cnt, tape_cs2_cnt;
unsigned tape_cs1_data_available = 0, tape_cs2_data_available = 0;

void tape_task(void)
{
  uint16_t fifo_status = REGS_TAPE.fifo_read;
  while (fifo_status & 0x300) {
    if (fifo_status & 0x200)
      fprintf(stderr, "Tape FIFO overflow!\n");
    if (fifo_status & 0x100) {
      uint8_t b = fifo_status;
      fifo_status >>= 4;
      fifo_status &= tape_mag_primed;
      if ((fifo_status ^ tape_mag_data_seen)) {
	fifo_status &= ~tape_mag_data_seen;
	if (fifo_status & 0x40) {
	  printf("CS1 recording started\n");
	  tape_cs1_cnt = 0;
	  tape_cs1_data_available = 0;
	}
	if (fifo_status & 0x80) {
	  printf("CS2 recording started\n");
	  tape_cs2_cnt = 0;
	  tape_cs2_data_available = 0;
	}
	tape_mag_data_seen |= fifo_status;
	tape_mag_primed &= ~fifo_status;
      }
      if ((tape_mag_data_seen & 0x40) && tape_cs1_cnt < sizeof(tape_cs1_buf)) {
	tape_cs1_buf[tape_cs1_cnt++] = b;
	if (tape_cs1_cnt == sizeof(tape_cs1_buf))
	  fprintf(stderr, "CS1 buffer full!\n");
      }
      if ((tape_mag_data_seen & 0x80) && tape_cs2_cnt < sizeof(tape_cs2_buf)) {
	tape_cs2_buf[tape_cs2_cnt++] = b;
	if (tape_cs2_cnt == sizeof(tape_cs2_buf))
	  fprintf(stderr, "CS2 buffer full!\n");
      }
    }
    fifo_status = REGS_TAPE.fifo_read;
  }
  fifo_status = (~fifo_status) >> 8;
  if ((fifo_status &= 0xc0))
    tape_mag_primed = fifo_status;
  if ((fifo_status &= tape_mag_data_seen)) {
    if (fifo_status & ~tape_mag_stopped) {
      tape_mag_stop_time = timer_read();
      tape_mag_stopped |= fifo_status;
    }
  }
  if (tape_mag_stopped &&
      ((uint32_t)(timer_read() - tape_mag_stop_time)) >= MS_TO_TICKS(10)) {
    if (tape_mag_stopped & 0x40) {
      tape_cs1_data_available = tape_cs1_cnt;
      printf("Saved %u bytes to CS1 buffer\n", tape_cs1_cnt);
    }
    if (tape_mag_stopped & 0x80) {
      tape_cs2_data_available = tape_cs2_cnt;
      printf("Saved %u bytes to CS2 buffer\n", tape_cs2_cnt);
    }
    tape_mag_data_seen &= ~tape_mag_stopped;
    tape_mag_stopped = 0;
  }

  uint16_t head = REGS_TAPE.head;
  uint16_t tail = REGS_TAPE.tail;
  if (!tape_file.size) {
    uint16_t control = REGS_TAPE.control;
    if ((control & 1)) {
      if (head == tail)
	REGS_TAPE.control = 0;
    }
    return;
  }
  uint16_t memsize = REGS_TAPE.memsize;
  uint16_t room = memsize + head - tail;
  if (!(room &= ~511))
    return;
  uint32_t pos = tape_file.filepos;
  int n = fatfs_read(&tape_file, TAPE_SAMPLES+(tail & (memsize-1)), room);
  if (n <= 0) {
    tape_file.size = 0;
    if (n < 0) {
      printf("CS1: ");
      fprintf(stderr, "%s\n", fatfs_strerror(-n));
    }
  } else
    REGS_TAPE.tail = tail + n;
}

static int tape_check_format(void)
{
  uint8_t hdr[16];
  int r = fatfs_read(&tape_file, hdr, 12);
  if (r < 0)
    return r;
  if (r > 0 && hdr[0] == 0xff) {
    /* TAP file */
    if ((r = fatfs_setpos(&tape_file, 0)) < 0)
      return r;
    memset(TAPE_SAMPLES, 0, 768);
    REGS_TAPE.tail = 768u;
    REGS_TAPE.sample_rate = 1151u;
    return FORMAT_TAP | 1u;
  }
  if (r < 12) {
    fprintf(stderr, "Short file\n");
    return 0;
  }
  if (memcmp(hdr, "RIFF", 4) || memcmp(hdr+8, "WAVE", 4)) {
    fprintf(stderr, "Unknown file format\n");
    return 0;
  }
  unsigned format = 0;
  while ((r = fatfs_read(&tape_file, hdr, 8)) == 8) {
    uint32_t len = hdr[4] | (hdr[5] << 8) | (hdr[6] << 16) | (hdr[7] << 24);
    if (!format && !memcmp(hdr, "fmt ", 4) && len >= 16) {
      len += tape_file.filepos;
      if ((r = fatfs_read(&tape_file, hdr, 16)) < 16)
	break;
      uint16_t wFormatTag = hdr[0] | (hdr[1] << 8);
      uint16_t nChannels = hdr[2] | (hdr[3] << 8);
      uint32_t nSamplesPerSec = hdr[4] | (hdr[5] << 8) | (hdr[6] << 16) | (hdr[7] << 24);
      uint16_t wBitsPerSample  = hdr[14] | (hdr[15] << 8);
      if (nSamplesPerSec < 2000u || nSamplesPerSec > 48000u) {
	fprintf(stderr, "Invalid sample rate\n");
	return 0;
      }
      if (wFormatTag != 1u || nChannels < 1u || nChannels > 2u ||
	  (wBitsPerSample != 8u && wBitsPerSample != 16u)) {
	fprintf(stderr, "Invalid sample format\n");
	return 0;
      }
      REGS_TAPE.sample_rate = (3579545u + (nSamplesPerSec >> 1)) / nSamplesPerSec - 1u;
      format = 1u;
      if (nChannels == 2u)
	format |= FORMAT_STEREO;
      else
	format |= FORMAT_MONO;
      if (wBitsPerSample == 16u)
	format |= FORMAT_16BIT;
      else
	format |= FORMAT_8BIT;
    } else
	len += tape_file.filepos;
    if (!memcmp(hdr, "data", 4)) {
      if (len < tape_file.size)
	tape_file.size = len;
      break;
    }
    if ((r = fatfs_setpos(&tape_file, len)) < 0)
      break;
  }
  if (r < 0)
    return r;
  if (!format) {
    fprintf(stderr, "Missing fmt chunk\n");
    return 0;
  }
  return format;
}

void tape_start(const fatfs_filehandle_t *fh)
{
  tape_file = *fh;
  if (!tape_file.size)
    return;
  REGS_TAPE.control = 0;
  REGS_TAPE.head = 0;
  REGS_TAPE.tail = 0;

  int r = tape_check_format();
  if (!r) return;

  if (r >= 0 && (tape_file.filepos & 0x1ffu)) {
    uint16_t tail = REGS_TAPE.tail;
    int n = fatfs_read(&tape_file, TAPE_SAMPLES+tail,
		       0x200u-(tape_file.filepos & 0x1ffu));
    if (n < 0)
      r = n;
    else
      REGS_TAPE.tail = tail + n;
  }
  if (r < 0) {
    fprintf(stderr, "%s\n", fatfs_strerror(-r));
    return;
  }

  tape_task();
  REGS_TAPE.control = r;
}

void tape_save(unsigned index, const char *filename)
{
  const char *dev = (index? "CS2" : "CS1");
  const uint8_t *buf = (index? tape_cs2_buf : tape_cs1_buf);
  unsigned available = (index? tape_cs2_data_available : tape_cs1_data_available);
  fatfs_filehandle_t fh, dirent_fh;
  int r;
  if (!available) {
    fprintf(stderr, "%s buffer is empty!\n", dev);
    return;
  }
  if ((r = fatfs_open_or_create(filename, &fh, &dirent_fh)) < 0 ||
      (r = fatfs_setsize(&fh, &dirent_fh, available)) < 0 ||
      (r = fatfs_setpos(&fh, 0)) < 0 ||
      (r = fatfs_write(&fh, buf, available)) < 0) {
    fprintf(stderr, "%s\n", fatfs_strerror(-r));
    return;
  }
  printf("Wrote %u bytes to %s from %s buffer\n", available, filename, dev);
}
