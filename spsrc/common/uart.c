#include "global.h"
#include "timer.h"
#include "regs.h"
#include "uart.h"

#ifndef BAUDRATE
#define BAUDRATE 115200u
#endif

#define BAUD_DIVISOR(n) ((TICKS_PER_SEC+((n)-1u)) / (n) - 1u)

bool uart_check_read(void)
{
  return REGS_UART.status & REGS_UART_STATUS_RXVALID;
}

uint8_t uart_read(void)
{
  return REGS_UART.rx_data;
}

void uart_write(uint8_t b)
{
  while (!(REGS_UART.status & REGS_UART_STATUS_TXREADY))
    ;
  REGS_UART.tx_data = b;
}

void uart_init(void)
{
  REGS_UART.baudrate = BAUD_DIVISOR(BAUDRATE);
  uart_read();
}

void uart_puts(const char *s)
{
  unsigned char c;
  while ((c = *s++)) {
    if (c == '\n')
      uart_write('\r');
    uart_write(c);
  }
}
