package core_v_mini_mcu_pkg;
    localparam Parallelism = 32+32*1;

    localparam int DMA_CH_NUM = 4;
    
    localparam int CLK_F = 1e9;

    localparam AddrWidth = Parallelism;
    localparam logic [AddrWidth-1:0] SPI_FLASH_START_ADDRESS = '0;
    localparam logic [AddrWidth-1:0] SPI_SUBSYSTEM_START_ADDRESS = SPI_FLASH_START_ADDRESS + 100;
endpackage