#ifndef _UART_H_
#define _UART_H_

typedef struct uart {
    uint32_t base_addr;
    uint32_t clk_freq_hz;
    uint32_t baudrate;
    uint64_t nco;
} uart_t;

int uart_init(uart_t *uart){
    // Dummy implementation
    return 0; // kErrorOk
};

int uart_write(uart_t *uart, const uint8_t *data, size_t len){
    // Dummy implementation
    return len; // Assume all bytes are written successfully
};
#endif  // _UART_H_
