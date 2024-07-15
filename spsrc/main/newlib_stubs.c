#include "global.h"
#include "uart.h"
#include "overlay.h"
#include "regs.h"

#include <errno.h>
#include <reent.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/time.h>

#include <or1k-support.h>
#include <or1k-sprs.h>

void __register_frame_info(__attribute__((unused)) const void *p,
			   __attribute__((unused)) struct object *ob)
{
}

void *__deregister_frame_info(__attribute__((unused)) const void *p)
{
  return (void *)0;
}

void exception_handler()
{
  unsigned i;
  REGS_MISC.leds = 2u;
  printf("Unhandled exception at %p, system halted\n",
	 (void *)or1k_mfspr(OR1K_SPR_SYS_EPCR_ADDR(0)));
  for(;;)
    ;
}

void _or1k_board_init(void)
{
  for (unsigned i=2; i<32; i++)
    if (i != 8)
      or1k_exception_handler_add(i, exception_handler);
}

int _or1k_uart_init(void)
{
  return 0;
}

uint32_t or1k_timer_disable(void)
{
  return 0;
}

void or1k_timer_restore(uint32_t sr_tee)
{
}

_ssize_t
_write_r(struct _reent * reent, int fd, const void *buf, size_t nbytes)
{
  int i;
  char* b = (char*) buf;

  if (fd < 1 || fd > 2) {
    reent->_errno = EBADF;
    return -1;
  }
  
  for (i = 0; i < nbytes; i++) {
    if (*(b + i) == '\n') {
      uart_write('\r');
    }
    uart_write(*(b + i));
    overlay_console_putc(fd, *(b + i));
  }
  return (nbytes);
}

void
_exit(int rc)
{
  extern void _or1k_board_exit(void);
  _or1k_board_exit();
  while (1) {}
}

int
_close_r(struct _reent *reent, int fildes)
{
  reent->_errno = ENOSYS;
  return -1;
}

int
_execve_r(struct _reent *reent, const char *name, char * const *argv,
		char * const *env)
{
  reent->_errno = ENOSYS;
  return -1;
}

int
_fork_r(struct _reent *reent)
{
  errno = ENOSYS;
  return -1;
}

int
_fstat_r(struct _reent *reent, int fildes, struct stat *st)
{
  reent->_errno = ENOSYS;
  return -1;
}

int
_getpid_r(struct _reent *reent)
{
  reent->_errno = ENOSYS;
  return -1;
}

int
_gettimeofday(struct _reent *reent, struct timeval  *ptimeval, void *ptimezone)
{
  reent->_errno = ENOSYS;
  return -1;
}

int
_isatty_r(struct _reent *reent, int file)
{
  reent->_errno = ENOSYS;
  return 0;
}

int
_kill_r(struct _reent *reent, int pid, int sig)
{
  reent->_errno = ENOSYS;
  return -1;
}

int
_link_r(struct _reent *reent, const char *existing, const char *new)
{
  reent->_errno = ENOSYS;
  return -1;
}

_off_t
_lseek_r(struct _reent *reent, int file, _off_t ptr, int dir)
{
  errno = ENOSYS;
  return -1;
}

int
_open_r(struct _reent *reent, const char *file, int flags, int mode)
{
  reent->_errno = ENOSYS;
  return -1;
}

_ssize_t
_read_r(struct _reent *reent, int file, void *ptr, size_t len)
{
  reent->_errno = ENOSYS;
  return -1;
}

int
_readlink_r(struct _reent *reent, const char *path, char *buf, size_t bufsize)
{
  reent->_errno = ENOSYS;
  return -1;
}

int
_stat_r(struct _reent *reent, const char *path, struct stat *buf)
{
  reent->_errno = EIO;
  return -1;
}

int
_unlink_r(struct _reent *reent, const char * path)
{
  reent->_errno = EIO;
  return (-1);
}
