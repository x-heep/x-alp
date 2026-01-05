uint8_t mmio_region_from_addr(uintptr_t addr) {
    return (uint8_t)addr;
};

#define SOC_CTRL_START_ADDRESS 0x10000000
#define UART_START_ADDRESS     0x10010000
